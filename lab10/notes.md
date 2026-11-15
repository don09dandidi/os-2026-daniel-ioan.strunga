# Lab 10: Add a System Call: trace (xv6)

## Raspunsuri

1. **De ce `trace 32 grep hello README` arata doar `read`, nu si `open`/`close`?**
   32 = 2^5, deci e setat doar bitul 5 (`SYS_read`). `SYS_open` = 15 si `SYS_close` = 21 dau 0 la `(p->trace_mask >> num) & 1`.

2. **In forkforkfork printeaza mai multe PID-uri. Ce linie din Partea 2 face asta posibil?**
   `np->trace_mask = p->trace_mask;` din `kfork()` (kernel/proc.c) – copilul mosteneste masca parintelui.

3. **De ce linia de trace apare intre "hi" si newline? De cate ori apeleaza echo write?**
   `echo` face 2 apeluri `write`: `write(1, "hi", 2)` si `write(1, "\n", 1)`. `printk` se executa dupa ce `syscalls[num]()` s-a terminat, deci "hi" e deja pe consola cand apare `N: syscall write -> 2`, apoi vine "\n" si `N: syscall write -> 1`.

4. **Ce masca urmareste doar `open` (15) si `close` (21)?**
   (1 << 15) | (1 << 21) = 32768 + 2097152 = **2129920** (0x208000).
