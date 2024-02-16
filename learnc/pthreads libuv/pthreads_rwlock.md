RW-lock (блокировка чтения-записи, блокировка «много читателей, один писатель») – это примитив синхронизации, который позволяет решить проблему «читателей-писателя»
Проблема «много читателей, один писатель» довольно часто встречается при решении практических задач многопоточного программирования. Такая проблема появляется тогда, когда много потоков читают данные, и один поток пишет (изменяет) данные. Простой подход – использованием мьютекса – считается медленным, так как нет необходимости блокировать ресурс, когда его только читают.
Pthreads решает эту проблему  с помощью блокировки чтения-записи, которая обеспечивает множественный доступ потоков читателей, и эксклюзивный доступ потока писателя.

В отличие от мьютекса, rwlock имеет два набора  функций блокировки-освобождения ресурса – один для потоков читателей, другой для потока писателя. Инициализируется ресурс типа pthread_rwlock_t либо стандартным инициализатором  PTHREAD_RWLOCK_INITIALIZER
, либо функцией



```
int pthread_rwlock_init(pthread_rwlock_t *rwlock, const pthread_rwlockattr_t *attr);
```

которая принимает в качестве первого аргумента указатель на блокировку, в качестве второго – атрибуты вновь создаваемой блокировки. Во время инициализации, конечно, могут появиться ошибки, из-за которых функция «упадёт»:



Уничтожение блокировки производится с помощью функции

```
int pthread_rwlock_destroy(pthread_rwlock_t *rwlock);
```

которая может упасть в случае ошибок

Блокировка осуществляется с помощью функций int

```
pthread_rwlock_rdlock(pthread_rwlock_t *rwlock);
int pthread_rwlock_tryrdlock(pthread_rwlock_t *rwlock);
int pthread_rwlock_timedrdlock(pthread_rwlock_t *restrict rwlock, const struct timespec *restrict abs_timeout);
```

для читателя, и

```
int pthread_rwlock_wrlock(pthread_rwlock_t *rwlock);
int pthread_rwlock_trywrlock(pthread_rwlock_t *rwlock);
int pthread_rwlock_timedwrlock(pthread_rwlock_t *restrict rwlock, const struct timespec *restrict abs_timeout);
```

для писателя. Эти функции и возвращаемые ошибки идентичны функциями для работы с мьютексами.

А теперь стандартный неинтересный пример

```
#define _CRT_SECURE_NO_WARNINGS
#define _CRT_RAND_S
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef WIN32
#include <conio.h>
#include <Windows.h>

#define Sleep(X) Sleep(X)
#define wait() _getch()
#else
#define Sleep(X) sleep(x)
#define wait() scanf("1")
#endif

char* data;

typedef struct arg_tag {
	pthread_rwlock_t *lock;
	pthread_spinlock_t *stop_flag_lock;
	int *stop;
	const char* thread_name;
} arg_t;

void* reader(void *args) {
	arg_t *arg = (arg_t*) args;
	int stop_flag;
	do {
		pthread_spin_lock(arg->stop_flag_lock);
		stop_flag = *arg->stop;
		pthread_spin_unlock(arg->stop_flag_lock);
		if (stop_flag) {
			break;
		}
		pthread_rwlock_rdlock(arg->lock);
		printf("reader %s [%s]\n", arg->thread_name, data);
		pthread_rwlock_unlock(arg->lock);
		Sleep(3000);
	} while(1);
}

void* fwriter(void *args) {
	arg_t *arg = (arg_t*) args;
	int stop_flag;
	unsigned int rand = 0;

	do {
		pthread_spin_lock(arg->stop_flag_lock);
		stop_flag = *arg->stop;
		pthread_spin_unlock(arg->stop_flag_lock);
		if (stop_flag) {
			break;
		}

		pthread_rwlock_wrlock(arg->lock);
		free(data);
		data = (char*) malloc(100);
		rand_s(&rand);
		rand = rand % 1000;
		_itoa(rand, data, 10);
		printf("\n\n\nwriter %s [%s]\n\n\n\n", arg->thread_name, data);
		pthread_rwlock_unlock(arg->lock);
		Sleep(rand);
	} while(1);
}

int main() {
	pthread_rwlock_t rw_lock;
	pthread_spinlock_t stop_spin;
	pthread_t readers[5];
	pthread_t writer;
	int stop = 0;
	int i;

	arg_t wtr = {
		&rw_lock,
		&stop_spin,
		&stop,
		"writer"
	};
	arg_t rdr[] = { {
		&rw_lock,
		&stop_spin,
		&stop,
		"reader 1"
	},{
		&rw_lock,
		&stop_spin,
		&stop,
		"reader 2"
	},{
		&rw_lock,
		&stop_spin,
		&stop,
		"reader 3"
	},{
		&rw_lock,
		&stop_spin,
		&stop,
		"reader 4"
	},{
		&rw_lock,
		&stop_spin,
		&stop,
		"reader 5"
		}
	};

	data = (char*) malloc(100);
	strcpy(data, "source");

	pthread_rwlock_init(&rw_lock, NULL);
	pthread_spin_init(&stop_spin, 0);

	for (i = 0; i < 5; i++) {
		pthread_create(&readers[i], NULL, reader, &rdr[i]);
		pthread_detach(readers[i]);
	}
	pthread_create(&writer, NULL, fwriter, &wtr);
	pthread_detach(writer);

	wait();
	pthread_spin_lock(&stop_spin);
	stop = 1;
	pthread_spin_unlock(&stop_spin);
	wait();

	return 0;
}
```

