# Реализация пространства имён в си с помощью структур

Приведённый ниже материал не относится к основному курсу, но позволяет полнее понять особенности языка си и упростить решение некоторых прикладных задач. 
Если вы не смогли совладать с основным курсом, остановитесь здесь и не читайте дальше.

Одной из больших проблем си является отсутствие пространств имён или системы модулей. Если есть две библиотеки, в которых функции имеют одинаковые имена, то произойдёт коллизия: нельзя будет понять, какая из функций будет использована. Компоновщик выдаст ошибку, что функция определена более одного раза.

В нашем проекте есть два подключаемых файла
File1.h

```
#pragma once

int doSomething(int, int);
```

и соответствующий ему .с файл File1.c

```
#include "File1.h"

int doSomething(int a, int b) {
	return a + b;
}
```

И файл File2.h

```
#pragma once

int doSomething();
```

и соответствующий ему файл File2.c

```
#include "File2.h"

int doSomething(int a, int b) {
	return a * b;
}
```

Если мы попытаемся подключить оба заголовочных файла, то получим ошибку: обнаружен многократно определенный символ - один или более.

```
#include <conio.h>
#include <stdio.h>
#include "File1.h"
#include "File2.h"

void main() {

}
```

Избавиться от неё можно (возможно, ещё есть другие способы...) объявив функции doSomething статическими.

```
#pragma once

static int doSomething(int, int);
```

Теперь проект скомпилируется, только вот использовать эти функции в main не удастся. Для того, чтобы использовать их, создадим структуру

```
#pragma once
#include <stdlib.h>

typedef struct FILE1 {
	int (*doSomething) (int, int);
} FILE1;

static int doSomething(int a, int b);
FILE1* getFile1Namespace(void);
```

для файла File2.h

```
#pragma once
#include <stdlib.h>

typedef struct FILE2 {
	int (*doSomething) (int, int);
} FILE2;

static int doSomething(int a, int b);
FILE2* getFile2Namespace(void);
```

Функции getFile?Namespace возвращают структуру, у которой поле - указатель на функцию - равно нашей статической функции.

```
#include "File1.h"

int doSomething(int a, int b) {
	return a + b;
}

FILE1* getFile1Namespace() {
	FILE1 *tmp = (FILE1*) malloc(sizeof(FILE1));
	tmp->doSomething = doSomething;

	return tmp;
}
```

File2.c

```
#include "File2.h"

int doSomething(int a, int b) {
	return a * b;
}

FILE2* getFile2Namespace() {
	FILE2 *tmp = (FILE2*) malloc(sizeof(FILE2));
	tmp->doSomething = doSomething;

	return tmp;
}
```

Теперь в main можно создать экземпляр структуры FILE1 или FILE2 и через поле структуры обратиться к статической функции.

```
#include <conio.h>
#include <stdio.h>
#include "File1.h"
#include "File2.h"

void main() {
	int a, b;
	FILE1 *ns1 = getFile1Namespace();
	FILE2 *ns2 = getFile2Namespace();
	a = 10;
	b = 20;

	printf("using namespace 1 = %d\n", ns1->doSomething(a, b));
	printf("using namespace 2 = %d\n", ns2->doSomething(a, b));

	free(ns1);
	free(ns2);
	_getch();
}
```

