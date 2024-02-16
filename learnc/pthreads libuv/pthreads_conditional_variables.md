Поставим задачу. Пусть есть процесс, один или несколько, которые генерируют задачи. Делают они это через неопределённые промежутки времени. И есть один процесс, который обрабатывает эти задачи. Например, есть поток, который занимается рассылкой писем, и несколько потоков, которые кидают сообщения к отправке.
Каким образом реализовать поток, занимающийся обработкой сообщений? С имеющимися у нас инструментами, можно создать бесконечный цикл, который будет через определённые промежутки времени проверять, есть ли данные, которые необходимо обработать, и обрабатывать их. Так как есть общий ресурс (в нашем упрощённом примере это будет массив со счётчиком), то для работы с ним нужно будет вводить мьютекс.



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

static int stack[100];
static size_t counter;

pthread_mutex_t mut;

void* consumer(void *args) {
	while (1) {
		pthread_mutex_lock(&mut);
		int hadSome = 0;
		if (counter > 0) {
			hadSome = 1;
			while (counter > 0) {
				counter--;
				printf("consumer processed %d\n", stack[counter]);
			}
		}
		pthread_mutex_unlock(&mut);
		if (!hadSome) {
			printf("consumer found empty stack\n");
		}
		Sleep(10);
	}
}

void* producer(void *args) {
	while (1) {
		int rand;
		rand_s(&rand);
		rand = abs(rand % 1000);
		pthread_mutex_lock(&mut);
		stack[counter] = rand;
		counter++;
		printf("producer put %d\n", rand);
		pthread_mutex_unlock(&mut);
		Sleep(rand);
	}
}

void main() {
	pthread_t p_thread;
	pthread_t c_thread;

	pthread_mutex_init(&mut, NULL);

	pthread_create(&p_thread, NULL, producer, NULL);
	pthread_create(&c_thread, NULL, consumer, NULL);

	pthread_detach(p_thread);
	pthread_detach(c_thread);

	wait();

	pthread_cancel(p_thread);
	pthread_cancel(c_thread);

	pthread_mutex_destroy(&mut);
}
```

Какие здесь есть проблемы?

Нам бы хотелось, чтобы поток ожидал события, не выполняя лишних действий, пока ему не придёт сообщение. После этого сообщения он начнёт 
работать. Например, поток будет ждать, пока не накопится 10 сообщений. После чего поток producer пошлёт ему сигнал. Consumer 
отработает и опять уйдёт ждать, пока не накопятся сообщения.

Для решения этой задачи можно использовать условную переменную. Условная переменная в Pthreads – это переменная типа pthread_cond_t, 
которая обеспечивает блокирование одного или нескольких потоков до тех пор, пока не придёт сигнал, или не пройдёт максимально 
установленное время ожидания. Условная переменная используется совместно с ассоциированным с ней мьютексом.

Как обычно, для создания условной переменной используется функция

```
int pthread_cond_init(pthread_cond_t *cond, const pthread_condattr_t *attr);
```

где cond – указатель на переменную типа pthread_cond_t, attr – аттрибуты условной переменной.

Понятно, что во время работы могут всплыть ошибки, например

Для уничтожения условной переменной используется функция

```
int pthread_cond_destroy(pthread_cond_t *cond);
```

которая выбрасывает ошибки

Для ожидания сигнала можно использовать функцию

```
int pthread_cond_wait(pthread_cond_t *cond, pthread_mutex_t *mutex);
```

которая ждёт неопределённо долго, или функцию

```
int pthread_cond_timedwait(pthread_cond_t *cond, 
    pthread_mutex_t *mutex, const struct timespec *abstime);
