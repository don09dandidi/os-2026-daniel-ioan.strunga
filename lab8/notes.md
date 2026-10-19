# Lab 8: Aceleasi apeluri, in OS-ul tau

## Partea 1: run, in xv6
1. In Linux we used `fork()`, `execlp()`, `waitpid()`. In xv6 we used `fork()`, `exec()`, `wait()`. The basic logic and flow (copy memory, replace image, wait) are exactly the same.
2. The `echo` program prints it. The child process called `exec`, which replaced the child's code with the code of the `echo` executable.
3. Linux `<sys/wait.h>` encodes extra information in the status integer (e.g., if it was killed by a signal), so we need macros like `WEXITSTATUS()` to extract it. xv6 is much simpler and just passes the integer status directly from `exit(1)` to `wait(&status)`.

## Partea 2: pingpong
1. A pipe is unidirectional (it only flows from the write end `[1]` to the read end `[0]`). If we want bidirectional communication (parent to child AND child to parent), we need two separate pipes.
2. The `read()` system call on an empty pipe will block the process until the other end writes some data. Also, the explicit `wait(0);` at the end makes the parent wait for the child process to fully terminate.
