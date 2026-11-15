# Lab 11: The Race and the Semaphore (Linux)

Rulat pe vaio (`user@user-VPCEH1L0E`), output complet in `output.txt`.

## Part 1: race
1. `counter++` sunt 3 pasi: **load** (citeste `counter` din memorie in registru), **add** (registru + 1), **store** (scrie registrul inapoi in memorie).
2. `counter = 5`. Thread A face load (5), thread B face load (5), A face add + store -> 6, B face add + store -> 6. Au fost doua incrementari, dar valoarea a crescut cu 1: o adunare s-a pierdut.
3. Ordinea in care se intercaleaza cele doua thread-uri depinde de planificator, de nucleele CPU si de timing, care difera la fiecare rulare. Pe vaio: 1044369, 1093544, 1041945.

## Part 2: mutex si sem
1. Da, `mutex` si `sem` dau de fiecare data 2000000 (3 din 3 rulari fiecare).
2. Cu `sem_init(&s, 0, 2)` semaforul lasa **doua** thread-uri simultan in sectiunea critica, deci nu mai protejeaza nimic si cursa revine: 1990835, 1937654, 1921909. Pierderile sunt mai mici decat la `race` doar pentru ca `sem_wait`/`sem_post` incetinesc bucla.
3. Fiecare incrementare costa in plus un lock si un unlock (operatii atomice), iar cand thread-ul celalalt tine lock-ul se intra in kernel (futex) si se asteapta. Thread-urile ajung practic sa lucreze pe rand. Pe vaio: race 0.014 s (gresit), mutex 0.196 s, sem 0.402 s (sys 0.331 s = timp in kernel).

## Part 3: order
1. Cu start 1, B citeste `""` (sir gol). `sem_wait` gaseste valoarea 1 si trece imediat, inainte ca A sa fi scris mesajul (A doarme 1 s).
2. Un semafor care porneste de la 0 inseamna "inca nu s-a intamplat nimic, asteapta pana cineva da semnalul (sem_post)".

## Part 4: parking
1. Valoarea maxima pentru `inside` este **3**. O garanteaza `sem_wait(&places);`, impreuna cu `sem_init(&places, 0, PLACES)` unde PLACES = 3: a patra masina asteapta pana pleaca una.
2. Cu PLACES = 1 semaforul devine binar, adica un **mutex**: masinile intra strict pe rand (inside doar 0/1).

## Optional: atomic
`atomic_fetch_add` da 2000000 in 0.079 s, fara lock: load/add/store se fac ca o singura instructiune indivizibila.
