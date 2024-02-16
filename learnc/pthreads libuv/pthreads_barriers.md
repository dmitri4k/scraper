## Барьер

Барьер – это механизм синхронизации, который позволяет приостановить выполнение потоков у некоторой точки программы до тех пор, пока все потоки 
не дойдут до этого места, и только затем продолжить выполнение дальше.

В отличие от join-а, где мы ожидаем завершения выполнения потока, при использовании барьеров мы ожидаем встречи (рандеву, rendezvous) этих потоков в определённой точке. 
Мы определяем количество потоков, которые должны прибыть к этой точке, блокируем их там, а когда набирается нужное число потоков, разблокируем их все, позволяя работать дальше.

Для создания барьера необходимо создать переменную типа pthread_barrier_t.

Инициализация барьера происходит с помощью функции

```
int pthread_barrier_init(pthread_barrier_t *restrict barrier, 
					     const pthread_barrierattr_t *restrict attr, 
						 unsigned count);
```

Здесь первый аргумент – это указатель на нашу переменную – барьер. Вторая переменная – атрибуты барьера (если их нет, то пишем NULL), последний аргумент – число потоков, которые должны вызвать pthread_barrier_wait, чтобы преодолеть (разблокировать) барьер.
Функция может возвращать ошибки

Кроме того, она обязательно возвратит ошибку, если

pthread_barrier_init выделяет нужные для работы барьера ресурсы, поэтому необходимо очищать их после использования с помощью функции

```
int pthread_barrier_destroy(pthread_barrier_t *barrier);
```

В случае удачного завершения, как обычно, функция возвращает 0. Возможны следующие ошибки

Собственно синхронизация осуществляется с помощью функции

```
int pthread_barrier_wait(pthread_barrier_t *barrier);
```

Поток, которые вызывает функцию pthread_barrier_wait блокируется в месте вызова, до тех пор, пока количество потоков, вызвавших pthread_barrier_wait не станет равным значению count, которое было задано при инициализации этого барьера.

В случае вызова функция возвращает значение PTHREAD_BARRIER_SERIAL_THREAD для произвольного синхронизированного потока, и 0 для всех остальных. Функция возвратит

Если функция pthread_barrier_wait возвращает значение PTHREAD_BARRIER_SERIAL_THREAD, это значит, что барьер может быть уничтожен. То есть, нельзя просто так уничтожать 
барьер в каком-то из потоков, так как порядок завершения потоков не детерминирован.

## Примеры

Пример из предыдущей главы. Задача - вывести в четыре потока четыре строки. Только вместо join-ов теперь будем использовать барьеры. Барьер
для нашей программы может быть глобальной переменной

```
#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <conio.h>

#define ERROR_CREATE_THREAD   -11
#define ERROR_JOIN_THREAD     -12
#define BAD_MESSAGE			  -13
#define ERROR_INIT_BARRIER    -14
#define ERROR_WAIT_BARRIER    -15
#define ERROR_DESTROY_BARRIER -16
#define SUCCESS				    0

//Барьер - глобальная переменная
static pthread_barrier_t barrier;

typedef struct someArgs_tag {
	int id;
	const char *msg;
	int out;
} someArgs_t;

void* helloWorld(void *args) {
	someArgs_t *arg = (someArgs_t*) args;
	int id = arg->id;
	int len;
	int status;
	int retVal;
	//Независимо от исхода, функция должна вызвать
	//pthread_barrier_wait, поэтому делаем одну точку выхода из функции
	if (arg->msg == NULL) {
		retVal = BAD_MESSAGE;
	} else {
		len = strlen(arg->msg);
		printf("%s\n", arg->msg);
		arg->out = len;
		retVal = SUCCESS;
	}

	status = pthread_barrier_wait(&barrier);
	if (status == PTHREAD_BARRIER_SERIAL_THREAD) {
		pthread_barrier_destroy(&barrier);
	} else if (status != 0) {
		printf("error wait barrier in thread %d with status = %d\n", arg->id, status);
		exit(ERROR_WAIT_BARRIER);
	}
	return retVal;
}

#define NUM_THREADS 4

int main() {
	pthread_t threads[NUM_THREADS];
	int status;
	int i;
	int status_addr;
	someArgs_t args[NUM_THREADS];
	const char *messages[] = {
		"First",
		NULL,
		"Third Message",
		"Fourth Message"
	};

	for (i = 0; i < NUM_THREADS; i++) {
		args[i].id = i;
		args[i].msg = messages[i];
	}

	status = pthread_barrier_init(&barrier, NULL, NUM_THREADS + 1);
	if (status != 0) {
		printf("main error: can't init barrier, status = %d\n", status);
		exit(ERROR_INIT_BARRIER);
	}

	for (i = 0; i < NUM_THREADS; i++) {
		status = pthread_create(&threads[i], NULL, helloWorld, (void*) &args[i]);
		if (status != 0) {
			printf("main error: can't create thread, status = %d\n", status);
			exit(ERROR_CREATE_THREAD);
		}
	}
	printf("Main Message\n");

	status = pthread_barrier_wait(&barrier);
	if (status == PTHREAD_BARRIER_SERIAL_THREAD) {
		pthread_barrier_destroy(&barrier);
	} else if (status != 0) {
		printf("error wait barrier in main thread with status = %d\n", status);
		exit(ERROR_WAIT_BARRIER);
	}

	for (i = 0; i < NUM_THREADS; i++) {
		printf("thread %d arg.out = %d\n", i, args[i].out);
	}

	_getch();
	return 0;
}
```

