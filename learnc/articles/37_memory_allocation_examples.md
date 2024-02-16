# Дополнительные примеры работы с памятью и указателями
## 1. Выделение памяти с явным сохранением размера области.

Когда мы работаем с массивом, то необходимо хранить его размер. Для этого нужно постоянно носить с собой переменную, 
которую нужно передавать в функции или возвращать из функции. Способ реализации функции malloc не определён в документации языка, известно только, что в большинстве 
случаев выделенный участок памяти начинается с метаданных, которые хранят размер области. В различных компиляторах реализованы свои функции, которые могут разбирать 
метаданные и возвращать размер области памяти.

Реализуем функцию  malloc, которая будет явно сохранять размер участка памяти и не будет зависеть от реализации компилятора. Для этого, в начале массива будет сохранять его 
размер в структуре _METADATA_.

```
typedef struct _METADATA_ {
	size_t size;
} _METADATA_;
```

Структура содержит всего одно поле – размер size типа size_t. В будущем, если понадобится, без труда можно будет добавить новые поля.
Теперь – функция my_malloc. Она получает размер участка памяти и возвращает указатель на выделенный участок.

1. Выделяем память. Её должно быть на sizeof(_METADATA_) байт больше, чтобы разместить заголовок.

```
void* ptr = malloc(size + sizeof(_METADATA_));
```

2. Если произошла ошибка и malloc вернула нулевой указатель, то выходим из функции

```
if (NULL == ptr) {
	return NULL;
}
```

3. Теперь выделенную область кастуем до структуры _METADATA_ и записываем туда размер

```
((_METADATA_*) ptr)->size = size;
```

4. Возвращаем указатель со сдвигом на sizeof(_METADATA_), таким образом, он будет иметь размер size

```
return (char*) ptr + sizeof(_METADATA_);
```

(char*) нужно для того, чтобы прибавить к указателю неопределённого типа число байт, равное размеру _METADATA_.

```
void* my_malloc(size_t size) {
	void* ptr = malloc(size + sizeof(_METADATA_));
	if (NULL == ptr) {
		return NULL;
	}
	((_METADATA_*) ptr)->size = size;
	return (char*) ptr + sizeof(_METADATA_);
}
```

Функция my_free должна освобождать участок памяти, выделенный функцией my_malloc. Для этого необходимо сдвинуть указатель на размер структуры с метаданными.

```
void my_free(void* ptr) {
	free((char*) ptr - sizeof(_METADATA_));
}
```

Функция get_size принимает указатель, полученный от функции my_malloc и читает размер массива из заголовка. Для этого сдвигаемся к началу области, кастуем её до _METADATA_ и обращаемся к полю size

```
size_t get_size(void* ptr) {
	return ((_METADATA_*)((char*) ptr - sizeof(_METADATA_)))->size;
}
```

Функция realloc похожа на malloc. Выделяем память под новый массив размера большего на sizeof(_METADATA_). Заносим в заголовок новый размер.

```
void* my_realloc(void* xptr, size_t new_size) {
	void* ptr = realloc((char*) xptr - sizeof(_METADATA_), new_size);
	if (ptr == NULL) {
		return NULL;
	}
	((_METADATA_*) ptr)->size = new_size;
	return (char*) ptr + sizeof(_METADATA_);
}
```

Проблемы возникают с функцией calloc. Так как она принимает размер массива и размер его элементов, то размер нашего заголовка может быть не кратен размеру элемента. Будет выделять память функцией malloc, а затем функцией memset заполнять выделенную область нулями.

```
void* my_calloc(size_t size, size_t num) {
	size_t real_size = (size * num) + sizeof(_METADATA_);
	void* ptr = malloc(real_size);
	memset((char*)ptr + sizeof(_METADATA_), 0, size*num);
	((_METADATA_*) ptr)->size = size;
	return (char*)ptr + sizeof(_METADATA_);
}
```

Теперь прикроем стандартные функции макросами

```
#define malloc my_malloc
#define free my_free
#define realloc my_realloc
#define calloc my_calloc
```

Соберём всё вместе с примерами

