# Lab 9: Watching System Calls with strace (Linux)

## Partea 1: ls -l
1. **Ce syscall foloseste `ls` ca sa afiseze pe ecran si in ce descriptor scrie?**
   `write`, in descriptorul **1** (stdout). Redirectat (`>/dev/null` sau pipe), libc face buffering pe bloc si toata listarea iese intr-un singur `write(1, ...)`; pe terminal stdout e line-buffered, deci apare cate un `write` pe linie.

## Partea 2: syscalls.c
1. **Primul `openat` intoarce descriptorul 3, nu 0, 1 sau 2. De ce sunt ocupate?**
   Orice proces porneste cu 3 descriptori deja deschisi, mosteniti de la shell: 0 = stdin, 1 = stdout, 2 = stderr. Kernelul aloca mereu cel mai mic descriptor liber, deci primul fisier deschis primeste 3. Dupa `close(3)`, al doilea `open("note.txt", O_RDONLY)` refoloseste tot 3.
   `open()` din C e doar un wrapper peste syscall-ul `openat(AT_FDCWD, ...)`.

## Partea 3: numararea apelurilor
- `2>&1 >/dev/null`: strace scrie pe stderr, programul pe stdout. Stderr merge in pipe catre `grep`, stdout e aruncat. Fara `>/dev/null`, linia programului `write sent 14 bytes` se potriveste si ea cu `^write`, iar numarul creste de la 2 la 3.
- Buffering: cu stdout redirectat, cele 3 `printf` se strang intr-un singur `write(1, ..., 80)` la iesire -> 2 apeluri `write` in total (plus `write(3, ...)`). Pe terminal (TTY) sunt 4: 3 x `write(1, ...)` + 1 x `write(3, ...)`.

| Comanda | Syscall | Redirectat (>/dev/null) | TTY (strace -o) |
|---|---|---|---|
| `ls -l` | write | 1 | 1 per linie (6 aici) |
| `ls -l` | openat | 10 | 10 |
| `./syscalls` | write | 2 | 4 |
