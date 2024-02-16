## Создание и ожидание потока

Рассмотрим простой пример

```
#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <conio.h>

#define ERROR_CREATE_THREAD -11
#define ERROR_JOIN_THREAD   -12
#define SUCCESS		   0

void* helloWorld(void *args) {
	printf("Hello from thread!\n");
	return SUCCESS;
}

int main() {
	pthread_t thread;
	int status;
	int status_addr;

	status = pthread_create(&thread, NULL, helloWorld, NULL);
	if (status != 0) {
		printf("main error: can't create thread, status = %d\n", status);
		exit(ERROR_CREATE_THREAD);
	}
	printf("Hello from main!\n");

	status = pthread_join(thread, (void**)&status_addr);
	if (status != SUCCESS) {
		printf("main error: can't join thread, status = %d\n", status);
		exit(ERROR_JOIN_THREAD);
	}

	printf("joined with address %d\n", status_addr);
	_getch();
	return 0;
}
```

В данном примере внутри основного потока, в котором работает функция main, создаётся новый поток, внутри которого вызывается функция helloWorld. Функция helloWorld выводит на 
дисплей приветствие. Внутри основного потока также выводится приветствие. Далее потоки объединяются.

Новый поток создаётся с помощью функции pthread_create

```
int pthread_create(*ptherad_t, const pthread_attr_t *attr, void* (*start_routine)(void*), void *arg);
```

Функция получает в качестве аргументов указатель на поток, переменную типа pthread_t, в которую, в случае удачного завершения сохраняет id потока. pthread_attr_t – атрибуты потока. 
В случае если используются атрибуты по умолчанию, то можно передавать NULL. start_routin – это непосредственно та функция, которая будет выполняться в новом потоке. arg – это 
аргументы, которые будут переданы функции.

Поток может выполнять много разных дел и получать разные аргументы. Для этого функция, которая будет запущена в новом потоке, принимает аргумент типа void*. За счёт этого можно обернуть все передаваемые аргументы в структуру. Возвращать значение можно также через передаваемый аргумент.

В случае успешного выполнения функция возвращает 0. Если произошли ошибки, то могут быть возвращены следующие значения

Пройдём по программе

```
#define ERROR_CREATE_THREAD -11
#define ERROR_JOIN_THREAD   -12
#define SUCCESS		   		  0
```

Здесь мы задаём набор значений, необходимый для обработки возможных ошибок.

```
void* helloWorld(void *args) {
	printf("Hello from thread!\n");
	return SUCCESS;
}
```

Это функция, которая будет работать в отдельном потоке. Она не будет получать никаких аргументов. По стандарту считается, что явный выход из функции вызывает функцию pthread_exit, а возвращаемое значение будет передано при вызове функции pthread_join, как статус.

```
status = pthread_create(&thread, NULL, helloWorld, NULL);
if (status != 0) {
	printf("main error: can't create thread, status = %d\n", status);
	exit(ERROR_CREATE_THREAD);
}
```

Здесь создаётся и сразу же исполняется новый поток. Поток не получает никаких атрибутов или аргументов. После создания потока происходит проверка на ошибку.

Вызов

```
status = pthread_join(thread, (void**)&status_addr);
if (status != SUCCESS) {
	printf("main error: can't join thread, status = %d\n", status);
	exit(ERROR_JOIN_THREAD);
}
```

Приводит к тому, что основной поток будет ждать завершения порождённого. Функция

```
int pthread_join(pthread_t thread, void **value_ptr);
```

Откладывает выполнение вызывающего (эту функцию) потока, до тех пор, пока не будет выполнен поток thread. Когда pthread_join выполнилась успешно, то она возвращает 0. 
Если поток явно вернул значение (это то самое значение SUCCESS, из нашей функции), то оно будет помещено в переменную value_ptr.
Возможные ошибки, которые возвращает pthread_join

## Пример создания потоков с передачей им аргументов

Пусть мы хотим передать потоку данные и вернуть что-нибудь обратно. Скажем, передавать потоку будем строку, а возвращать из потока длину этой строки.

Так как функция может получать только указатель типа void, то все аргументы следует упаковать в структуру. Определим новый тип структуру:

```
typedef struct someArgs_tag {
	int id;
	const char *msg;
	int out;
} someArgs_t;
```

Здесь id – это идентификатор потока (он в общем-то не нужен в нашем примере), второе поле это строка, а третье длина строки, которую мы будем 
возвращать.

Внутри функции приводим аргумент  к нужному типу, выводим на печать строку и засовываем в структуру обратно вычисленную длину строки.

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

В том случае, если всё прошло удачно, то в качестве статуса возвращаем значение SUCCESS, а если была допущена ошибка (в нашем случае, если передана нулевая строка), то выходим со статусом BAD_MESSAGE.

В этом примере создадим 4 потока. Для 4-х потоков понадобятся массив типа pthread_t длинной 4, массив передаваемых аргументов и 4 строки, которые мы и будем передавать.

```
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
```

Первым делом заполняем значения аргументов.

```
for (i = 0; i < NUM_THREADS; i++) {
	args[i].id = i;
	args[i].msg = messages[i];
}
```

Далее создаём в цикле новые потоки

```
for (i = 0; i < NUM_THREADS; i++) {
	status = pthread_create(&threads[i], NULL, helloWorld, (void*) &args[i]);
	if (status != 0) {
		printf("main error: can't create thread, status = %d\n", status);
		exit(ERROR_CREATE_THREAD);
	}
}
```

Затем ждём завершения

```
for (i = 0; i < NUM_THREADS; i++) {
	status = pthread_join(threads[i], (void**)&status_addr);
	if (status != SUCCESS) {
		printf("main error: can't join thread, status = %d\n", status);
		exit(ERROR_JOIN_THREAD);
	}
	printf("joined with address %d\n", status_addr);
}
```

Под конец ещё выводим аргументы, которые теперь хранят возвращённые значения. Заметьте, что один из аргументов «плохой» (строка равна NULL). Вот полный код

```
#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <conio.h>
#include <string.h>

#define ERROR_CREATE_THREAD -11
#define ERROR_JOIN_THREAD   -12
#define BAD_MESSAGE			-13
#define SUCCESS				  0

typedef struct someArgs_tag {
	int id;
	const char *msg;
	int out;
} someArgs_t;

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

	for (i = 0; i < NUM_THREADS; i++) {
		status = pthread_create(&threads[i], NULL, helloWorld, (void*) &args[i]);
		if (status != 0) {
			printf("main error: can't create thread, status = %d\n", status);
			exit(ERROR_CREATE_THREAD);
		}
	}

	printf("Main Message\n");

	for (i = 0; i < NUM_THREADS; i++) {
		status = pthread_join(threads[i], (void**)&status_addr);
		if (status != SUCCESS) {
			printf("main error: can't join thread, status = %d\n", status);
			exit(ERROR_JOIN_THREAD);
		}
		printf("joined with address %d\n", status_addr);
	}

	for (i = 0; i < NUM_THREADS; i++) {
		printf("thread %d arg.out = %d\n", i, args[i].out);
	}

	_getch();
	return 0;
}
```

Выполните его несколько раз. Заметьте, что порядок выполнения потоков не детерминирован. Запуская программу, можно каждый раз получить другой порядок выполнения.

