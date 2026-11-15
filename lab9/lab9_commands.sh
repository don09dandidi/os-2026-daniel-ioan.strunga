#!/bin/bash
# Lab 9 - Watching System Calls with strace
set -x
# Part 1
strace -f -e trace=openat,read,write,close ls -l
strace -c ls -l >/dev/null
# Part 2
gcc -Wall -Wextra -o syscalls syscalls.c
./syscalls
wc -c note.txt
strace -e trace=openat,write,read,close ./syscalls
strace -c ./syscalls >/dev/null
# Part 3
strace -f -e trace=write ls -l 2>&1 >/dev/null | grep -c '^write'
strace -f -e trace=openat ls -l 2>&1 >/dev/null | grep -c '^openat'
strace -e trace=write ./syscalls 2>&1 >/dev/null | grep -c '^write'
# TTY comparison (stdout on a terminal, strace output to file)
strace -o /tmp/ls_tty.txt -e trace=write ls -l; grep -c '^write' /tmp/ls_tty.txt
strace -o /tmp/sc_tty.txt -e trace=write ./syscalls; grep -c '^write' /tmp/sc_tty.txt
