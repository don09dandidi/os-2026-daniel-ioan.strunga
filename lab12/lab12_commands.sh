#!/bin/bash
mkdir -p ~/os-lab12 && cd ~/os-lab12
cat > prodcons.c <<'EOF'
/* prodcons.c - producer and consumer around a buffer of 4 slots.
 *   empty = free slots (starts at SIZE), full = filled slots (starts at 0), lock = the buffer itself.
 * Build: gcc -Wall -pthread -o prodcons prodcons.c
 */
#include <stdio.h>
#include <unistd.h>
#include <pthread.h>
#include <semaphore.h>

#define SIZE 4
#define ITEMS 8

int buf[SIZE];
int in = 0, out = 0, count = 0;         /* count only for printing */
sem_t empty, full;
pthread_mutex_t lock = PTHREAD_MUTEX_INITIALIZER;

void *producer(void *arg) {
    for (int item = 1; item <= ITEMS; item++) {
        sem_wait(&empty);               /* wait for a free slot */
        pthread_mutex_lock(&lock);
        buf[in] = item;
        in = (in + 1) % SIZE;
        count++;
        printf("put %d    (in buffer: %d)\n", item, count);
        pthread_mutex_unlock(&lock);
        sem_post(&full);                /* one more filled slot */
    }
    return NULL;
}

void *consumer(void *arg) {
    for (int k = 0; k < ITEMS; k++) {
        sem_wait(&full);                /* wait for something to take */
        pthread_mutex_lock(&lock);
        int item = buf[out];
        out = (out + 1) % SIZE;
        count--;
        printf("            take %d   (in buffer: %d)\n", item, count);
        pthread_mutex_unlock(&lock);
        sem_post(&empty);               /* one more free slot */
        usleep(300000);                 /* the consumer is slow */
    }
    return NULL;
}

int main(void) {
    sem_init(&empty, 0, SIZE);
    sem_init(&full, 0, 0);
    pthread_t p, c;
    pthread_create(&c, NULL, consumer, NULL);
    pthread_create(&p, NULL, producer, NULL);
    pthread_join(p, NULL);
    pthread_join(c, NULL);
    sem_destroy(&empty);
    sem_destroy(&full);
    return 0;
}
EOF
cat > condvar.c <<'EOF'
/* condvar.c - the order.c problem, solved with a mutex and a condition variable.
 * Build: gcc -Wall -pthread -o condvar condvar.c
 */
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <pthread.h>

char message[32];
int ready = 0;                                  /* the condition itself */
pthread_mutex_t lock = PTHREAD_MUTEX_INITIALIZER;
pthread_cond_t changed = PTHREAD_COND_INITIALIZER;

void *writer(void *arg) {
    sleep(1);
    pthread_mutex_lock(&lock);
    strcpy(message, "hello");
    ready = 1;
    printf("A: message written\n");
    pthread_cond_signal(&changed);              /* wake one waiter */
    pthread_mutex_unlock(&lock);
    return NULL;
}

void *reader(void *arg) {
    pthread_mutex_lock(&lock);
    while (!ready) {                            /* while, not if: re-check after waking */
        printf("B: not ready, I sleep\n");
        pthread_cond_wait(&changed, &lock);     /* unlocks, sleeps, locks again */
    }
    printf("B: I read \"%s\"\n", message);
    pthread_mutex_unlock(&lock);
    return NULL;
}

int main(void) {
    pthread_t a, b;
    pthread_create(&b, NULL, reader, NULL);
    pthread_create(&a, NULL, writer, NULL);
    pthread_join(a, NULL);
    pthread_join(b, NULL);
    return 0;
}
EOF
cat > readers.c <<'EOF'
/* readers.c - readers and writers with two semaphores.
 *   Many readers may read together; a writer must be alone.
 * Build: gcc -Wall -pthread -o readers readers.c
 */
#include <stdio.h>
#include <unistd.h>
#include <pthread.h>
#include <semaphore.h>

#define READERS 3
#define WRITERS 2

int value = 0;                  /* the shared data */
int readers = 0;                /* how many are reading now */
sem_t rlock;                    /* protects the counter readers */
sem_t room;                     /* 1 = the room is free for a writer */

void *reader(void *arg) {
    long id = (long)arg;
    sem_wait(&rlock);
    if (++readers == 1)         /* the first reader in locks out the writers */
        sem_wait(&room);
    sem_post(&rlock);

    printf("reader %ld reads %d   (readers inside: %d)\n", id, value, readers);
    usleep(200000);

    sem_wait(&rlock);
    if (--readers == 0)         /* the last reader out lets the writers in */
        sem_post(&room);
    sem_post(&rlock);
    return NULL;
}

