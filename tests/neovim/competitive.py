"""Integration test with pynvim; run against an isolated copy of config/nvim.

Requires installed locked plugins and g++. Uses temporary problems, the real
~/dev/cp/cf-template.cpp, and the actual localhost receiver (port 27121).
"""

import json
import socket
import tempfile
import time
from pathlib import Path

import pynvim

with tempfile.TemporaryDirectory(prefix="competitest-") as workspace:
    actual = Path(workspace) / "actual"
    actual.mkdir()
    root = Path(workspace) / "cp"
    root.symlink_to(actual, target_is_directory=True)
    template = Path.home() / "dev/cp/cf-template.cpp"
    assert template.is_file(), template
    original_template = template.read_bytes()
    n = pynvim.attach("child", argv=["nvim", "--embed", "--headless"])

    def lua(code, *args):
        return n.exec_lua(code, *args)

    def wait(predicate, timeout=20):
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline:
            if predicate():
                return
            time.sleep(0.05)
        raise AssertionError(n.command_output("messages"))

    def key(lhs):
        lua(
            'vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(..., true, false, true), "m", false)',
            lhs,
        )
        time.sleep(0.05)

    def send(url, batch="single", size=1):
        task = {
            "name": "A. Test problem",
            "group": "Codeforces - Test contest",
            "url": url,
            "memoryLimit": 256,
            "timeLimit": 1000,
            "tests": [
                {"input": "2 3\n", "output": "5\n"},
                {"input": "4 7\n", "output": "11\n"},
            ],
            "languages": {"java": {"mainClass": "Main", "taskClass": "ATest"}},
            "batch": {"id": batch, "size": size},
        }

        body = json.dumps(task).encode()

        with socket.create_connection(("127.0.0.1", 27121), timeout=3) as client:
            client.sendall(
                b"POST / HTTP/1.1\r\nHost: localhost\r\nContent-Length: "
                + str(len(body)).encode()
                + b"\r\n\r\n"
                + body
            )

            client.shutdown(socket.SHUT_WR)
            client.recv(1024)

    def import_problem(url, relative, initial=False):
        if not initial:
            key("<leader>cpi")
        send(url)
        path = root / relative
        wait(lambda: path.is_file())

        wait(
            lambda: (
                Path(lua("return vim.api.nvim_buf_get_name(0)")).resolve()
                == path.resolve()
            )
        )

        assert path.read_bytes() == original_template
        assert (
            path.parent / "tests" / (path.stem + "_input0.txt")
        ).read_text() == "2 3\n"
        assert (
            path.parent / "tests" / (path.stem + "_output1.txt")
        ).read_text() == "11\n"
        assert lua('return vim.fn.maparg("<F6>", "n", false, true).buffer') == 1
        return path

    def run(source, expected):
        lua(
            'vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(..., "\\n")); vim.bo.fileformat="unix"',
            source,
        )
        key("<F6>")
        wait(
            lambda: lua(
                'local r=require("competitest.commands").runners; for _,v in pairs(r) do if v.tcdata[1] and not v.tcdata[1].running and v.tcdata[1].status ~= "" then return true end end; return false'
            )
        )

        wait(
            lambda: (
                lua(
                    'local r=require("competitest.commands").runners; for _,v in pairs(r) do for _,t in ipairs(v.tcdata) do if t.running or t.status=="" then return false end end end; return true'
                )
                if not expected[0].startswith("RET ")
                else True
            )
        )

        data = lua(
            'local r=require("competitest.commands").runners; for _,v in pairs(r) do local t={}; for _,tc in ipairs(v.tcdata) do t[#t+1]={status=tc.status, time=tc.time, stderr=tc.stderr, stdout=tc.stdout, number=tc.tcnum} end; return t end'
        )
        assert sorted(t["status"] for t in data) == sorted(expected), data
        assert all(t.get("time") is not None for t in data if t["status"] != "")
        # Runner and error viewer use q to close; restore the source buffer.
        while lua("return vim.bo.filetype") != "cpp":
            key("q")
        return data

    try:
        lua(
            "vim.notify=function(msg) print(msg) end; vim.o.columns=160; vim.o.lines=50"
        )
        assert not lua("return package.loaded.competitest ~= nil")
        lua('require("lazy").load({plugins={"nvim-dap"}})')
        f5 = lua('return vim.fn.maparg("<F5>", "n")')
        # Redirect only the CP workspace path, leaving HOME/template untouched.
        lua(
            'local root=...; local expand=vim.fn.expand; vim.fn.expand=function(value, ...) if value=="~/dev/cp" then return root end; return expand(value, ...) end',
            str(root),
        )
        n.command("cd " + str(root))
        wait(lambda: lua("return package.loaded.competitest ~= nil"))
        assert lua(
            'return require("lazy.core.config").plugins["competitest.nvim"]._.loaded ~= nil'
        )
        a = import_problem(
            "https://m1.codeforces.com/contest/2000/problem/A",
            "codeforces/2000/A.cpp",
            initial=True,
        )
        import_problem(
            "https://codeforces.com/problemset/problem/2001/B?locale=en",
            "codeforces/2001/B.cpp",
        )
        import_problem(
            "https://codeforces.com/gym/100001/problem/A1", "codeforces/100001/A1.cpp"
        )
        import_problem(
            "https://codeforces.com/problemset/gymProblem/100002/C",
            "codeforces/100002/C.cpp",
        )
        print(
            "PASS startup, Lazy, port 27121, contest/problemset/Gym paths, template bytes, samples and automatic opening"
        )

        key("<leader>cpc")
        send("https://codeforces.com/contest/2002/problem/A", "contest", 2)
        send("https://codeforces.com/contest/2002/problem/B", "contest", 2)
        wait(lambda: (root / "codeforces/2002/B.cpp").is_file())
        assert (root / "codeforces/2002/A.cpp").read_bytes() == original_template
        assert (root / "codeforces/2002/tests/B_output0.txt").read_text() == "5\n"
        print("PASS complete contest batch")

        key("<leader>cpi")
        send("https://atcoder.jp/contests/abc123/tasks/abc123_a")
        wait(lambda: (root / "codeforces/test-contest/a-test-problem.cpp").is_file())
        # Verify safe fallback against realistic non-Codeforces metadata too.
        assert lua(
            'local o=require("competitest.config").current_setup; return o.received_problems_path({url="https://atcoder.jp/task",group="AtCoder - ABC 123",name="A - Sum / ../x"},"cpp")'
        ) == str(root / "atcoder/abc-123/a-sum-x.cpp")
        print("PASS other-judge fallback naming")

        n.command("edit " + str(a))
        key("<leader>cpi")
        lua(
            'vim.fn.confirm=function(prompt) assert(prompt:find("overwrite",1,true)); _G.overwrite_prompted=true; return 2 end'
        )
        send("https://codeforces.com/contest/2000/problem/A")
        wait(lambda: lua("return _G.overwrite_prompted == true"))
        assert a.read_bytes() == original_template
        print("PASS existing solution overwrite confirmation and refusal")

        good = '#include <iostream>\nint main(){int a,b;std::cin>>a>>b;std::cout<<a+b<<"\\n";}'
        run(good, ["DONE", "CORRECT", "CORRECT"])
        assert not (a.parent / "A").exists()

        assert (
            lua(
                'return vim.fn.executable(require("competitest.commands").runners[vim.api.nvim_get_current_buf()].rc.exec)'
            )
            == 1
        )

        print(
            "PASS F6 compile, all samples, timings, cache binary and rerun after edits"
        )

        key("<leader>cpa")
        wait(lambda: lua('return vim.fn.bufnr("CompetiTestEditInput")') > 0)
        lua(
            'vim.api.nvim_buf_set_lines(vim.fn.bufnr("CompetiTestEditInput"),0,-1,false,{"8 9"}); vim.api.nvim_buf_set_lines(vim.fn.bufnr("CompetiTestEditOutput"),0,-1,false,{"17"})'
        )
        key("<C-s>")
        wait(lambda: (a.parent / "tests/A_input2.txt").exists())
        assert (a.parent / "tests/A_output2.txt").read_text().strip() == "17"
        # cpe opens the picker, Enter chooses the first sample.
        key("<leader>cpe")
        key("<CR>")
        wait(lambda: lua('return vim.fn.bufnr("CompetiTestEditInput")') > 0)
        lua(
            'vim.api.nvim_buf_set_lines(vim.fn.bufnr("CompetiTestEditInput"),0,-1,false,{"10 20"}); vim.api.nvim_buf_set_lines(vim.fn.bufnr("CompetiTestEditOutput"),0,-1,false,{"30"})'
        )
        key("<C-s>")
        assert (a.parent / "tests/A_input0.txt").read_text().strip() == "10 20"
        key("<leader>cpa")
        lua(
            'vim.api.nvim_buf_set_lines(vim.fn.bufnr("CompetiTestEditInput"),0,-1,false,{"1 2"})'
        )
        key("<C-s>")
        assert not (a.parent / "tests/A_output3.txt").exists()
        run(good, ["DONE", "CORRECT", "CORRECT", "CORRECT", "DONE"])
        run(good.replace("a+b", "a-b"), ["DONE", "WRONG", "WRONG", "WRONG", "DONE"])
        print("PASS custom add/edit UI, input-only DONE, correct/wrong results")
        errors = run("invalid C++ syntax", ["RET 1", "", "", "", ""])
        assert errors[0]["stderr"]
        print("PASS compilation errors and automatic error viewer")
        run("int main(){return 7;}", ["DONE", "RET 7", "RET 7", "RET 7", "RET 7"])
        # Shorten only this test's timeout using the runner configuration.
        lua(
            'require("competitest.commands").runners[vim.api.nvim_get_current_buf()].config.maximum_time=100'
        )
        run(
            "int main(){for(;;){}}",
            ["DONE", "TIMEOUT", "TIMEOUT", "TIMEOUT", "TIMEOUT"],
        )
        print("PASS runtime errors and timeout")
        assert lua('return vim.fn.maparg("<F5>", "n")') == f5
        outside = root.parent / (root.name + "-ordinary.cpp")
        n.command("edit " + str(outside))
        assert not lua('return vim.fn.maparg("<F6>", "n", false, true).buffer == 1')
        for extension in ("py", "rs"):
            n.command("edit " + str(root / ("ordinary." + extension)))
            assert not lua('return vim.fn.maparg("<F6>", "n", false, true).buffer == 1')

        with tempfile.TemporaryDirectory(prefix="ordinary-cmake-") as project:
            Path(project, "CMakeLists.txt").write_text(
                "cmake_minimum_required(VERSION 3.20)\nproject(test)\n"
            )
            n.command("edit " + str(Path(project, "main.cpp")))
            assert (
                lua('return vim.fn.maparg("<leader>cmb", "n", false, true).buffer') == 1
            )
            assert not lua('return vim.fn.maparg("<F6>", "n", false, true).buffer == 1')

        assert template.read_bytes() == original_template
        print("PASS F6 isolation, CMake bindings, unchanged F5 and template")
    finally:
        try:
            n.command("qa!")
        except (EOFError, OSError):
            pass
