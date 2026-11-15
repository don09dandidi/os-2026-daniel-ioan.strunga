#!/bin/bash
cd ~/xv6-riscv
grep -q SYS_sem_init kernel/syscall.h || printf '#define SYS_sem_init 24\n#define SYS_sem_down 25\n#define SYS_sem_up   26\n' >> kernel/syscall.h
grep -q 'sem_init' user/user.h || sed -i 's/^int sync(void);$/int sync(void);\nint sem_init(int, int);\nint sem_down(int);\nint sem_up(int);/' user/user.h
grep -q 'sem_init' user/usys.pl || printf 'entry("sem_init");\nentry("sem_down");\nentry("sem_up");\n' >> user/usys.pl
grep -q '_semtest' Makefile || sed -i 's|^\t\$U/_zombie\\$|\t$U/_zombie\\\n\t$U/_semtest\\\n\t$U/_mix\\|' Makefile
cat > user/semtest.c <<'EOF'
// semtest.c: two tests for the kernel semaphores (Lab 13).
#include "kernel/types.h"
#include "user/user.h"

int
main(void)
{
  // Test 1: order. Semaphore 0 starts at 0, so the child must wait.
  sem_init(0, 0);
  if (fork() == 0) {
    sem_down(0);
    printf("child: I ran after the parent\n");
    exit(0);
  }
  pause(10);
  printf("parent: done, I let the child go\n");
  sem_up(0);
  wait(0);

  // Test 2: ping-pong. Semaphore 1 = ping's turn, semaphore 2 = pong's turn.
  sem_init(1, 1);
  sem_init(2, 0);
  if (fork() == 0) {
    for (int i = 1; i <= 3; i++) {
      sem_down(2);
      printf("  pong %d\n", i);
      sem_up(1);
    }
    exit(0);
  }
  for (int i = 1; i <= 3; i++) {
    sem_down(1);
    printf("ping %d\n", i);
    sem_up(2);
  }
  wait(0);
  printf("semtest: OK\n");
  exit(0);
}
EOF
cat > user/mix.c <<'EOF'
// mix.c: two processes print five lines each, one letter per write().
//   mix        no lock: the letters of the two processes can mix
//   mix lock   semaphore 3 used as a lock: every line stays whole
#include "kernel/types.h"
#include "user/user.h"

void
lines(char *s, int uselock)
{
  for (int k = 0; k < 5; k++) {
    if (uselock)
      sem_down(3);
    for (char *p = s; *p; p++)
      write(1, p, 1);
    if (uselock)
      sem_up(3);
  }
}

int
main(int argc, char *argv[])
{
  int uselock = (argc > 1);
  sem_init(3, 1);
  if (fork() == 0) {
    lines("bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb\n", uselock);
    exit(0);
  }
  lines("AAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n", uselock);
  wait(0);
  exit(0);
}
EOF
grep -n 'sem' kernel/syscall.h user/user.h user/usys.pl Makefile
make qemu
cd ~/xv6-riscv
cat > kernel/sem.c <<'EOF'
// sem.c: counting semaphores inside the xv6 kernel (Lab 13).
// A small table of NSEM semaphores, shared by every process.
// Each one is a number plus a spinlock that protects the number.

#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "param.h"
#include "spinlock.h"
#include "proc.h"

#define NSEM 8

struct sem {
  struct spinlock lock;       // a zeroed spinlock is a free spinlock
  int value;                  // how many may still pass
};

static struct sem sems[NSEM];

// sem_init(id, value): give semaphore id its start value.
uint64
sys_sem_init(void)
{
  int id, value;
  argint(0, &id);
  argint(1, &value);
  if (id < 0 || id >= NSEM || value < 0)
    return -1;
  acquire(&sems[id].lock);
  sems[id].value = value;
  release(&sems[id].lock);
  return 0;
}

// sem_down(id): take one unit; if there is none, sleep until there is.
uint64
sys_sem_down(void)
{
  int id;
  argint(0, &id);
  if (id < 0 || id >= NSEM)
    return -1;
  struct sem *s = &sems[id];

  acquire(&s->lock);
  while (s->value == 0) {
    sleep_prepare(s);       // I will sleep on the address of s
    release(&s->lock);      // never sleep holding a spinlock
    sleep();                // returns at once if sem_up came in between
    acquire(&s->lock);
    if (killed(myproc())) { // kill must still work on a waiting process
      release(&s->lock);
      return -1;
    }
  }
  s->value--;
  release(&s->lock);
  return 0;
}

// sem_up(id): give one unit back and wake whoever sleeps on s.
uint64
sys_sem_up(void)
{
  int id;
  argint(0, &id);
  if (id < 0 || id >= NSEM)
    return -1;
  struct sem *s = &sems[id];

  acquire(&s->lock);
  s->value++;
  wakeup(s);
  release(&s->lock);
  return 0;
}
EOF
grep -q 'sem.o' Makefile || sed -i 's|^  \$K/sysproc.o \\$|  $K/sysproc.o \\\n  $K/sem.o \\|' Makefile
grep -q 'sys_sem_init' kernel/syscall.c || sed -i -e 's/^extern uint64 sys_sync(void);$/extern uint64 sys_sync(void);\nextern uint64 sys_sem_init(void);\nextern uint64 sys_sem_down(void);\nextern uint64 sys_sem_up(void);/' -e 's/^  \[SYS_sync\]    = sys_sync,$/  [SYS_sync]    = sys_sync,\n  [SYS_sem_init] = sys_sem_init,\n  [SYS_sem_down] = sys_sem_down,\n  [SYS_sem_up]   = sys_sem_up,/' kernel/syscall.c
grep -n 'sem' Makefile kernel/syscall.c
make qemu