Внимательно смотрим на функцию. Раньше она выглядела так

```
void* helloWorld(void *args) {
    someArgs_t *arg = (someArgs_t*) args;
    int len;
 
    if (arg->msg == NULL) {
        return BAD_MESSAGE;
    }
 
    len = strlen(arg->msg);
    printf("%s\n", arg->msg);
    arg->out = len;
 
    return SUCCESS;
}
```

В случае, если передавался невалидный аргумент, функция возвращала значение. pthread_join дожидался завершения процесса и
синхронизировал работу. В нашем случае с барьерами мы не можем просто выйти из функции: обязательно должна быть вызвана функция
pthread_barrier_wait, иначе все остальные потоки заблокируются и барьер никогда не преодолеется.

Значение count при инициализации барьера равно NUM_THREADS + 1, потому что функция main, внутри которой порождаются потоки,
сама выполняется в своём потоке.

Глобальные переменные это почти всегда плохо. Будем передавать барьер всем потокам вместе с аргументами. Для этого изменим структуру
someArgs_tag:

```
#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <conio.h>

#define ERROR_CREATE_THREAD   -11
#define ERROR_JOIN_THREAD     -12
#define BAD_MESSAGE			  -13
#define ERROR_INIT_BARRIER    -14
#define ERROR_WAIT_BARRIER    -15
#define ERROR_DESTROY_BARRIER -16
#define SUCCESS				    0

typedef struct someArgs_tag {
	int id;
	const char *msg;
	int out;
	pthread_barrier_t *bar;
} someArgs_t;

void* helloWorld(void *args) {
	someArgs_t *arg = (someArgs_t*) args;
	int id = arg->id;
	int len;
	int status;
	int retVal;
	
	if (arg->msg == NULL) {
		retVal = BAD_MESSAGE;
	} else {
		len = strlen(arg->msg);
		printf("%s\n", arg->msg);
		arg->out = len;
		retVal = SUCCESS;
	}

	status = pthread_barrier_wait(arg->bar);
	if (status == PTHREAD_BARRIER_SERIAL_THREAD) {
		pthread_barrier_destroy(arg->bar);
	} else if (status != 0) {
		printf("error wait barrier in thread %d with status = %d\n", arg->id, status);
		exit(ERROR_WAIT_BARRIER);
	}
	return retVal;
}

#define NUM_THREADS 4

int main() {
	pthread_t threads[NUM_THREADS];
	int status;
	int i;
	int status_addr;
	someArgs_t args[NUM_THREADS];
	const char *messages[] = {
		"First",
		NULL,
		"Third Message",
		"Fourth Message"
	};
	pthread_barrier_t barrier;

	for (i = 0; i < NUM_THREADS; i++) {
		args[i].id = i;
		args[i].msg = messages[i];
		args[i].bar = &barrier;
	}

	status = pthread_barrier_init(&barrier, NULL, NUM_THREADS + 1);
	if (status != 0) {
		printf("main error: can't init barrier, status = %d\n", status);
		exit(ERROR_INIT_BARRIER);
	}

	for (i = 0; i < NUM_THREADS; i++) {
		status = pthread_create(&threads[i], NULL, helloWorld, (void*) &args[i]);
		if (status != 0) {
			printf("main error: can't create thread, status = %d\n", status);
			exit(ERROR_CREATE_THREAD);
		}
	}
	printf("Main Message\n");

	status = pthread_barrier_wait(&barrier);
	if (status == PTHREAD_BARRIER_SERIAL_THREAD) {
		pthread_barrier_destroy(&barrier);
	} else if (status != 0) {
		printf("error wait barrier in main thread with status = %d\n", status);
		exit(ERROR_WAIT_BARRIER);
	}

	for (i = 0; i < NUM_THREADS; i++) {
		printf("thread %d arg.out = %d\n", i, args[i].out);
	}

	_getch();
	return 0;
}
```

