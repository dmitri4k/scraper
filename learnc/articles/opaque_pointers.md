# Реализация инкапсуляции с помощью непрозрачных указателей
## Opaque pointers и инкапсуляция в си.

Приведённый ниже материал не относится к основному курсу, но позволяет полнее понять особенности языка си и упростить решение некоторых прикладных задач. 
Если вы не смогли совладать с основным курсом, остановитесь здесь и не читайте дальше.

Инкапсуляция –  механизм, позволяющий скрыть свойства объекта от свободного изменения. Когда мы определяем структуру в си, поля структуры доступны всем через операцию точка или стрелка.
Очень часто существует необходимость защитить поля от доступа. Например, у нас есть структура, которая хранит имя, фамилию, идентификационный номер, пол и возраст человека.

```
typedef enum GENDER {
	MALE,
	FEMALE,
	UNKNOWN
} GENDER;

struct person {
	unsigned long long id;
	char* firstName;
	char *lastName;
	unsigned char age;
	GENDER gender;
};
```

Любая функция может беспрепятственно изменить поля структуры, причём задать значения, которые противоречат здравому смыслу. Конечно, всегда можно проверять данные при вводе, но, рано или поздно, вы либо забудете это сделать, либо ленивый программист не сделает проверку значений и получит ошибку.
Также часто нужно хранить скрытые параметры, которые нельзя изменять извне. Например, структура массив может иметь переменную размер, которая отвечает за текущее количество объектов в массиве. Изменяться она должна только тогда, когда добавляются новые элементы. Извне эта переменная может быть только считана, но её нельзя менять.
Стандартная структура не позволяет инкапсулировать данные. Однако особенность процесса компиляции помогает добиться нужных для нас свойств.

Создадим два файла: Box.h и Box.c В файле Box.h опишем структуру без полей и новый тип.

```
#ifndef _BOX_H_
#define _BOX_H_

struct Box_;

typedef struct Box_ Box;

#endif
```

Структура Box_ не содержит полей. Поэтому при компиляции, когда мы подключим файл Box.h к нашему проекту, к полям структуры обратиться будет нельзя. В файле Box.c доопределим эту структуру:

```
#include "Box.h"

struct Box_ {
	unsigned depth;
	unsigned height;
	unsigned width;
};
```

Поля структуры Box_ теперь видны только в файле Box.c. Функции, описанные в Box.c будут видеть поля структуры и иметь доступ до них, в остальных файлах доступа до полей не будет. Так как функции определены по умолчанию как extern (если, конечно, они не определены явно как static), все функции будут доступны извне.
Таким образом, доступ до всех полей будет осуществляться через функции, которые уже будут проверять корректность введённых данных. Также функции смогут обращаться к тем полям, доступа до которых вообще не должно быть.

Содержимое Box.h теперь

```
#ifndef _BOX_H_
#define _BOX_H_

#define MAX_HEIGHT 10000
#define MAX_WIDTH  10000
#define MAX_DEPTH  10000

struct Box_;

typedef struct Box_ Box;

Box* createBox(unsigned, unsigned, unsigned);

void setHeight(Box*, unsigned);
void setDepth(Box*, unsigned);
void setWidth(Box*, unsigned);
unsigned getHeight(Box*);
unsigned getWidth(Box*);
unsigned getDepth(Box*);
unsigned getVolume(Box*);

#endif
```

Содержимое Box.c

```
#include "Box.h"

struct Box_ {
	unsigned depth;
	unsigned height;
	unsigned width;
};

void setHeight(Box* this_, unsigned height) {
	this_->height = height;
}
void setWidth(Box* this_, unsigned width) {
	this_->width = width;
}
void setDepth(Box* this_, unsigned depth) {
	this_->depth = depth;
}
unsigned getHeight(Box* this_) {
	return this_->height;
}
unsigned getWidth(Box* this_) {
	return this_->width;
}
unsigned getDepth(Box* this_) {
	return this_->depth;
}
unsigned getVolume(Box* this_) {
	return this_->depth * this_->height * this_->width;
}
```

Один момент – мы не проверяем правильность данных в функциях setHeight, setWidth  и setDepth. Функции проверки, между тем, должны быть, но они не должны быть видны вне нашего 
файла. То есть, функции должны быть также защищены, как и поля структуры, только не от изменения, а от использования. Это делается стандартным способом – определим новые 
функции как static:

В Box.h

```
static int checkDepth(unsigned);
static int checkHeight(unsigned);
static int checkWidth(unsigned);
```

В Box.c

```
int checkDepth(unsigned depth) {
	return (depth < MAX_DEPTH);
}
int checkHeight(unsigned height) {
	return (height < MAX_HEIGHT);
}
int checkWidth(unsigned width) {
	return (width < MAX_WIDTH);
}
```

Конечный результат работы
Box.h

```
#ifndef _BOX_H_
#define _BOX_H_

#include <stdlib.h>

#define MAX_HEIGHT 10000
#define MAX_WIDTH  10000
#define MAX_DEPTH  10000
#define BAD_DATA -5

struct Box_;

typedef struct Box_ Box;

Box* createBox(unsigned, unsigned, unsigned);

void setHeight(Box*, unsigned);
void setDepth(Box*, unsigned);
void setWidth(Box*, unsigned);
unsigned getHeight(Box*);
unsigned getWidth(Box*);
unsigned getDepth(Box*);
unsigned getVolume(Box*);

static int checkDepth(unsigned);
static int checkHeight(unsigned);
static int checkWidth(unsigned);

#endif
```

Box.c

```
#include "Box.h"

struct Box_ {
	unsigned depth;
	unsigned height;
	unsigned width;
};

void setHeight(Box* this_, unsigned height) {
	if (checkHeight(height)) {
		this_->height = height;
	} else {
		exit(BAD_DATA);
	}
}
void setWidth(Box* this_, unsigned width) {
	if (checkWidth(width)) {
		this_->width = width;
	} else {
		exit(BAD_DATA);
	}
}
void setDepth(Box* this_, unsigned depth) {
	if (checkDepth(depth)) {
		this_->depth = depth;
	} else {
		exit(BAD_DATA);
	}
}
unsigned getHeight(Box* this_) {
	return this_->height;
}
unsigned getWidth(Box* this_) {
	return this_->width;
}
unsigned getDepth(Box* this_) {
	return this_->depth;
}
unsigned getVolume(Box* this_) {
	return this_->depth * this_->height * this_->width;
}
int checkDepth(unsigned depth) {
	return (depth < MAX_DEPTH);
}
int checkHeight(unsigned height) {
	return (height < MAX_HEIGHT);
}
int checkWidth(unsigned width) {
	return (width < MAX_WIDTH);
}
```

main.c

```
#include <conio.h>
#include <stdio.h>
#include "Box.h"

void main() {
	Box *box = createBox(10, 20, 35);
	//Нельзя получить доступ напрямую box->width
	printf("volume = %d\n", getVolume(box));
	setWidth(box, 22);
	printf("volume = %d\n", getVolume(box));
	free(box);
	_getch();
}
```

Этот трюк довольно часто используется при попытках создать ООП-подобные интерфейсы в си.

