# Перечисляемый тип

В си выделен отдельный тип перечисление (enum), задающий набор всех возможных целочисленных значений переменной этого типа. Синтаксис перечисления

```
enum <имя> {
	<имя поля 1>,
	<имя поля 2>,
	...
	<имя поля N>
};	//здесь стоит ;!
```

Например

```
#include <conio.h>
#include <stdio.h>

enum Gender {
	MALE,
	FEMALE
};

void main() {
	enum Gender a, b;
	a = MALE;
	b = FEMALE;
	printf("a = %d\n", a);
	printf("b = %d\n", b);
	getch();
}
```

В этой программе объявлено перечисление с именем Gender. Переменная типа enum Gender может принимать теперь только два значения – это MALE И FEMALE.

По умолчанию, первое поле структуры принимает численное значение 0, следующее 1, следующее 2 и т.д. Можно задать нулевое значение явно:

```
#include <conio.h>
#include <stdio.h>

enum Token {
	SYMBOL,			//0
	NUMBER,			//1
	EXPRESSION = 0,	//0
	OPERATOR,		//1
	UNDEFINED		//2
};

void main() {
	enum Token a, b, c, d, e;
	a = SYMBOL;
	b = NUMBER;
	c = EXPRESSION;
	d = OPERATOR;
	e = UNDEFINED;
	printf("a = %d\n", a);
	printf("b = %d\n", b);
	printf("c = %d\n", c);
	printf("d = %d\n", d);
	printf("e = %d\n", e);
	getch();
}
```

Будут выведены значения 0 1 0 1 2. То есть, значение SYMBOL равно значению EXPRESSION, а NUMBER равно OPERATOR.
Если мы изменим программу и напишем

```
enum Token {
	SYMBOL,				//0
	NUMBER,				//1
	EXPRESSION = 10,	//10
	OPERATOR,			//11
	UNDEFINED			//12
};
```

То SYMBOL будет равно значению 0, NUMBER равно 1, EXPRESSION равно 10, OPERATOR равно 11, UNDEFINED равно 12.

Принято писать имена полей перечисления, как и константы, заглавными буквами. Так как поля перечисления целого типа, то они могут быть использованы в операторе switch.

Заметьте, что мы не можем присвоить переменной типа Token просто численное значение. Переменная является сущностью типа Token и принимает только значения полей перечисления. Тем не менее, переменной числу можно присвоить значение поля перечисления.

Обычно перечисления используются в качестве набора именованных констант. Часто поступают следующим образом - создают массив строк, ассоциированных с полями перечисления. Например

```
#include <conio.h>
#include <stdio.h>
#include <stdlib.h>

static char *ErrorNames[] = {
	"Index Out Of Bounds",
	"Stack Overflow",
	"Stack Underflow",
	"Out of Memory"
};

enum Errors {
	INDEX_OUT_OF_BOUNDS = 1,
	STACK_OVERFLOW,
	STACK_UNDERFLOW,
	OUT_OF_MEMORY
};

void main() {
	//ошибка случилась
	printf(ErrorNames[INDEX_OUT_OF_BOUNDS-1]);
	exit(INDEX_OUT_OF_BOUNDS);
}
```

Так как поля принимают численные значения, то они могут использоваться в качестве индекса массива строк. Команда exit(N) должна получать код ошибки,
отличный от нуля, потому что 0 - это плановое завершение без ошибки. Именно поэтому первое поле перечисления равно единице.

Перечисления используются для большей типобезопасности и ограничения возможных значений переменной. Для того, чтобы не писать enum каждый раз, можно объявить новый тип. Делается это также, как и в случае структур.

```
typedef enum enumName {
	FIELD1,
	FIELD2
} Name;
```

Например

```
typedef enum Bool {
	FALSE,
	TRUE
} Bool;
```

