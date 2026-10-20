#define _GNU_SOURCE
#include <errno.h>
#include <fcntl.h>
#include <linux/memfd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
#ifndef SUDO_PATH
#define SUDO_PATH "/run/wrappers/bin/sudo"
#endif
extern char **environ;

static void fail(const char *what) {
    perror(what);
    exit(125);
}

int main(int argc, char **argv) {
    if (argc < 2) {
        fputs("namespace-launch: application ID required\n", stderr);
        return 125;
    }

    // Seal the environment before passing it through sudo on descriptor 3.
    int fd = memfd_create("namespace-user-environment", MFD_ALLOW_SEALING);
    if (fd < 0)
        fail("memfd_create");
    size_t total = 0;

    for (char **item = environ; *item; item++) {
        size_t length = strlen(*item) + 1;
        total += length;
        if (total > 1024 * 1024) {
            fputs("namespace-launch: environment too large\n", stderr);
            return 125;
        }
        size_t done = 0;

        while (done < length) {
            ssize_t count = write(fd, *item + done, length - done);
            if (count < 0 && errno == EINTR)
                continue;
            if (count <= 0)
                fail("write environment");
            done += (size_t)count;
        }
    }

    if (fcntl(fd, F_ADD_SEALS, F_SEAL_WRITE | F_SEAL_GROW | F_SEAL_SHRINK | F_SEAL_SEAL) < 0)
        fail("seal environment");
    if (lseek(fd, 0, SEEK_SET) < 0)
        fail("rewind environment");

    if (fd != 3) {
        if (dup2(fd, 3) < 0)
            fail("preserve environment");
        close(fd);
    }

    if (fcntl(3, F_SETFD, 0) < 0)
        fail("environment descriptor");

    // Only the registered application ID and its arguments reach the entry helper.
    char **args = calloc((size_t)argc + 7, sizeof(char *));
    if (!args)
        fail("calloc");
    args[0] = (char *)SUDO_PATH;
    args[1] = "-n";
    args[2] = "-C";
    args[3] = "4";
    args[4] = "--";
    args[5] = (char *)ENTER_PATH;
    for (int i = 1; i < argc; i++)
        args[i + 5] = argv[i];
    execv(SUDO_PATH, args);
    fail("namespace-launch: sudo");
}