ЗАМЕЧАНИЕ: Всё, написаное выше, работает по случайности. В чём же проблема? Проблема заключается в том, что операции pthread_barrier_wait и pthread_barrier_destroy
не являются атомарными. То есть, пока один поток выполняет wait, другой в это время может выполнить свой wait, получить PTHREAD_BARRIER_SERIAL_THREAD и начать уничтожать
барьер. Другой поток, который ещё выполняет wait, не получит валидного барьера (а может быть и получит, в спецификации сказано, что состояние барьера 
после уничтожения без инициализации не определено) и выпадет с ошибкой типа "нарушение прав доступа при чтении по адресу 0xFEEEFEEE".

Решение - явно собрать все потоки, и только потом уничтожить барьер.

Напишем функцию seqMap, которая применяет к каждому элементу массива функцию. В качестве аргументов будем передавать указатель типа void (массив неопределённого типа),
число элементов, размер одного элемента массива и указатель но функцию, которая будет применяться к аргументам. Код должен быть известен из темы об указателях на функции.

```
void seqMap(void *data, size_t size, size_t item_size, void(*f)(void*)) {
	char     *from;
	const char *to;
	
	assert(data);
	assert(f);

	from = (char*)data;
	to   = (char*)data + size * item_size;

	while (from < to) {
		f(from);
		from += item_size;
	}

	return;
}
```

Задача: ускорить выполнение этой функции, путём распараллеливания вычислений. В нашем примере функция применяется к каждому элементу массива. Все
элементы точно не зависят друг от друга. То есть, можно разбить массив на участки, каждый из которых будет обрабатываться своим потоком.

Чтобы поток мог обрабатывать свой участок массива, он должен получить указатель на этот массив, начальный и конечный элементы, а также размер элемента массива
и указатель на функцию. Кроме того, будем передавать указатель на барьер.

```
typedef struct argParMap_tag {
	int id;
	void *data;				//массив
	size_t item_size;		//размер элемента массива
	size_t from;			//с какого элемента начать
	size_t to;				//до какого элемента
	void (*f)(void*);		//функция
	pthread_barrier_t *bar; //барьер
} argParMap_t;
```

Далее нужно описать функцию, которая будет работать в потоке и обрабатывать наш подмассив:

```
void* parMapTask(void *args) {
	argParMap_t *arg = (argParMap_t*) args;
	char  *from      = (char*) arg->data + arg->from * arg->item_size;
	const char *to   = (char*) arg->data + arg->to * arg->item_size;
	size_t size      = arg->item_size;
	void (*f)(void*) = arg->f;
	int status;

	while (from < to) {
		f(from);
		from += size;
	}

	status = pthread_barrier_wait(arg->bar);
	if (status != 0 && status != PTHREAD_BARRIER_SERIAL_THREAD) {
		exit(status);
	}

	return 0;
}
```

Эта функция будет выполняться в своём потоке. Теперь нужно описать функцию, которая будет создавать потоки и распределять по ним нагрузку.
Если нужно обработать, скажем, 10 элементов в 3 потока, то каждый из потоков должен получить подмассив размером 10/3 = 3 элемента, и один
из потоков должен будет вдобавок обработать ещё 10 % 3 = 1 элемент.
Наша функция будет получать указатель на массив, размер массива, размер элемента, функцию и число потоков. Число потоков обязательно должно быть меньше числа 
элементов массива.

