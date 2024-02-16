# Оператор присваивания

Когда мы работаем с переменными, необходимо изменять их значение. Это делается с помощью оператора присваивания =

```
#include<conio.h>
#include<stdio.h>

int main() {
	signed long long a, b, c;
	a = 1234567890123456789LL;
	b = -1234567890123456789LL;
	c = 123;

	printf("%lld\n", a);
	printf("%lld\n", b);
	printf("%lld\n", c);
	getch();
}
```

Оператор присваивания имеет особенность - он возвращает правое значение. Это значит, что можно использовать несколько операторов присваивания подряд, по цепочке.

```
#include<conio.h>
#include<stdio.h>

int main() {
	unsigned a, b, c;
	a = b = c = 10;
	printf("%u = %u = %u = 10", a, b, c);
	getch();
}
```

В этом примере переменной c присваивается значение 10, после чего оператор присваивания возвращает значение 10, которое используется следующим оператором, и присваивает значение 10 переменной b, после чего возвращает значение 10, которое используется следующим оператором.

Это свойство - возвращать значение - часто используется. Например, при выделении памяти мы можем узнать, была ли действительно выделена память.

```
#include<conio.h>
#include<stdio.h>
#include<stdlib.h>

int main() {
	int *a = NULL;

	printf("Try to allocate memory\n");
	if (a = (int*)malloc(1024*1024*1024 * sizeof(int))) {
		printf("Memory was allocated");
	} else {
		printf("Error: can't allocate memory");
	}
	getch();
	free(a);
}
```

Здесь одновременно выделяется память и проверяется, что было возвращено при попытке получить память. Этот же пример может быть записан и так

```
a = (int*)malloc(1024*1024*1024 * sizeof(int));
if (a) {
	printf("Memory was allocated");
} else {
	printf("Error: can't allocate memory");
}
```

(вам этот пример кажется непонятным, здесь важно для вас только использование оператора =).

## rvalue и lvalue

Любая переменная связана с адресом в памяти и хранит некоторое значение. Выражение типа

```
int i;
i = 20;
```

говорит о том, что мы заносим в область памяти, на которую указывает переменная i значение 20. Выражение

20 += 3;
не имеет смысла, поскольку 20 - это литерал, значение, которое не связано с областью памяти.

Для обозначения объектов, которым может быть присвоено значение, используется понятие lvalue (буквально, то, что может стоять слева от оператора присваивания). Для обозначения объектов, которые имеют только значения, используют выражение rvalue (то, что стоит справа от оператора присваивания).

lvalues в свою очередь делят на modifiable lvalues, которые могут быть изменены, и non-modifiable lvalues, которые связаны с областью памяти, но не могут быть изменены, например, константы.

В том случае, если lvalue стоит справа от оператора присваивания, например

```
int i, j;
j = 20;
i = j;
```

то происходит lvalue-to-rvalue convertion, преобразование lvalue к rvalue.

К rvalue относятся результаты арифметических выражений, преобразование не к ссылочным типам, результат постфиксных операций ++ и --, литералы за исключением строк.

К lvalue относятся переменные, выражения ссылочных типов, результат операции разыменования *, строковые литералы, результат префиксных операций ++ и -- над ссылочными типами.

Имена функций и массивов, также объявленные как немодифицируемые объекты, являются non-modifiable lvalues.
