#!/bin/bash
mkdir -p ~/os-lab11 && cd ~/os-lab11
cat > race.c <<'EOF'
/* race.c - two threads add to the same counter, with no protection.
 * Build: gcc -Wall -pthread -o race race.c       (no -O2: keep counter++ in memory)
 * Run:   ./race   (several times)
 */
#include <stdio.h>
#include <pthread.h>

#define N 1000000

long counter = 0;                          /* shared by both threads */

void *add(void *arg) {
    for (int i = 0; i < N; i++)
        counter++;                         /* read, add 1, write back: three steps */
    return NULL;
}

int main(void) {
    pthread_t a, b;
    pthread_create(&a, NULL, add, NULL);
    pthread_create(&b, NULL, add, NULL);
    pthread_join(a, NULL);
    pthread_join(b, NULL);
    printf("counter = %ld (expected %d)\n", counter, 2 * N);
    return 0;
}
EOF
cat > mutex.c <<'EOF'
/* mutex.c - the same counter, now protected by a mutex.
 * Build: gcc -Wall -pthread -o mutex mutex.c
 */
#include <stdio.h>
#include <pthread.h>

#define N 1000000

long counter = 0;
pthread_mutex_t lock = PTHREAD_MUTEX_INITIALIZER;

void *add(void *arg) {
    for (int i = 0; i < N; i++) {
        pthread_mutex_lock(&lock);                /* only one thread past this line */
        counter++;                                /* the critical section */
        pthread_mutex_unlock(&lock);              /* let the other one in */
    }
    return NULL;
}

int main(void) {
    pthread_t a, b;
    pthread_create(&a, NULL, add, NULL);
    pthread_create(&b, NULL, add, NULL);
    pthread_join(a, NULL);
    pthread_join(b, NULL);
    printf("counter = %ld (expected %d)\n", counter, 2 * N);
    return 0;
}
EOF
cat > sem.c <<'EOF'
/* sem.c - the same counter, protected by a semaphore that starts at 1.
 * Build: gcc -Wall -pthread -o sem sem.c
 */
#include <stdio.h>
#include <pthread.h>
#include <semaphore.h>

#define N 1000000

long counter = 0;
sem_t s;

void *add(void *arg) {
    for (int i = 0; i < N; i++) {
        sem_wait(&s);           /* 1 -> 0: I go in; at 0: wait */
        counter++;
        sem_post(&s);           /* 0 -> 1: the next one may go in */
    }
    return NULL;
}

int main(void) {
    sem_init(&s, 0, 1);         /* 0 = shared between threads, 1 = start value */
    pthread_t a, b;
    pthread_create(&a, NULL, add, NULL);
    pthread_create(&b, NULL, add, NULL);
    pthread_join(a, NULL);
    pthread_join(b, NULL);
    printf("counter = %ld (expected %d)\n", counter, 2 * N);
    sem_destroy(&s);
    return 0;
}
EOF
cat > order.c <<'EOF'
/* order.c - thread B must wait until thread A has written the message.
 * A semaphore that starts at 0 is a signal: sem_wait blocks until someone posts.
 * Build: gcc -Wall -pthread -o order order.c
 */
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <pthread.h>
#include <semaphore.h>

char message[32];
sem_t ready;                    /* starts at 0: nothing is ready yet */

void *writer(void *arg) {
    sleep(1);                   /* pretend the work takes a while */
    strcpy(message, "hello");
    printf("A: message written\n");
    sem_post(&ready);           /* 0 -> 1: wake up B */
    return NULL;
}

void *reader(void *arg) {
    printf("B: waiting for the message...\n");
    sem_wait(&ready);           /* blocks while the value is 0 */
    printf("B: I read \"%s\"\n", message);
    return NULL;
}

int main(void) {
    sem_init(&ready, 0, 0);
    pthread_t a, b;
    pthread_create(&b, NULL, reader, NULL);     /* B starts first, on purpose */
    pthread_create(&a, NULL, writer, NULL);
    pthread_join(a, NULL);
    pthread_join(b, NULL);
    sem_destroy(&ready);
    return 0;
}
EOF
cat > parking.c <<'EOF'
/* parking.c - 6 cars, 3 places. A semaphore that starts at 3 counts the free places.
 * Build: gcc -Wall -pthread -o parking parking.c
 */
