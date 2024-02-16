## Спинлок

Одна из проблем мьютекса - низкая скорость работы. Это связано с его механизмом работы. При попытке захватить блокированный мьютекс поток 
помещается в очередь ожидающих потоков и уходит в сон. При освобождении ресурса потоки достаются из очереди и приступают к работе.

Отличие спинлока в том, что он продолжает пытаться захватить ресурс, даже если ресурс блокирован. Таким образом, время ожидания снижается. 
Очевидно, что минусом будет то, что спинлок отъедает процессорное время, хотя, на многопроцессорных системах этот недостаток хорошо 
нейтрализуется. Спинлок полезно использовать в том случае, когда известно, что время ожидания очень маленькое.

Спинлок реализован с помощью атомарных операций (как и все остальные примитивы синхронизации...), на процессорном уровне в виде
 бесконечного цикла. Тем не менее, спинлок может быть реализован более сложно, применяя в разных случаях различные 
стратегии. Например, он может работать как мьютекс (уводить поток в сон) при большом числе попыток разблокировки ресурса.

Сейчас рассмотрим только базовые операции и очень простой пример. Далее, рассмотрим большой пример с использованием одновременно
условных переменных, мьютексов и спинлоков (очередь сообщений).

Спинлок представляет собой экземпляр переменной типа pthread_spinlock_t; инициализируется с помощью функции

```
int pthread_spin_init(pthread_spinlock_t *lock, int pshared);
```

где, как заведено, первый аргумент указатель на переменную спинлок, второй аргумент указывает, может ли спинлок использоваться 
потоками, принадлежащими разным процессам, при использовании общей памяти между процессами. В наших примерах мы нигде
не используем несколько процессов, а только создаём много потоков внутри одного процесса.

```
int pthread_spin_destroy(pthread_spinlock_t *lock);
```

функция уничтожает спинлок и принимает в качестве аргумента, очевидно, указатель на спинлок.

Функции могут вернуть слебующий ошибки

Отдельно, pthread_spin_init может вернуть

У спинлока нет инициализатора по умолчанию.

Блокировка потока спинлоком осуществляется с помощью функции

```
int pthread_spin_lock(pthread_spinlock_t *lock);
```

и с помощью функции

```
int pthread_spin_trylock(pthread_spinlock_t *lock);
```

Первая функция старается получить блокировку, и делает это до тех пор, пока не получит. Вторая функция
пытается получить блокировку спинлока и возвращает ошибку, если спинлок уже занят другим потоком.

Обе функции могут вернуть ошибки

pthread_spin_lock может вернуть

pthread_spin_trylock может вернуть

Разблокировка спинлока производится с помощью функции

```
int pthread_spin_unlock(pthread_spinlock_t *lock);
```

с ошибками

Пример, который уже рассматривали, только с использованием спинлока

```
#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#ifdef WIN32
	#include <conio.h>
	#include <Windows.h>
	#define Sleep(X) Sleep(X)
	#define wait() _getch()
#else
	#include <unistd.h>
	#define Sleep(X) sleep(X)
	#define wait() scanf("1")
#endif

static int counter;

void* plus(void *args) {
	int local, i;
	pthread_spinlock_t *spin = (pthread_spinlock_t*)args;
	for (i = 0; i < 100; i++) {
		pthread_spin_lock(spin);
		local = counter;
		local++;
		counter = local;
		pthread_spin_unlock(spin);
		printf("plus %d\n", local);
	}
}

void* minus(void *args) {
	int local, i;
	pthread_spinlock_t *spin = (pthread_spinlock_t*)args;
	for (i = 0; i < 100; i++) {
		pthread_spin_lock(spin);
		local = counter;
		local--;
		counter = local;
		pthread_spin_unlock(spin);
		printf("minus %d\n", local);
	}
}

void main() {
	pthread_t p_thread;
	pthread_t m_thread;
	pthread_spinlock_t spin;

	pthread_spin_init(&spin, 0);

	pthread_create(&p_thread, NULL, plus, &spin);
	pthread_create(&m_thread, NULL, minus, &spin);

	pthread_detach(p_thread);
	pthread_detach(m_thread);

	wait();

	pthread_cancel(p_thread);
	pthread_cancel(m_thread);
	
	pthread_spin_destroy(&spin);
}
```

Немного о коде и о том, что раньше не встречалось.

```
pthread_detach(p_thread);
```

Функция pthread_detach означает, что мы не будем ждать конца выполнения потока, как в случае pthread_join.

```
pthread_cancel(p_thread);
```

Функция pthread_cancel останавливает поток.

