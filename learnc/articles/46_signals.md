## Сигналы

Сигналы – это ограниченная форма межпроцессного взаимодействия. Сигнал – это асинхронное
уведомление, отосланное процессу или определённому потоку процесса для того, чтобы сообщить ему о каком-то событии.

Работа с сигналами хорошо развита в UNIX-подобных операционных системах. Стандарт си определяет всего шесть сигналов, которые могут быть обработаны.

Кроме того, есть сигналы, которые не могут быть обработаны, пойманы или игнорированы.

Для обработки сигналов в библиотеке signals.h определены функции

```
void (*signal(int sig, void (*func)(int)))(int);
```

Эта функция принимает в качестве аргумента сигнал и указатель на void функцию, которая принимает сигнал. Функция возвращает указатель на функцию, которая была перед этим задана в качестве обработчика. Если функция отработала с ошибкой, то она вернёт значение SIGERR.

В качестве обработчика можно задать два предопределённых значения

Для того, чтобы из программы послать сигнал, используется функция

```
int raise(int)
```

Если функция отработала успешно, то возвращается 0, иначе ненулевое значение.

Такое объяснение довольно запутанно. Посмотрим простой пример.

```
#include <signal.h>
#include <conio.h>
#include <stdio.h>

//обработчик
void listener(int sig) {
	fprintf(stdout, "listener\n");
}

void main() {
	//устанавливаем обработчик для сигнлана SIGINT
	signal(SIGINT, listener);
	fprintf(stdout, "begin\n");
	//посылаем сигнал
	raise(SIGINT);
	fprintf(stdout, "end\n");
	_getch();
}
```

Вызов и обработка сигнала внутри одного процесса являются синхронными. То есть, при посылке сигнала управление переходит к обработчику, новых потоков не создаётся. После того, как отработал обработчик, управление возвращается тому, кто послал сообщение.

Немного переделаем программу, чтобы она стала цивильнее

```
#include <signal.h>
#include <conio.h>
#include <stdio.h>

//обработчик
void listener(int sig) {
	fprintf(stdout, "listener\n");
}

void main() {
	int status;
	//устанавливаем обработчик для сигнала SIGINT
	status = signal(SIGINT, listener);
	if (SIG_ERR == status) {
		fprintf(stdout, "error signal");
		exit(1);
	}
	printf("begin\n");
	//посылаем сигнал
	status = raise(SIGINT);
	if (0 != status) {
		fprintf(stdout, "error raise");
		exit(1);
	}
	fprintf(stdout, "end\n");
	_getch();
}
```

Теперь сделаем следующее – напишем три обработчика. Каждый будет устанавливать следующий.

```
#include <signal.h>
#include <conio.h>
#include <stdio.h>

//обработчик3
void listener3(int sig) {
	fprintf(stdout, "listener3\n");
}
//обработчик2
void listener2(int sig) {
	fprintf(stdout, "listener2\n");
	//установили в качестве обработчика listener3
	signal(SIGINT, listener3);
}
//обработчик1
void listener1(int sig) {
	fprintf(stdout, "listener1\n");
	//установили в качестве обработчика listener2
	signal(SIGINT, listener2);
}

void main() {
	int status;
	//устанавливаем обработчик для сигнлана SIGINT
	signal(SIGINT, listener1);
	printf("begin\n");
	//посылаем сигнал
	raise(SIGINT);
	raise(SIGINT);
	raise(SIGINT);
	fprintf(stdout, "end\n");
	_getch();
}
```

Более интересный пример: будем читать чужую память, пока не выпадет Access Violation:

```
#include <signal.h>
#include <conio.h>
#include <stdio.h>

void listener(int sig) {
	printf("listener: access violation");
	_getch();
}

void main() {
	char a = 10;
	char *p = &a;

	signal(SIGSEGV, listener);

	do {
		printf("%d", *p++);
	} while (1);

	_getch();
}
```

К большому сожалению, восстановить программу после такой ошибки по стандарту не получится (только используя системные функции, специфичные для ОС). После того, как был послан сигнал SIGSEGV он будет обработан функцией listener. Но после этого управление вернётся к функции main и будет выполнена та инструкция, которая приведёт к access violation. В этом случае максимум, что мы можем сделать штатными средствами – попытаться сохранить состояние программы и вывести сообщение о сбое.

Вот ещё пример обработки сигнала: программа работает бесконечно долго, пока не получит сигнал SIGINT

```
#include <signal.h>
#include <conio.h>
#include <stdio.h>

static wait = 1;

void listener(int sig) {
	//очищаем буфер
	while (getchar() != '\n');
	printf("listener: stop");
	wait = 0;
	_getch();
}

void main() {
	signal(SIGINT, listener);

	do {
		//...
	} while (wait);

	_getch();
}
```

Теперь программа будет работать до тех пор, пока не будет нажато сочетание Ctrl+C. Тем не менее, можно игнорировать этот сигнал:

```
#include <signal.h>
#include <conio.h>
#include <stdio.h>

void main() {
	signal(SIGINT, SIG_IGN);

	do {
		printf("*");
	} while (1);

	_getch();
}
```

Этот процесс всегда можно остановить сочетанием Ctrl+Break (SIGSTOP) или просто убить.

