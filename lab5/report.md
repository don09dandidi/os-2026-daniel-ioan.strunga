# Lab 5: The File System with Your Own Hands (Linux)

## Part 1. The tree and the file types
1. File types (`ls -ld`): `/bin` -> `l` (symbolic link), `/dev/null` -> `c` (character device), `/etc` & `/tmp` -> `d` (directory), `/etc/passwd` -> `-` (regular file).
2. `/bin` is a symbolic link to `usr/bin`.
3. Character device: `/dev/console` (`/dev/null`). Block device: `/dev/sda` (`/dev/sr0`).
4. `/usr` (8.5G) is bigger than `/var/log` (4.3G) by ~4.2G.

## Part 2. Inodes and links
1. `Inode: 6556116` is the inode number; `Links: 1` (then `2`) is the link count.
2. `rm notes.txt` only unlinks the name and decrements the link count; `hard.txt` still points to inode `6556116`.
3. `soft.txt` is a symbolic link (inode `6556117`) storing the 8-byte string `"hard.txt"`. Once `hard.txt` is removed, `soft.txt` becomes a dangling link.
4. `mkdir d` has 2 links (`d` in parent and `d/.`). Adding `d/x` and `d/y` adds two `..` links pointing back to `d` (total 4).
5. `one.txt` (2 bytes) allocates one 4.0K ext4 block. `big.img` (1G) is a sparse file with 0 physical blocks allocated.

## Part 3. Permissions
1. `600` (`rw-------` - SSH private keys), `644` (`rw-r--r--` - config files), `755` (`rwxr-xr-x` - executables/dirs), `700` (`rwx------` - private dirs).
2. Kernel checks owner permission bits (`000`); ownership allows calling `chmod` to restore permissions.
3. `umask` is `0002`: files `666 - 002 = 664` (`rw-rw-r--`), directories `777 - 002 = 775` (`rwxrwxr-x`).
4. On a directory, `r` allows reading entry names (`ls`), while `x` allows traversing the directory to access known files (`cat box/f`).
5. `s` on `/usr/bin/passwd` is SUID (runs as root to update `/etc/shadow`); `t` on `/tmp` is Sticky Bit (only file owners can delete their files).

## Part 4. Disks and the kernel as files
1. Disk `sda` (298.1G): `sda1` (512M, `/boot/efi`), `sda5` (297.6G, mounted at `/` as `ext4`).
2. Root filesystem `/dev/sda5` is 16% full (43G used out of 292G).
3. 4 CPU cores (`/proc/cpuinfo`) and 3956716 kB (~3.96 GB) RAM (`/proc/meminfo`).
4. `/proc/self/status` shows `Name: head` because `head` is the process reading `/proc/self/status`.