void *writer(void *arg) {
    long id = (long)arg;
    sem_wait(&room);            /* alone in the room */
    value += 10;
    printf("writer %ld writes %d (alone)\n", id, value);
    usleep(200000);
    sem_post(&room);
    return NULL;
}

int main(void) {
    sem_init(&rlock, 0, 1);
    sem_init(&room, 0, 1);
    pthread_t r[READERS], w[WRITERS];
    pthread_create(&w[0], NULL, writer, (void *)1L);
    for (long i = 0; i < READERS; i++)
        pthread_create(&r[i], NULL, reader, (void *)(i + 1));
    pthread_create(&w[1], NULL, writer, (void *)2L);
    for (int i = 0; i < READERS; i++) pthread_join(r[i], NULL);
    for (int i = 0; i < WRITERS; i++) pthread_join(w[i], NULL);
    return 0;
}
EOF
cat > deadlock.c <<'EOF'
/* deadlock.c - two threads, two mutexes, taken in opposite order.
 * Build: gcc -Wall -pthread -o deadlock deadlock.c
 * Run:   timeout 5 ./deadlock; echo "exit code: $?"      (124 = killed by timeout)
 */
#include <stdio.h>
#include <unistd.h>
#include <pthread.h>

pthread_mutex_t A = PTHREAD_MUTEX_INITIALIZER;
pthread_mutex_t B = PTHREAD_MUTEX_INITIALIZER;

void *one(void *arg) {
    pthread_mutex_lock(&A);
    printf("one: I have A, I want B\n");
    sleep(1);
    pthread_mutex_lock(&B);             /* waits for two */
    printf("one: I have both\n");
    pthread_mutex_unlock(&B);
    pthread_mutex_unlock(&A);
    return NULL;
}

void *two(void *arg) {
    pthread_mutex_lock(&B);             /* the fix: lock A first here too */
    printf("two: I have B, I want A\n");
    sleep(1);
    pthread_mutex_lock(&A);             /* waits for one */
    printf("two: I have both\n");
    pthread_mutex_unlock(&A);
    pthread_mutex_unlock(&B);
    return NULL;
}

int main(void) {
    pthread_t t1, t2;
    pthread_create(&t1, NULL, one, NULL);
    pthread_create(&t2, NULL, two, NULL);
    pthread_join(t1, NULL);
    pthread_join(t2, NULL);
    printf("done\n");
    return 0;
}
EOF
sed '/sem_wait(&empty);/{N;s/\(.*\)\n\(.*\)/\2\n\1/}' prodcons.c > prodcons_swap.c
sed 's/while (!ready)/if (!ready)/' condvar.c > condvar_if.c
sed '/sleep(1);/d' deadlock.c > deadlock_nosleep.c
cp deadlock.c deadlock_orig.c
for p in prodcons prodcons_swap condvar condvar_if readers deadlock_orig deadlock_nosleep; do gcc -Wall -pthread -o $p $p.c; done
clear
{
echo "===== PART 1: prodcons ====="
echo '$ ./prodcons'; stdbuf -oL ./prodcons
echo "--- lock inainte de sem_wait(&empty) ---"
echo '$ timeout 5 ./prodcons'; timeout 5 stdbuf -oL ./prodcons_swap; echo "exit code: $?"
echo; echo "===== PART 2: condvar ====="
echo '$ ./condvar'; stdbuf -oL ./condvar
echo "--- if (!ready) ---"
echo '$ ./condvar'; stdbuf -oL ./condvar_if
echo; echo "===== PART 3: readers ====="
echo '$ ./readers'; stdbuf -oL ./readers
echo; echo "===== PART 4: deadlock ====="
echo '$ timeout 5 ./deadlock; echo "exit code: $?"'; timeout 5 stdbuf -oL ./deadlock_orig; echo "exit code: $?"
echo "--- fara sleep(1), de 10 ori ---"
for i in 1 2 3 4 5 6 7 8 9 10; do echo "run $i:"; timeout 3 stdbuf -oL ./deadlock_nosleep; echo "exit code: $?"; done
} 2>&1 | tee output.txt
sed -i '/^void \*two/,/^}/{s/lock(&B)/lock(\&TMP)/;s/lock(&A)/lock(\&B)/;s/lock(&TMP)/lock(\&A)/}' deadlock.c
gcc -Wall -pthread -o deadlock deadlock.c
{
echo "--- dupa fix (A apoi B si in two) ---"
echo '$ timeout 5 ./deadlock; echo "exit code: $?"'; timeout 5 stdbuf -oL ./deadlock; echo "exit code: $?"
} 2>&1 | tee -a output.txt