```

которая ждёт до момента abstime (это абсолютное время, а не относительное!).

Для того, чтобы послать сигнал, используются две функции

```
int pthread_cond_signal(pthread_cond_t *cond);
```

разблокирует как минимум один поток, заблокированный переменной cond, и

```
int pthread_cond_broadcast(pthread_cond_t *cond);
```

которая разблокирует все потоки, заблокированные с помощью условной переменной cond.

Обе функции могут возвратить ошибочное значение EINVAL, если аргумент функции не указывает на инициализированную переменную типа pthread_cond_t.

Рассмотрим тот же самый пример, что и выше, только с условной переменной.

```
#include <stdio.h>
#include <pthread.h>
#include <time.h>

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

static int stack[100];
static size_t counter;

pthread_mutex_t stack_mut;
pthread_cond_t stack_cond;

void* randomProducer(void* args) {
	do {
		int rand;
		rand_s(&rand);
		rand = abs(rand % 3000);
		Sleep(rand);
		pthread_mutex_lock(&stack_mut);
		printf("producer %d sent %d\n", *(int*) args, rand);
		stack[counter++] = rand;
		if (counter > 10) {
			pthread_cond_signal(&stack_cond);
		}

		pthread_mutex_unlock(&stack_mut);
	} while (1);
}

void* consumer() {
	do {
		pthread_mutex_lock(&stack_mut);
		printf("waiting for data\n");				
		while (counter > 0) {
			Sleep(100);
			counter--;
			int data = stack[counter];
			printf("data = %d processed\n", data);
		}
		printf("work done!\n");
		pthread_mutex_unlock(&stack_mut);
	} while (1);
}

void main() {
	pthread_t p_thread1;
	pthread_t p_thread2;
	pthread_t c_thread;

	int num1 = 1;
	int num2 = 2;

	pthread_mutex_init(&stack_mut, NULL);	
	pthread_cond_init(&stack_cond, NULL);

	pthread_create(&p_thread1, NULL, randomProducer, &num1);
	pthread_create(&p_thread2, NULL, randomProducer, &num2);
	pthread_create(&c_thread, NULL, consumer, NULL);
	//не ждём завершения потоков
	pthread_detach(p_thread1);
	pthread_detach(p_thread2);
	pthread_detach(c_thread);

	wait();

	pthread_cancel(p_thread1);
	pthread_cancel(p_thread2);
	pthread_cancel(c_thread);

	pthread_cond_destroy(&stack_cond);
	pthread_mutex_destroy(&stack_mut);
}
```

Здесь два потока поставщика, каждый принимает в качестве аргумента свой номер, и один поток обработчик. Код довольно простой и не требует дополнительных пояснений.

Теперь попробуем использовать функцию pthread_cond_timedwait. Для этого заменим код функции consumer на следующий:

```
void* consumer() {
	do {
		struct timespec stime;
		int now;
		int result;

		pthread_mutex_lock(&stack_mut);
		printf("waiting for data\n");		
		now = time(NULL);
		stime.tv_sec = now + 7;
		result = pthread_cond_timedwait(&stack_cond, &stack_mut, &stime);
		if (result == ETIMEDOUT) {
			printf("waiting sooooooooooooooooooooooooooooo long!\n");
		}
		while (counter > 0) {
			Sleep(100);
			counter--;
			int data = stack[counter];
			printf("data = %d processed\n", data);
		}
		printf("work done!\n");
		pthread_mutex_unlock(&stack_mut);
	} while (1);
}
```

Напишем теперь более приличный пример. Сделаем очередь сообщений. И несколько потоков, обрабатывающих очередь, и 
несколько потоков, пишущих в очередь. Так как очередь будет общим ресурсом, то запись и чтение из неё должны будут 
синхронизироваться с помощью мьютексов. Потоки обработчики также, как и в прошлом примере, будут ждать, 
пока не накопится нужное число сообщений, либо не пройдёт время для проверки очереди.

Для чистоты избавимся от глобальных переменных, очередь и все примитивы синхронизации будем передавать в аргументах. На примере рассмотрим, как ведёт себя pthread_cond_signal и pthread_cond_broadcast.

Так как задача усложнилась, разобьём решение на несколько файлов. Первым делом определимся с очередью сообщений. Так как нам надо писать в неё, и читать из неё, то ресурс должен быть защищён от многопоточного доступа мьютексом.

Файл queue.h

```
#ifndef __QUEUE_H__
#define __QUEUE_H__

