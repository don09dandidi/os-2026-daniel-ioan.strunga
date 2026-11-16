#!/bin/bash
echo "=== Q1: Cereri esuate ==="
grep -c FAIL access.log

echo "=== Q2: Pagini distincte ==="
cut -d' ' -f5 access.log | sort -u

echo "=== Q3: Accesari per pagina ==="
cut -d' ' -f5 access.log | sort | uniq -c | sort -rn

echo "=== Q4: Utilizatorul cu cele mai multe esecuri (incluzand egalitatile) ==="
max_fails=$(grep FAIL access.log | cut -d' ' -f3 | sort | uniq -c | sort -rn | head -n 1 | awk '{print $1}')
grep FAIL access.log | cut -d' ' -f3 | sort | uniq -c | sort -rn | awk -v max="$max_fails" '$1 == max'