#include <stdio.h>
#include <unistd.h>
#include <pthread.h>
#include <semaphore.h>

#define PLACES 3
#define CARS   6

sem_t places;                                   /* free places */
pthread_mutex_t lock = PTHREAD_MUTEX_INITIALIZER;
int inside = 0;                                 /* only for printing */

void *car(void *arg) {
    long id = (long)arg;
    sem_wait(&places);                          /* take a place, or wait */
    pthread_mutex_lock(&lock);
    inside++;
    printf("car %ld enters (inside: %d)\n", id, inside);
    pthread_mutex_unlock(&lock);

    sleep(1);                                   /* parked */

    pthread_mutex_lock(&lock);
    inside--;
    printf("car %ld leaves (inside: %d)\n", id, inside);
    pthread_mutex_unlock(&lock);
    sem_post(&places);                          /* give the place back */
    return NULL;
}

int main(void) {
    sem_init(&places, 0, PLACES);
    pthread_t t[CARS];
    for (long i = 0; i < CARS; i++)
        pthread_create(&t[i], NULL, car, (void *)(i + 1));
    for (int i = 0; i < CARS; i++)
        pthread_join(t[i], NULL);
    sem_destroy(&places);
    return 0;
}
EOF
cat > atomic.c <<'EOF'
/* atomic.c - the counter of race.c, with no lock at all: one atomic instruction per addition.
 * Build: gcc -Wall -pthread -o atomic atomic.c
 */
#include <stdio.h>
#include <pthread.h>
#include <stdatomic.h>

#define N 1000000

atomic_long counter = 0;                        /* every operation on it is indivisible */

void *add(void *arg) {
    for (int i = 0; i < N; i++)
        atomic_fetch_add(&counter, 1);          /* load, add, store as ONE step */
    return NULL;
}

int main(void) {
    pthread_t a, b;
    pthread_create(&a, NULL, add, NULL);
    pthread_create(&b, NULL, add, NULL);
    pthread_join(a, NULL);
    pthread_join(b, NULL);
    printf("counter = %ld (expected %d)\n", (long)counter, 2 * N);
    return 0;
}
EOF
sed 's/sem_init(&s, 0, 1)/sem_init(\&s, 0, 2)/' sem.c > sem2.c
sed 's/sem_init(&ready, 0, 0)/sem_init(\&ready, 0, 1)/' order.c > order1.c
sed 's/#define PLACES 3/#define PLACES 1/' parking.c > parking1.c
for p in race mutex sem order parking atomic sem2 order1 parking1; do gcc -Wall -pthread -o $p $p.c; done
clear
{
echo "===== PART 1: race ====="
for i in 1 2 3; do echo '$ ./race'; stdbuf -oL ./race; done
echo; echo "===== PART 2: mutex si sem ====="
for i in 1 2 3; do echo '$ ./mutex'; stdbuf -oL ./mutex; done
for i in 1 2 3; do echo '$ ./sem'; stdbuf -oL ./sem; done
echo "--- sem_init(&s, 0, 2) ---"
for i in 1 2 3; do echo '$ ./sem'; stdbuf -oL ./sem2; done
echo "--- time ---"
for p in race mutex sem; do echo "\$ time ./$p"; ( time ./$p ) 2>&1; done
echo; echo "===== PART 3: order ====="
echo '$ ./order'; stdbuf -oL ./order
echo "--- sem_init(&ready, 0, 1) ---"
echo '$ ./order'; stdbuf -oL ./order1
echo; echo "===== PART 4: parking ====="
echo '$ ./parking'; stdbuf -oL ./parking
echo "--- PLACES 1 ---"
echo '$ ./parking'; stdbuf -oL ./parking1
echo; echo "===== OPTIONAL: atomic ====="
echo '$ time ./atomic'; ( time ./atomic ) 2>&1
} 2>&1 | tee output.txt
