# Lab 7: Three Small Programs (Linux)

## Part 1. fork + exec + wait
1. `perror("exec")` happens only if `execlp` fails (like with `nosuchprog`). When `ls` or `date` is run, `execlp` replaces the child's memory image entirely with the new program, so the lines of code after `execlp` are never reached.
2. The child prints the PID of the original process that called `fork()` (its parent).
3. With `ls` it sees status `0` (success). With `nosuchprog` it sees `127` (the exit code hardcoded in `exit(127)` when `exec` fails).

## Part 2. A zombie, on purpose
1. `Z`, which stands for "Zombie" (or defunct). It means the child process has finished executing, but its parent hasn't read its exit status yet via `wait`.
2. After 20 seconds, the line disappears because the parent wakes up from `sleep(20)` and calls `waitpid`, effectively "reaping" the zombie and removing it from the process table.

## Part 3. Redirection: ls -l > out.txt
1. It gave descriptor `1`. `open` always assigns the lowest available file descriptor number. Since we just did `close(1)`, `1` was free.
2. Because `ls` automatically writes its output to file descriptor `1` (standard output). We changed descriptor `1` to point to the file `out.txt` instead of the terminal.
3. We would `close(2);` because descriptor `2` is standard error (`stderr`).

## Part 4. A pipe: ls /etc | wc -l
1. Yes, `./pipeline` outputs the exact same count as `ls /etc | wc -l`.
2. `wc` never ends.
3. `wc` reads until it receives an EOF (End-Of-File) on the pipe. EOF is sent only when ALL write ends of the pipe are closed across all processes. By commenting out `close(p[1])` in the parent, the pipe remains open for writing, so `wc` hangs forever waiting for more data.
