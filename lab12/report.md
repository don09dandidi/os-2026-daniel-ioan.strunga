# Lab 12: Producer, Consumer and the Other Tools (Linux)

Rulat pe vaio (`user@user-VPCEH1L0E`), output complet in `output.txt`. `deadlock.c` este versiunea reparata.

## Part 1: producer / consumer
1. Producatorul se opreste in `sem_wait(&empty)`: dupa 4 elemente `empty` ajunge la 0, iar producatorul asteapta pana cand consumatorul face `sem_post(&empty)`.
2. La inceput asteapta **consumatorul**, in `sem_wait(&full)`, pentru ca `full` porneste de la 0.
3. Cu `pthread_mutex_lock` inainte de `sem_wait(&empty)`, programul se blocheaza dupa `put 4` (timeout -> exit 124). Producatorul tine mutex-ul si doarme in `sem_wait(&empty)` pentru ca bufferul e plin. Consumatorul nu poate lua mutex-ul ca sa scoata un element si sa faca `sem_post(&empty)`. Fiecare asteapta dupa celalalt: deadlock. Nu dormi niciodata tinand un lock de care are nevoie cel care te trezeste.

## Part 2: condition variable
1. Variabila `ready` (protejata de `lock`). Variabila de conditie nu tine minte nimic: daca `signal` vine cand nu asteapta nimeni, se pierde.
2. Cu `if (!ready)` merge si aici (output identic), pentru ca exista un singur cititor si un singur semnal.
3. `pthread_cond_wait` se poate intoarce si fara semnal (*spurious wakeup*). In plus, cu mai multi cititori sau cu `broadcast`, alt thread poate prinde mutex-ul primul si poate schimba conditia inainte ca thread-ul trezit sa o verifice. `while` re-verifica `ready` dupa fiecare trezire.

## Part 3: readers / writers
1. `if (++readers == 1) sem_wait(&room);`: primul cititor inchide camera pentru scriitori. `if (--readers == 0) sem_post(&room);`: ultimul cititor o deschide. Cititorii din mijloc nu ating `room`, deci pot citi impreuna.
2. `++readers` / `--readers` sunt read-modify-write, aceeasi cursa ca in `race.c`. Fara `rlock`, doi cititori ar putea vedea amandoi 1 (dublu `sem_wait(&room)` -> blocaj) sau amandoi 0 (camera deschisa cat inca citeste cineva -> scriitorul intra peste cititori).
3. Daca vin mereu cititori noi, `readers` nu ajunge niciodata la 0, `room` nu e eliberat si writer 2 asteapta la nesfarsit: **starvation**.

## Part 4: deadlock
1. Thread `one` tine **A** si asteapta **B**, iar thread `two` tine **B** si asteapta **A**. Cercul: one -> (vrea) B -> (tinut de) two -> (vrea) A -> (tinut de) one.
2. Pe vaio s-a blocat in 10 din 10 rulari, pentru ca `printf` dintre cele doua lock-uri lasa destul timp ca celalalt thread sa-si ia primul lock. Pe alta masina (testat de mine) s-a blocat doar in 3 din 10. Fara `sleep`, deadlock-ul depinde de timing. E mai rau, nu mai bine: bug-ul devine intermitent, trece de teste si apare rar, in productie, greu de reprodus.
3. Daca toate thread-urile iau lock-urile in aceeasi ordine (A apoi B), nimeni nu poate tine B asteptand A, deci cercul de asteptare nu se poate forma.
