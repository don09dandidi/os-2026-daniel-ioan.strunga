#!/bin/bash
echo "=== Q1: Cereri esuate ==="
grep -c FAIL access.log
echo "=== Q2: Pagini distincte ==="
cut -d' ' -f5 access.log | sort -u
echo "=== Q3: Accesari per pagina ==="
cut -d' ' -f5 access.log | sort | uniq -c | sort -rn
echo "=== Q4: Utilizatorul cu cele mai multe esecuri ==="
grep FAIL access.log | cut -d' ' -f3 | sort | uniq -c | sort -rn | head -1
echo "=== Q5: user3 total si esuate ==="
echo "total: $(grep -c user3 access.log), failed:$(grep user3 access.log | grep -c FAIL)"
echo "=== Q6: Ultimele 3 cereri esuate (ora si utilizator) ==="
grep FAIL access.log | tail -3 | cut -d' ' -f2,3
echo "=== Q7: Shell-uri de login din /etc/passwd ==="
cut -d: -f7 /etc/passwd | sort | uniq -c | sort -n
echo "=== Q8: Diferenta intre ls /etc si ls -l /etc ==="
echo "ls /etc: $(ls /etc \vert{} wc -l), ls -l /etc:$(ls -l /etc | wc -l)"