```
void parMap(void *data, size_t size, size_t item_size, void (*f)(void*), unsigned num_of_threads) {
	pthread_t *threads = NULL;	//потоки
	argParMap_t  *args = NULL;	//аргументы
	unsigned items_per_thread;	//число элементов массива на поток
	unsigned residue;			//остаток
	unsigned i;
	int status;
	pthread_barrier_t bar;		//барьер

	assert(num_of_threads <= size);
	assert(data);
	assert(f);

	threads = (pthread_t*)malloc(sizeof(pthread_t)*num_of_threads);
	assert(threads);
	args = (argParMap_t*)malloc(sizeof(argParMap_t)*num_of_threads);
	assert(args);

	status = pthread_barrier_init(&bar, NULL, num_of_threads + 1);
	if (status != 0) {
		exit(status);
	}

	items_per_thread = size / num_of_threads;
	residue = size % num_of_threads;

	for (i = 0; i < num_of_threads; i++) {
		args[i].id = i;
		args[i].data = data;
		args[i].f = f;
		args[i].from = i*items_per_thread;
		args[i].to = (i + 1)*items_per_thread;
		args[i].item_size = item_size;
		args[i].bar = &bar;
	}
	args[num_of_threads - 1].to += residue;
	
	for (i = 0; i < num_of_threads; i++) {
		status = pthread_create(&threads[i], NULL, parMapTask, (void*) &args[i]);
		if (status != 0) {
			exit(status);
		}
	}

	
	pthread_barrier_wait(&bar);
	for (i = 0; i < num_of_threads; i++) {
		pthread_join(threads[i], NULL);
	}
	pthread_barrier_destroy(&bar);

	free(threads);
	free(args);

	return;
}
```

Теперь осталось протестировать. Будет два теста: одан маленький, без измерения времени работы, второй большой. Для тестирования зададим несколько функций обработчиков..

```
void doubleInt(void *arg) {
	*((int*)arg) *= 2;
	return;
}

void doubleFloat(void *arg) {
	*((float*)arg) *= 2.0f;
	return;
}

void processDouble(void *arg) {
	double val = *(double*)arg;
	val = log(sqrt(1.0/val) + log(pow(val, 3.141592))) / (val*val);
	*(double*)arg = val;
	return;
}
```

Заметьте, последняя функция специально такая сложная, чтобы повысить время выполнения.

```
void test_works() {
	int   datai[10] = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 };
	float dataf[10] = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 };
	int i;

	parMap(datai, 10, sizeof(int), doubleInt, 2);
	for (i = 0; i < 10; i++) {
		printf("%3d ", datai[i]);
	}
	printf("\n");
	seqMap(datai, 10, sizeof(int), doubleInt);
	for (i = 0; i < 10; i++) {
		printf("%3d ", datai[i]);
	}
	printf("\n-------------------\n");

	parMap(dataf, 10, sizeof(float), doubleFloat, 5);
	for (i = 0; i < 10; i++) {
		printf("%5.2f ", dataf[i]);
	}
	printf("\n");
	seqMap(dataf, 10, sizeof(float), doubleFloat);
	for (i = 0; i < 10; i++) {
		printf("%5.2f ", dataf[i]);
	}
	printf("\n");
	printf("press any key to continue...\n");
	_getch();
}

static const int test_data_size = 10000000;
static const int num_of_threads = 4;

void test_performance() {
	double *data = NULL;
	LARGE_INTEGER frequency;        // ticks per second
	LARGE_INTEGER t1, t2;           // ticks
	double elapsedTime;

	QueryPerformanceFrequency(&frequency);
	data = (double*)malloc(sizeof(double)*test_data_size);

	QueryPerformanceCounter(&t1); {
		seqMap(data, test_data_size, sizeof(double), processDouble);
	} QueryPerformanceCounter(&t2);
	elapsedTime = (t2.QuadPart - t1.QuadPart) * 1000.0 / frequency.QuadPart;
	printf("seq ready in %.3f ms\npress any key to continue...\n", elapsedTime);
	_getch();

	QueryPerformanceCounter(&t1); {
		parMap(data, test_data_size, sizeof(double), processDouble, num_of_threads);
	} QueryPerformanceCounter(&t2);
	elapsedTime = (t2.QuadPart - t1.QuadPart) * 1000.0 / frequency.QuadPart;
	printf("par ready in %.3f ms\npress any key to continue...\n", elapsedTime);
	_getch();

	free(data);
}

void main() {
	test_works();
	test_performance();
}
```

Замечания. Во-первых, массив для тестирования создаётся динамически. Если делать локальную переменную, то будет переполнение стека,
так как массив большой. Второе: мы используем типы данных и функции, специфичные для Windows, поэтому нужно будет подключить
библиотеку windows.h.

Запустите программу, откройте диспетчер задач и посмотрите на загрузку процессора. На моём двухядерной процессоре (Intel Core Duo T6600), при работе в два потока 
время выполнения параллельного алгоритма примерно в два раза меньше, чем последовательного. Нагрузка на процессор для однопоточного алгоритма
соответственно 50%, многопоточного 100%.
Для четырёхядерного процессора Intel i5 2310 время выполнения в 4 потока, как это ни удивительно, в 4 раза быстрее, чем однопоточный вариант. Нагрузка на процессор повышается
с 25% до 100%.

Код программы

