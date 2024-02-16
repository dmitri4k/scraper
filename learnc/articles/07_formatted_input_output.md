# Форматированный вывод

Сегодня мы рассмотрим две важные функции форматированного ввода и вывода. Устройство и работу этих функций полностью можно понять только после 
изучения работы с указателями и функций с переменным числом параметров. Но пользоваться этими функциями необходимо уже сейчас, так что некоторые моменты 
придётся пропустить.

Функция форматированного вывода printf получает в качестве аргументов строку формат и аргументы, которые необходимо вывести в соответствии с форматом, и возвращает число 
выведенных символов. В случае ошибки возвращает отрицательное значение и устанавливает значение ferror. Если произошло несколько ошибок, errno равно EILSEQ.
int printf (const char * format, ...);

```
#include <stdio.h>
#include <conio.h>

void main() {
	//функция не получает никаких аргументов, кроме строки
	printf("Hello world");
	getch();
}
```

Функция проходит по строке и заменяет первое вхождение %<спецификатор формата> на первый аргумент, второе вхождение %<спецификатор формата> на второй 
аргумент и т.д. Далее мы будем просто рассматривать список флагов и примеры использования.

Общий синтаксис спецификатора формата
%[флаги][ширина][.точность][длина]спецификатор
Спецификатор – это самый важный компонент. Он определяет тип переменной и способ её вывода.

Примеры

```
#include <stdio.h>
#include <conio.h>

void main() {
	int a = 0x77, b = -20;
	char c = 'F';
	float f = 12.2341524;
	double d = 2e8;
	char* string = "Hello, World!";

	printf("%s\n", string);
	printf("a = %d, b = %d\n", a, b);
	printf("a = %u, b = %u\n", a, b);
	printf("a = %x, b = %X\n", a, b);
	printf("dec a = %d, oct a = %o, hex a = %x\n", a, a, a);
	printf("floating point f = %f, exp f = %e\n", f, f);
	printf("double d = %f or %E\n", d, d);
	printf("not all compiler support %a\n", f);
	printf("character c = %c, as number c = %d", c, c);
	printf("address of string is %p", string);
	getch();
}
```

Строка формата также может включать в себя следующие необязательные суб-спецификаторы: флаг, ширина, .точность и модификатор (именно в таком порядке).

Примеры

```
#include <stdio.h>
#include <conio.h>

void main() {
	int a = 0x77, b = -20;
	char c = 'F';
	float f = 12.2341524;
	double d = 2e2;
	char* string = "Hello, World!";

	printf("%.3f\n", f);
	printf("%.*f\n", 2, f);
	printf("%010.3f\n", d);
	printf("%*d\n", 6, a);
	printf("%+d\n", b);
	printf("%0.6d\n", a);
	printf("%.f\n", d);
	printf("%.4s", string);
	getch();
}
```

Суб-спецификатор длины изменяет длину типа. В случае, если длина не совпадает с типом, по возможности происходит  преобразование до нужного типа.

Примеры

```
#include <stdio.h>
#include <conio.h>

void main() {
	long long x = 12300000000579099123;
	short i = 10;
	printf("%llu\n", x);
	printf("%d\n", i);
	printf("%hd\n", i);
	getch();
}
```

## Форматированный ввод

Рассмотрим форматированный ввод функцией scanf.
int scanf(const char*, ...)
Функция принимает строку формата ввода (она похожа на строку формата printf) и адреса, по которым необходимо записать считанные данные. Возвращает
количество успешно проинициализированных аргументов.
Формат спецификатора ввода
%[*][ширина][длинна]спецификатор

Как и в printf, ширина, заданная символом * ожидает аргумента, который будт задавать ширину. Флаг длина совпадает с таким флагом функции printf.

Примеры

```
#include <stdio.h>
#include <conio.h>

void main() {
	int year, month, day;
	char buffer[128];
	int count;
	//Требует форматированного ввода, например 2013:12:12
	printf("Enter data like x:x:x = ");
	scanf("%d:%d:%d", &year, &month, &day);
	printf("year = %d\nmonth = %d, day = %d\n", year, month, day);
	//Считываем строку, не более 127 символов. При считывании в массив писать & не надо,
	//так как массив подменяется указателем
	printf("Enter string = ");
	scanf("%127s", buffer);
	printf("%s", buffer);
	getch();
}
```

Кроме функций scanf и printf есть ещё ряд функций, которые позволяют получать вводимые данные

```
#include <stdio.h>
#include <conio.h>

void main() {
	char c = 0;
	do {
		c = getch();
		printf("%c", c);
	} while (c != 'q');
}
```

char * fgets ( char * str, int num, FILE * stream ) - функция позволяет считывать строку с пробельными символами.
Несмотря на то, что она работает с файлом, можно с её помощью считывать и из стандартного потока ввода. Её преимущество относительно gets в
том, что она позволяет указать максимальный размер считываемой строки и заканчивает строку терминальным символом.

```
#include <stdio.h>
#include <conio.h>
#include <stdlib.h>

void main() {
	char buffer[128];
	//Считываем из стандартного потока ввода
	fgets(buffer, 127, stdin);
	printf("%s", buffer);
	//Этим можно заменить ожидание ввода символа
	scanf("1");
}
```

Это не полный набор различных функций символьного ввода и вывода. 
Таких функций море, но очень многие из них небезопасны, поэтому перед использованием внимательно читайте документацию.

## Непечатные символы

В си определён ряд символов, которые не выводятся на печать, но позволяют производить форматирование вывода. Эти символы
можно задавать в виде численных значений, либо в виде эскейп-последовательностей: символа, экранированного обратным слешем.

```
#include <stdio.h>
#include <conio.h>

void main() {
	char backspace = 0x08;
	//Выводим с использованием символа переноса строки
	printf("Hello\nWorld\n");
	//Выводим символ переноса строки через его значение
	printf("Hello%cWorld\n", 0x0a);
	//"Выводим" сигнал
	printf("\a");
	//Выводим сигнал, как символ
	printf("%c", '\a');
	//Выводим сигнал через шестнадцатеричное значение
	printf("%c", 0x07);
	printf("This is sparta!!!\b\b%c", backspace);
	printf("   ");
	getch();
}
```
