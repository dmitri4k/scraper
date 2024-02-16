## Семафоры

Семафор – это объект, который используется для контроля доступа нескольких потоков до общего ресурса. В общем случае это какая-то 
переменная, состояние которой изменяется каждым из потоков. 
Текущее состояние переменной определяет доступ к ресурсам.

В pthreads семафор – это переменная типа sem_t, которая может находиться в заданном числе состояний. Каждый поток 
может увеличить счётчик 
семафора, или уменьшить его. В литературе операция увеличения значения счётчика называется  V (от датского verhogen – увеличивать, или 
vrijgave - освобождать). Для простоты можно запоминать как английское vacate (освобождать). Уменьшение счётчика – это  операция P 
(proberen – тестировать, или passeren – проходить, или pakken – захватывать, или даже probeer te verlagen – попытаться уменьшить), 
или по-английски procure – добывать.

Замечание: иногда мьютекс называют двоичным семафором, указывая не то, что мьютекс может находиться в двух состояниях. Но здесь есть важное отличие: 
разблокировать мьютекс может только тот поток, который его заблокировал, семафор же может «разблокировать» любой поток.

Семафоры описаны в библиотеке semaphore.h. Работа с семаформаи похожа на работу с мьютексами. Сначала необходимо инициализировать семафор с 
помощью функции

```
int sem_init(sem_t *sem, int pshared, unsigned int value);
```

где sem – это указатель на семафор, pshared – флаг,указывающий, должен ли семафор быть расшарен при 
использовании функции fork(), 
value – начальное значение семафора.

Далее, для ожидания  доступа используется функция

```
int sem_wait(sem_t *sem);
```

Если значение семафора отрицательное, то вызывающий поток блокируется до тех пор, пока один из потоков не вызовет sem_post

```
int sem_post(sem_t *sem);
```

Эта функция увеличивает значение семафора и разблокирует ожидающие потоки. Как обычно, в конце необходимо уничтожить семафор

```
int sem_destroy(sem_t *sem);
```

Кроме тго, можно получить текущее значение семаформа

```
int sem_getvalue(sem_t *sem, int *valp);
```

Здесь в переменную valp будет помещено значение счётчика.

Обратимся опять к старому примеру. Два потока изменяют одну переменную, копируя её в локальную переменную. Один поток 
увеличивает значение, а второй уменьшает 100 раз. Таким образом, в конце должен быть 0. Из-за совместного доступа к переменной 
получаем каждый раз разное значение

```
#define _CRT_SECURE_NO_WARNINGS
#include <pthread.h>
#include <stdio.h>
#include <conio.h>
#include <Windows.h>

static int counter = 0;

void* worker1(void* args) {
	int i;
	int local;
	for (i = 0; i < 100; i++) {
		local = counter;
		printf("worker1 - %d\n", local);
		local++;
		counter = local;
		Sleep(10);
	}
}

void* worker2(void* args) {
	int i;
	int local;
	for (i = 0; i < 100; i++) {
		local = counter;
		printf("worker 2 - %d\n", local);
		local--;
		counter = local;
		Sleep(10);
	}
}

void main() {
	pthread_t thread1;
	pthread_t thread2;

	pthread_create(&thread1, NULL, worker1, NULL);
	pthread_create(&thread2, NULL, worker2, NULL);

	pthread_join(thread1, NULL);
	pthread_join(thread2, NULL);

	printf("== %d", counter);
	_getch();
}
```

Синхронизируем теперь их с помощью семафора. Рассмотрим сначала пример, когда счётчик равен 1, значит, после того, 
как один из потоков уменьшит значение семафора, то второй вынужден будет ждать доступа к ресурсу (в данном случае, это тело функции 
worker1 или worker2)

```
#define _CRT_SECURE_NO_WARNINGS
#include <pthread.h>
#include <stdio.h>
#include <conio.h>
#include <Windows.h>
#include <semaphore.h>

sem_t semaphore;

static int counter = 0;

void* worker1(void* args) {
	int i;
	int local;
	for (i = 0; i < 100; i++) {
		sem_wait(&semaphore);
		local = counter;
		printf("worker1 - %d\n", local);
		local++;
		counter = local;
		Sleep(10);
		sem_post(&semaphore);
	}
}

void* worker2(void* args) {
	int i;
	int local;
	for (i = 0; i < 100; i++) {
		sem_wait(&semaphore);
		local = counter;
		printf("worker 2 - %d\n", local);
		local--;
		counter = local;
		Sleep(10);
		sem_post(&semaphore);
	}
}

void main() {
	pthread_t thread1;
	pthread_t thread2;
	
	sem_init(&semaphore, 0, 1);

	pthread_create(&thread1, NULL, worker1, NULL);
	pthread_create(&thread2, NULL, worker2, NULL);

	pthread_join(thread1, NULL);
	pthread_join(thread2, NULL);

	sem_destroy(&semaphore);
	printf("== %d", counter);
	_getch();
}
```

