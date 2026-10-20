#define _GNU_SOURCE
#include <errno.h>
#include <fcntl.h>
#include <grp.h>
#include <limits.h>
#include <linux/capability.h>
#include <linux/nsfs.h>
#include <pwd.h>
#include <sched.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mount.h>
#include <sys/ioctl.h>
#include <sys/prctl.h>
#include <sys/stat.h>
#include <sys/syscall.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>
struct target {
    const char *id, *netns, *user, *executable, *check;
};
#include "targets.h"

static void fail(const char *what) {
    perror(what);
    exit(125);
}

static void reject(const char *what) {
    fprintf(stderr, "namespace-enter: %s\n", what);
    exit(125);
}

static unsigned long number(const char *name) {
    const char *value = getenv(name);
    if (!value || !*value)
        reject("must be invoked through the configured sudo rule");
    char *end;
    errno = 0;
    unsigned long n = strtoul(value, &end, 10);
    if (errno || *end || n == 0 || n >= UINT_MAX)
        reject("invalid invoking user identity");
    return n;
}

static void trusted(int fd, mode_t type) {
    struct stat st;
    if (fstat(fd, &st) < 0)
        fail("stat namespace resource");
    if (st.st_uid != 0 || (st.st_mode & 0022) || ((st.st_mode & S_IFMT) != type))
        reject("namespace resource has unsafe ownership or permissions");
}

static void bind_file(const char *source, const char *dest, mode_t type) {
    int fd = open(source, O_RDONLY | O_CLOEXEC | O_NOFOLLOW | (type == S_IFDIR ? O_DIRECTORY : 0));
    if (fd < 0)
        fail("open namespace resolver resource");
    trusted(fd, type);
    char fdpath[64];
    snprintf(fdpath, sizeof(fdpath), "/proc/self/fd/%d", fd);
    if (mount(fdpath, dest, NULL, MS_BIND, NULL) < 0)
        fail("bind namespace resolver resource");
    if (mount(NULL, dest, NULL, MS_BIND | MS_REMOUNT | MS_RDONLY | MS_NOSUID | MS_NODEV, NULL) < 0)
        fail("protect namespace resolver resource");
    close(fd);
}