#include <stdlib.h>
#include <pthread.h>

struct node_tag;
typedef struct node_tag node_t;

typedef struct queue_tag {
	pthread_mutex_t *mut;
	size_t size;	
	node_t *head;
	node_t *tail;
} queue_t;

void* pop(queue_t *);
size_t push(queue_t *, void*);
size_t get_size(queue_t *);

#endif
```

Здесь всё понятно. Функция вставки элемента в начало очереди, функция удаления с конца и функция 
получения размера. При этом функция вставки возвращает размер очереди после вставки. 
Структура node_tag – это узел двусвязного списка, описанный в queue.c. Сама очередь содержит указатель на голову, последний элемент, 
размер очереди, а также мьютекс, который используется при каждом доступе к функциям pop, push и get_size.

Файл queue.c содержит определения функций

```
#include "queue.h"

struct node_tag {
	struct node_tag *next;
	struct node_tag *prev;
	void *data;
};

void* pop(queue_t *queue) {
	void* out;
	node_t *next;
	void *tmp;

	pthread_mutex_lock(queue->mut);

   
	if (queue->tail == NULL) {
	pthread_mutex_unlock(queue->mut);
		return NULL;
	}

	next = queue->tail;
	queue->tail = queue->tail->prev;
	if (queue->tail) {
		queue->tail->next = NULL;
	}
	if (next == queue->head) {
		queue->head = NULL;
	}
	tmp = next->data;
	free(next);

	queue->size--;
    
	pthread_mutex_unlock(queue->mut);
	return tmp;
}

size_t push(queue_t *queue, void* data) {
	size_t current;
	node_t *tmp;
	pthread_mutex_lock(queue->mut);
	tmp = (node_t*) malloc(sizeof(node_t));
	tmp->data = data;
	tmp->next = queue->head;
	tmp->prev = NULL;
	if (queue->head) {
		queue->head->prev = tmp;
	}
	queue->head = tmp;

	if (queue->tail == NULL) {
		queue->tail = tmp;
   	}
    current = queue->size++;
	pthread_mutex_unlock(queue->mut);
	return current;
}

size_t get_size(queue_t *queue) {
	size_t size;
	pthread_mutex_lock(queue->mut);
	size = queue->size;
	pthread_mutex_unlock(queue->mut);
	return size;
}
```

Обращу некоторое внимание на следующие строчки.



```
if (queue->tail == NULL) {
	pthread_mutex_unlock(queue->mut);
	return NULL;
}
```

Всегда, когда мы покидаем функцию, мьютекс должен быть разблокирован, иначе мы придём либо 
к ситуации, когда все потоки встанут, ожидая мьютекса (который некому будет освободить), либо к ситуации, когда один из потоков попытается завладеть мьютексом, которым он уже владеет. Плохо!

```
current = queue->size++;
pthread_mutex_unlock(queue->mut);
return current;
```

Получение размера очереди должно также происходить внутри защищённой мьютексом области кода.

Наша очередь хранит пустой указатель, поэтому можно, в принципе, хранить там любой объект. Важно только правильным образом управлять памятью.

Теперь объявим новый тип message_t, который будет храниться в очереди. Пока в нём будет только несколько полей для тестирования.

message.h

```
#ifndef _MESSAGE_H_
#define _MESSAGE_H_
#define _CRT_SECURE_NO_WARNINGS

#include <time.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>

struct message_tag {
	time_t created_at;
	char *message;
	size_t id;
};
typedef struct message_tag message_t;

message_t* create_message(const char*, const size_t, const time_t);
void free_message(message_t **);