Здесь всё совершено понятно. Увеличим теперь значение счётчика до 3, например. Заменим

```
sem_init(&semaphore, 0, 1);
```

на

```
sem_init(&semaphore, 0, 3);
```

Теперь мы получаем ту же неразбериху. В конце counter вряд ли будет равен нулю. Это случается от того, что после 
уменьшения значения семафора он ещё не равен нулю (3 - 1 = 2), из-за чего блокировки не происходит. Так как нет блокировки, ещё два
потока могут изменить перменную.

## Мьютексы и семафоры

Рассмотрим аналогию: мьютекс можно сравнить с ключом от туалета на заправке. Если у вас есть ключ, то вы можете зайти в туалет, и туда больше никто не зайдёт. Если у вас нет ключа, то надо ждать, и в туалет вы зайти не можете. Мьютекс ограничивает доступ к общему ресурсу и позволяет в один момент времени пользоваться этим ресурсом только одному потоку.

Этот подход, к сожалению, не масштабируется на два туалета. И семафор не может разрешить проблему: по аналогии, мы имели бы на заправке два одинаковых ключа для двух одинаковых туалетов. Если один человек уже зашёл в туалет, то у второго оказался бы дубликат, способный открыть дверь туалета (свободного или занятого). Для предупреждения такой ситуации необходимо вводить флаг «туалет занят» (а это два мьютекса…), или же с самого начала использовать два разных ключа (т.е., два мьютекса). Семафор не помогает нам решать проблему доступа до набора идентичных ресурсов.

Цель использования семафора – оповещение одним потоком другого. Когда мы используем мьютекс, сначала мы его захватываем, 
потом используем ресурс, потом отдаём, и поступаем так всегда, потому что это обеспечивает защиту ресурса. 
В противоположность этому, потоки, которые используют семафор, либо ждут, либо сигналят, но не делают того и другого вместе. 
Например, один поток «нажимает» на кнопку, а второй отвечает на нажатие выводом сообщения.

Важно также, что сигнал может быть послан из обработчика прерываний, и не является блокирующей операцией, поэтому часто используется в ОС реального времени.

Рассмотрим следующий пример. Есть три потока. Все три создаются одновременно, но второй  должен работать только после того, как отработает 
первый, а третий после того, как отработает второй.

```
#define _CRT_SECURE_NO_WARNINGS
#define _CRT_RAND_S
#include <pthread.h>
#include <stdio.h>
#include <semaphore.h>

#ifdef _WIN32
	#include <conio.h>
	#include <Windows.h>
	#define Sleep(x) Sleep(x)
	#define wait() _getch()
#else
	#include <unistd.h>
	#define Sleep(x) sleep(x)
	#define wait() scanf("1")
#endif

sem_t semaphore1;
sem_t semaphore2;

static int counter = 0;

void* waiter(void* args) {
	Sleep(3000);
	sem_wait(&semaphore2);
	printf("waiter work!");
}

void* signaler1(void* args) {
	Sleep(1500);
	sem_post(&semaphore1);
	printf("signaler1 work!");
}

void* signaler2(void* args) {
	Sleep(2500);
	sem_wait(&semaphore1);
	sem_post(&semaphore2);
	printf("signaler2 work!");
}

void main() {
	pthread_t thread1;
	pthread_t thread2;
	pthread_t thread3;

	sem_init(&semaphore1, 0, 0);
	sem_init(&semaphore2, 0, 0);
	
	pthread_create(&thread1, NULL, waiter, NULL);
	pthread_create(&thread2, NULL, signaler1, NULL);
	pthread_create(&thread3, NULL, signaler2, NULL);

	pthread_join(thread1, NULL);
	pthread_join(thread2, NULL);
	pthread_join(thread3, NULL);

	sem_destroy(&semaphore1);
	sem_destroy(&semaphore2);
	wait();
}
```