```
#include <stdio.h>
#include <conio.h>
#include <stdlib.h>
#include <string.h>

typedef struct _METADATA_ {
	size_t size;
} _METADATA_;

void* my_malloc(size_t size) {
	void* ptr = malloc(size + sizeof(_METADATA_));
	if (NULL == ptr) {
		return NULL;
	}
	((_METADATA_*) ptr)->size = size;
	return (char*) ptr + sizeof(_METADATA_);
}

void* my_calloc(size_t size, size_t num) {
	size_t real_size = (size * num) + sizeof(_METADATA_);
	void* ptr = malloc(real_size);
	memset((char*)ptr + sizeof(_METADATA_), 0, size*num);
	((_METADATA_*) ptr)->size = size;
	return (char*)ptr + sizeof(_METADATA_);
}

size_t get_size(void* ptr) {
	return ((_METADATA_*)((char*) ptr - sizeof(_METADATA_)))->size;
}

void* my_realloc(void* xptr, size_t new_size) {
	void* ptr = realloc((char*) xptr - sizeof(_METADATA_), new_size);
	if (ptr == NULL) {
		return NULL;
	}
	((_METADATA_*) ptr)->size = new_size;
	return (char*) ptr + sizeof(_METADATA_);
}

void my_free(void* ptr) {
	free((char*) ptr - sizeof(_METADATA_));
}

#define malloc my_malloc
#define free my_free
#define realloc my_realloc
#define calloc my_calloc

void printIntArray(int *a) {
	int size = get_size(a) / sizeof(int);
	int i;
	for (i = 0; i < size; i++) {
		printf("%d ", a[i]);
	} 
}

int** ones(int num) {
	int** a = (int**) malloc(num * sizeof(int*));
	int i;
	for (i = 0; i < num; i++) {
		a[i] = (int*) calloc(num, sizeof(int));
		a[i][i] = 1;
	}
	return a;
}

void main() {
	int* a = (int*) malloc(10*sizeof(int));
	int** one = NULL;
	int i, j;
	for (i = 0; i < 10; i++) {
		a[i] = i*i;
	}
	printf("size of a = %d byte\n", get_size(a));
	printIntArray(a);
	free(a);
	getch();
	printf("\n");
	one = ones(10);
	for (i = 0; i < 10; i++) {
		for (j = 0; j < 10; j++) {
			printf("%d ", one[i][j]);
		}
		printf("\n");
	}
	for (i = 0; i < 10; i++) {
		free(one[i]);
	}
	free(one);
	getch();
}
```

## 2. Простой пул памяти.

Уже оговаривалось ранее, что частое выделение памяти под множество мелких объектов, а также изменение размера выделенной области памяти замедляет 
работу и приводит к фрагментации памяти. Создадим просто пул памяти – заранее зарезервированную область памяти, которую будем раздавать. Для простоты сделаем пул глобальной 
переменной.

```
void** mempool = NULL;
int *checkbox;
size_t msize;
```

Здесь mempool – это наш пул, двумерный массив. msize – число строк, соответствует числу блоков памяти, размер которых задаётся пользователем при создании, 
checkbox – массива флагов. Длина массива флагов msize. Если i-й флаг поднят, то i-й блок памяти выделен.

Как это работает:

```
#include <stdio.h>
#include <conio.h>
#include <stdlib.h>

void** mempool = NULL;
int *checkbox;
static size_t msize;

void prepare_pool(size_t items, size_t len) {
	size_t i;
	msize = items;
	checkbox = (int*) calloc(len, sizeof(int));
	mempool = (void**) malloc(msize*sizeof(void*));
	for (i = 0; i < msize; i++) {
		mempool[i] = malloc(len);
	}
}

void freemempool() {
	for (;msize != 0; msize--) {
		free(mempool[msize-1]);
	}
	free(mempool);
}

void* mylloc() {
	size_t i;
	for (i = 0; i < msize; i++) {
		if (!checkbox[i]) {
			checkbox[i] = 1;
			return mempool[i];
		}
	}

	return NULL;
}
void myfree(void *ptr) {
	size_t i;
	for (i = 0; i < msize; i++) {
		if (mempool[i] == ptr) {
			checkbox[i] = 0;
			break;
		}
	}
}

void main () {
	int i;
	char *a, *b, *c;
	
	for (i = 0; i < 1000000; i++) {
		a = (char*) malloc(100);
		b = (char*) malloc(100);
		c = (char*) malloc(100);
		free(a);
		free(b);
		free(c);
	}
	/*раскомментируйте и закомментируйте старый цикл
	prepare_pool(10, 1000);
	for (i = 0; i < 1000000; i++) {
		a = (char*) mylloc();
		b = (char*) mylloc();
		c = (char*) mylloc();
		myfree(a);
		myfree(b);
		myfree(c);
	}
	freemempool();
	*/
}
```