#endif
```

И message.c

```
#include "message.h"

message_t* create_message(const char *message, const size_t id, const time_t created_at) {
	message_t *out = (message_t*) malloc(sizeof(message_t));
	const size_t len = strlen(message) + 1;

	if (out == NULL) {
		return NULL;
	}

	out->message = (char*) malloc(sizeof(len));

	if (out->message == NULL) {
		free(out);
		return NULL;
	}

	strcpy(out->message, message);
	out->id = id;
	if (created_at == NULL) {
		out->created_at = time(NULL);
	} else {
		out->created_at = created_at;
	}

	return out;
}

void free_message(message_t **message) {
	free((*message)->message);
	free(*message);
	*message = NULL;
}
```

Сообщение состоит из времени создания, текстового сообщения и идентификатора. Например, можно в качестве сообщения посылать имя скрипта на языке lua, а при обработке события вызывать этот скрипт.

Так как мне лень, то всё остальное я опишу в файле main.c

1. Определю такой простой макрос

```
#define free(X) {free(X); X = NULL;}
```

2. Самое сложное. Объявляю структуру очередь сообщений

```
typedef struct arg_tag {
	queue_t queue;
	size_t processed;
	size_t sent;
	pthread_mutex_t *c_mut;
	pthread_cond_t *c_cond;
	pthread_spinlock_t *sent_proc_lock;
	pthread_spinlock_t *await_lock;
	unsigned char stop_prod;
	unsigned char stop_cons;
} arg_t;
```

Начинаем обсуждать поля.

queue_t queue – собственно, очередь, которую мы описали в queue.c

size_t processed – счётчик того, сколько задач обработано. 
size_t sent – сколько задач поставлено в очередь. Для работы с этими 
счётчиками будем использовать спинлок sent_proc_lock.

Потоки производители и потоки обработчики будут работать бесконечно. Для того, чтобы их остановить, используются переменные флаги 

unsigned char stop_prod;
unsigned char stop_cons;
Для безопасной работы с ними используется спинлок
pthread_spinlock_t *await_lock;

Конечно, для каждого счётчика и для каждого флага можно использовать свой спинлок (и даже лучше…), или мьютекс.

Каждый поток получит указатель на один экземпляр этой структуры. Но кроме неё я буду передавать каждому потоку ещё уникальное имя, чтобы удобнее было следить за их поведением. Для этого объявлю новую структуру

```
typedef struct arg_wrapper_tag {
	arg_t *arg;
	const char* name;
} arg_wrapper_t;
```

Функция создания arg_t переменной

```
arg_t* createArgument() {
	arg_t *arg = (arg_t*) malloc(sizeof(arg_t));

	arg->c_cond		   = (pthread_cond_t*)	malloc(sizeof(pthread_cond_t));
	arg->c_mut		   = (pthread_mutex_t*) malloc(sizeof(pthread_mutex_t));
	arg->queue.mut	   = (pthread_mutex_t*) malloc(sizeof(pthread_mutex_t));
	arg->sent_proc_lock = (pthread_spinlock_t*) malloc(sizeof(pthread_spinlock_t));
	arg->await_lock	   = (pthread_spinlock_t*) malloc(sizeof(pthread_spinlock_t));

	pthread_mutex_init(arg->c_mut, NULL);
	pthread_mutex_init(arg->queue.mut, NULL);
	pthread_cond_init(arg->c_cond, NULL);
	pthread_spin_init(arg->sent_proc_lock, 0);
	pthread_spin_init(arg->await_lock, 0);
	arg->queue.size = 0;
	arg->processed = 0;
	arg->sent = 0;
	arg->stop_cons = arg->stop_prod = 0;
	arg->queue.head = arg->queue.tail = NULL;

	return arg;
}
```

Ничего нового, просто инициализируем по порядку все поля. Здесь, конечно, опущены все проверки. В пару ей функция уничтожения полей структуры (полей, а не самой структуры)

```
void deleteArgument(arg_t *arg) {
	pthread_cond_destroy(arg->c_cond);
	pthread_mutex_destroy(arg->c_mut);
	pthread_mutex_destroy(arg->queue.mut);
	pthread_spin_destroy(arg->await_lock);
	pthread_spin_destroy(arg->sent_proc_lock);
	
	free(arg->c_cond);
	free(arg->c_mut);
	free(arg->queue.mut);
	free(arg->await_lock);
	free(arg->sent_proc_lock);
}
```

Функция производитель

```
void* producer(void *args) {
	arg_wrapper_t *raw_arg = (arg_wrapper_t*) args;
	arg_t *arg = raw_arg->arg;
	do {
		char data[1000];
		unsigned int rand;
		size_t size;
		size_t local_sent;
		message_t *message;

		pthread_spin_lock(arg->await_lock);
		if (arg->stop_prod) {
			pthread_spin_unlock(arg->await_lock);
			break;
		}
		pthread_spin_unlock(arg->await_lock);

		rand_s(&rand);
		rand %= 300;
		_itoa(rand, data, 10);

		pthread_spin_lock(arg->sent_proc_lock);
		local_sent = arg->sent++;
		pthread_spin_unlock(arg->sent_proc_lock);

		printf("%s sent %s (%d)\n", raw_arg->name, data, local_sent);
		pthread_mutex_lock(arg->c_mut);

		message = create_message(data, local_sent, NULL);

		size = push(&arg->queue, message);
		
		if (size > THRESHOLD) {
			pthread_cond_broadcast(arg->c_cond);
		}

		pthread_mutex_unlock(arg->c_mut);
		Sleep(rand);
	} while(1);
}
```

Эта функция создаёт новую задачу. В качестве текста сообщения она отправляет строку со случайным числом , это время, 
которое будет спать поток.

Рассмотрим подробнее

```
pthread_spin_lock(arg->await_lock);
if (arg->stop_prod) {
	pthread_spin_unlock(arg->await_lock);
	break;
} 
pthread_spin_unlock(arg->await_lock);
```

Здесь поток проверяет флаг await_lock. Если он установлен (т.е. не равен нулю), то продолжаем работу, иначе выходим из бесконечного цикла.

```
rand_s(&rand);
rand %= 300;
_itoa(rand, data, 10);
```

Здесь мы создаём случайное число в пределах от 0 до 300. Это сколько поток будет спать в мс. Заметьте, что мы используем rand_s функцию. rand является не потокобезопасной и будет возвращать для всех потоков одно и то же число.

Здесь мы просто увеличиваем счётчик поставленных в очередь задач.

```
pthread_spin_lock(arg->sent_proc_lock);
local_sent = arg->sent++;
pthread_spin_unlock(arg->sent_proc_lock);
```

Также хочу заметить, что спит поток уже после разблокировки мьютекса, защищающего условную переменную, иначе все остальные потоки будут его ждать.

Бродкаст произойдёт после того, как размер очереди превысит THRESHOLD.

Так как новое сообщение функцией create_message выделяет память, то её надо будет очищать

```
message = create_message(data, local_sent, NULL);
```

Теперь функция, которая обрабатывает сообщения.

```
void* consumer(void *args) {
	arg_wrapper_t *raw_arg = (arg_wrapper_t*) args;
	arg_t *arg = raw_arg->arg;
	char buffer[100];
	struct tm* tm_info;
	
	do {
		message_t *data;
		int counter = 0;
		int local_processed;
		time_t stime = time(NULL);
		struct timespec newtime;
		
		newtime.tv_sec = stime + 3;

		pthread_mutex_lock(arg->c_mut);
		pthread_cond_timedwait(arg->c_cond, arg->c_mut, &newtime);
		pthread_mutex_unlock(arg->c_mut);
		do {
			data = (message_t*) pop(&arg->queue);
			if (data == NULL) {
				break;
			}
			pthread_spin_lock(arg->sent_proc_lock);
			local_processed = arg->processed++;
			pthread_spin_unlock(arg->sent_proc_lock);

			tm_info = localtime(&data->created_at);
			strftime(buffer, 100, "%Y-%m-%d %H:%M:%S.000", tm_info);

			printf("%s processed %s (%d) at %s\n", raw_arg->name, data->message, local_processed, buffer);
			Sleep(100);
			free_message(&data);
		} while(1);

		pthread_spin_lock(arg->await_lock);
		if (arg->stop_cons && get_size(&arg->queue) == 0) {
			pthread_spin_unlock(arg->await_lock);
			break;
		}
		pthread_spin_unlock(arg->await_lock);
		
	} while(1);
}
```

Логика следующая. Функция ждёт, пока не придёт сообщение, либо пока не пройдёт больше трёх секунд от момента создания.

```
time_t stime = time(NULL);
struct timespec newtime;