int main(int argc, char **argv) {
    if (getuid() != 0 || geteuid() != 0)
        reject("requires the configured sudo entry point");
    if (argc < 2)
        reject("application ID required");
    const struct target *target = NULL;

    for (const struct target *t = targets; t->id; t++)
        if (strcmp(argv[1], t->id) == 0) {
            target = t;
            break;
        }

    if (!target)
        reject("unregistered application");

    // Match the invoking account to the fixed application registration.
    uid_t uid = (uid_t)number("SUDO_UID");
    gid_t gid = (gid_t)number("SUDO_GID");
    struct passwd *pw = getpwuid(uid);
    if (!pw || strcmp(pw->pw_name, target->user) || pw->pw_gid != gid)
        reject("application is not authorized for this user");

    // Do not interpret the user's environment until ALL privileges are gone.
    struct stat env_stat;
    if (fstat(3, &env_stat) < 0 || !S_ISREG(env_stat.st_mode) || env_stat.st_size < 0 ||
        env_stat.st_size > 1024 * 1024)
        reject("missing or invalid sealed environment descriptor");
    int seals = fcntl(3, F_GET_SEALS);
    int required = F_SEAL_WRITE | F_SEAL_GROW | F_SEAL_SHRINK | F_SEAL_SEAL;
    if (seals < 0 || (seals & required) != required)
        reject("environment must be immutable");
    if (fcntl(3, F_SETFD, FD_CLOEXEC) < 0)
        fail("protect environment descriptor");

    // Refuse entry until the namespace passes its readiness check.
    pid_t checker = fork();
    if (checker < 0)
        fail("fork readiness check");

    if (checker == 0) {
        char *check_argv[] = {(char *)target->check, NULL};
        char *check_env[] = {"PATH=/no-inherited-path", "LC_ALL=C", NULL};
        execve(target->check, check_argv, check_env);
        _exit(125);
    }

    int status;
    while (waitpid(checker, &status, 0) < 0) {
        if (errno != EINTR)
            fail("readiness check");
    }
    if (!WIFEXITED(status) || WEXITSTATUS(status) != 0)
        reject("VPN is unavailable; refusing host-network fallback");
    char path[PATH_MAX];
    int netdir = open("/run/netns", O_RDONLY | O_DIRECTORY | O_CLOEXEC | O_NOFOLLOW);
    if (netdir < 0)
        fail("open namespace directory");
    trusted(netdir, S_IFDIR);
    int netfd = openat(netdir, target->netns, O_RDONLY | O_CLOEXEC | O_NOFOLLOW);
    close(netdir);
    if (netfd < 0)
        fail("open network namespace");

    // nsfs inodes report GLOBAL_ROOT_UID even in a subordinate user namespace.
    // Trust the protected directory and verify the actual kernel namespace type.
    if (ioctl(netfd, NS_GET_NSTYPE) != CLONE_NEWNET)
        reject("invalid network namespace handle");
    if (setns(netfd, CLONE_NEWNET) < 0)
        fail("enter network namespace");
    close(netfd);
    if (unshare(CLONE_NEWNS) < 0 || mount(NULL, "/", NULL, MS_REC | MS_PRIVATE, NULL) < 0)
        fail("isolate resolver mounts");
    snprintf(path, sizeof(path), "/run/network-namespaces/%s/resolv.conf", target->netns);
    bind_file(path, "/etc/resolv.conf", S_IFREG);
    snprintf(path, sizeof(path), "/run/network-namespaces/%s/nsswitch.conf", target->netns);
    bind_file(path, "/etc/nsswitch.conf", S_IFREG);
    if (access("/run/nscd", F_OK) == 0) {
        snprintf(path, sizeof(path), "/run/network-namespaces/%s/empty-nscd", target->netns);
        bind_file(path, "/run/nscd", S_IFDIR);
    }

    // Restore the user identity and remove every remaining capability.
    if (initgroups(target->user, gid) < 0)
        fail("restore user groups");

    for (int cap = 0;; cap++) {
        int exists = prctl(PR_CAPBSET_READ, cap, 0, 0, 0);
        if (exists < 0 && errno == EINVAL)
            break;
        if (exists < 0 || prctl(PR_CAPBSET_DROP, cap, 0, 0, 0) < 0)
            fail("drop capability bounding set");
    }

    if (setresgid(gid, gid, gid) < 0 || setresuid(uid, uid, uid) < 0)
        fail("drop root identity");
    struct __user_cap_header_struct cap_header = {_LINUX_CAPABILITY_VERSION_3, 0};
    struct __user_cap_data_struct cap_data[2] = {{0}, {0}};
    if (syscall(SYS_capset, &cap_header, cap_data) < 0 ||
        prctl(PR_CAP_AMBIENT, PR_CAP_AMBIENT_CLEAR_ALL, 0, 0, 0) < 0 ||
        prctl(PR_SET_NO_NEW_PRIVS, 1, 0, 0, 0) < 0)
        fail("seal privilege drop");
    if (syscall(SYS_close_range, 4, UINT_MAX, 0) < 0)
        fail("close inherited descriptors");

    // Read the sealed environment only after the privilege drop.
    size_t length = (size_t)env_stat.st_size;
    char *data = calloc(length + 1, 1);
    char **env = calloc(length + 1, sizeof(char *));
    if (!data || !env)
        fail("allocate user environment");
    size_t done = 0;

    while (done < length) {
        ssize_t n = pread(3, data + done, length - done, (off_t)done);
        if (n < 0 && errno == EINTR)
            continue;
        if (n <= 0)
            fail("read user environment");
        done += (size_t)n;
    }

    close(3);
    size_t offset = 0, count = 0;

    while (offset < length) {
        char *end = memchr(data + offset, '\0', length - offset);
        if (!end || !memchr(data + offset, '=', (size_t)(end - data - offset)))
            reject("malformed user environment");
        env[count++] = data + offset;
        offset = (size_t)(end - data) + 1;
    }

    // argv[1] is the registered ID; replace it with the immutable target path.
    argv[1] = (char *)target->executable;
    execve(target->executable, argv + 1, env);
    fail("execute registered application");
}
