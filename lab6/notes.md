# Lab 6: Inside the xv6 File System

## Part 1. Read what xv6 shows you
1. Types in `kernel/stat.h`: `1` = `T_DIR`, `2` = `T_FILE`, `3` = `T_DEVICE`.
2. Root directory has inode `1`. `.` and `..` are both `1` because `/` is its own parent.
3. Empty directory `a` has size 32 bytes (2 entries: `.` and `..`), so each `struct dirent` is 16 bytes.

## Part 2. Write mystat
1. After `ln README r2`, `links` increased from 1 to 2 for inode 2. After `rm README`, `r2` kept inode 2 and size 2441 bytes with `links = 1`.
2. `ip->nlink--` is at line 244 in `kernel/sysfile.c` (`sys_unlink`). Data blocks are freed in `iput()` when both `nlink == 0` and `ref == 0`.
3. `struct dinode` (`kernel/fs.h`): `type`, `major`, `minor`, `nlink`, `size`, `addrs[NDIRECT + 1]`.

## Part 3. Measure the limits
1. Truncated to 14 characters (`averyveryveryl`) due to `#define DIRSIZ 14`.
2. Max file size: `(12 + 256) * 1024 = 274,432 bytes` (268 KB).
3. Disk layout (`nmeta 47`): total 2000 blocks (1 boot, 1 super, 31 log, 13 inode, 1 bitmap, 1953 data blocks).