newtime.tv_sec = stime + 3;

pthread_mutex_lock(arg->c_mut);
pthread_cond_timedwait(arg->c_cond, arg->c_mut, &newtime);
pthread_mutex_unlock(arg->c_mut);
```

это позволяет решить важную проблему. Если мы отключим производителей, то в очереди останутся ещё задачи. По прошествии 3-х секунд все сообщения будут обработаны, даже если некому послать бродкаст. Именно по этой причине проверять, заблокировано ли выполнение, мы будем в конце, после обработки сообщений.

```
pthread_spin_lock(arg->await_lock);
if (arg->stop_cons && get_size(&arg->queue) == 0) {
	pthread_spin_unlock(arg->await_lock);
	break;
}
pthread_spin_unlock(arg->await_lock);
```

Здесь вызов функции get_size произойдёт только после того, как проверено, что флаг остановки потока поднят. Т.е. не более одного раза, непосредственно перед остановкой.

Очищение памяти из-под сообщения

```
free_message(&data);
```

и неизвестная вам функция

```
strftime(buffer, 100, "%Y-%m-%d %H:%M:%S.000", tm_info);
```

печатающая в буфер форматированное время.

Собственно, тестирование

```
void main() {
	const char* prod_name1  = "producer1";
	const char* prod_name2  = "producer2";
	const char* cons_name1	= "consumer1";
	const char* cons_name2	= "consumer2";

	pthread_t p_thread1;
	pthread_t p_thread2;
	pthread_t c_thread1;
	pthread_t c_thread2;

	arg_t *arg = createArgument();

	arg_wrapper_t p_arg1 = { 
		arg, 
		prod_name1 
	};
	arg_wrapper_t p_arg2 = { 
		arg, 
		prod_name2 
	};
	arg_wrapper_t c_arg1 = { 
		arg, 
		cons_name1 
	};
	arg_wrapper_t c_arg2 = { 
		arg, 
		cons_name2 
	};

	pthread_create(&p_thread1,  NULL, producer, &p_arg1);
	pthread_create(&p_thread2,  NULL, producer, &p_arg2);
	pthread_create(&c_thread1, NULL, consumer, &c_arg1);
	pthread_create(&c_thread2, NULL, consumer, &c_arg2);

	wait();

	printf("try to stop threads");
	pthread_spin_lock(arg->await_lock);
	arg->stop_cons = arg->stop_prod = 1;
	pthread_spin_unlock(arg->await_lock);
	printf("...\n");

	wait();

	pthread_cancel(p_thread1);
	pthread_cancel(p_thread2);
	pthread_cancel(c_thread1);
	pthread_cancel(c_thread2);

	deleteArgument(arg);

	wait();
}
```

Код программы

В качестве задания добавьте дополнительные спинлоки для каждого флага остановки потоков и выделите все функции в отдельный файл,
оставив только функцию main.

