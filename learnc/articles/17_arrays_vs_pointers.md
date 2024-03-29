# Указатели и массивы

Пусть есть массив
int A[5] = {1, 2, 3, 4, 5};
Мы уже показали, что указатели очень похожи на массивы. В частности, массив хранит адрес, откуда начинаются его элементы. Используя указатель можно также получить доступ до 
элементов массива
int *p = A;

тогда вызов A[3] эквивалентен вызову *(p + 3)

На самом деле оператор  [ ] является синтаксическим сахаром – он выполняет точно такую же работу. То есть вызов
A[3] также эквивалентен вызову *(A + 3)

```
#include <conio.h>
#include <stdio.h>

void main() {
	int A[5] = {1, 2, 3, 4, 5};
	int *p = A;

	printf("%d\n", A[3]);
	printf("%d\n", *(A + 3));
	printf("%d\n", *(p + 3));

	getch();
}
```

Тем не менее, важно понимать – указатели - это не массивы!
Отличие массива от указателя
Массив - непосредственно указывает на первый элемент, указатель – переменная, которая хранит адрес первого элемента.

Тогда почему возможна следующая ситуация?

```
#include <conio.h>
#include <stdio.h>

void main() {
	int A[5] = {1, 2, 3, 4, 5};
	int *p = A;

	printf("%d\n", *(A+1));
	printf("%d\n", *(p+1));
	getch();
}
```

Это правильный код, который будет работать. Дело в том, что компилятор подменяет массив на указатель. Данный пример работает, потому что мы действительно работаем с 
указателем (хотя помним, что массив отличается от указателя). То же самое происходит и при вызове функции. Если функция требует указатель, 
то можно передавать в качестве аргумента массив, так как он будет подменён указателем.

В си существует одна занимательная особенность. Если A[i] это всего лишь синтаксический сахар, 
и A[i] == *(A + i), то от смены слагаемых местами
ничего не должно поменяться, т. е. A[i] == *(A + i) == *(i + A) == i[A]. Как бы странно это ни звучало,
но это действительно так. Следующий код вполне валиден:

```
int a[] = {1, 2, 3, 4, 5};
printf("%d\n", a[3]);
printf("%d\n", 3[a]);
```

## Многомерные массивы и указатели на многомерные массивы.

Теперь рассмотрим такой пример

```
void main() {
	int A[][3] = {1, 2, 3, 4, 5, 6, 7, 8, 9};
	int **p = A;
}
```

Этот код не скомпилируется. Дело в том, что правило подмены массива на указатель на рекурсивное. 
Поэтому при определении многомерного массива нужно указывать размер явно, а пустыми оставлять можно только первые скобки.
Этот пример можно переписать так

```
#include <conio.h>
#include <stdio.h>

void main() {
	int A[][3] = {1, 2, 3, 4, 5, 6, 7, 8, 9};
	int *p = A[0];

	printf("%d\n", p[2]);

	getch();
}
```

Мы получили указатель на первую строку. Далее вывели третий элемент.
Либо так - создать массив указателей на строки

```
#include <conio.h>
#include <stdio.h>

void main() {
	int A[][3] = {1, 2, 3, 4, 5, 6, 7, 8, 9};
	int (*p)[3] = A;

	printf("%d\n", p[0][2]);
	//Или так
	printf("%d\n", *(*( p + 0 ) + 2));

	getch();
}
```

Только здесь уже p будет именем массива, каждый элемент которого является указателем. И точно так же, как мы обращались к элементам массива через массив указателей *p[3], через имя массива можно обратиться к элементу массива

```
printf("%d\n", *(*( A + 1 ) + 2));
```

Тоже самое правило действует и при вызове функций. Если функция требует указателя на указатель, то нельзя просто передать двумерный массив, потому что он не будет подменён 
указателем на указатель, а будет заменён массивом указателей.

Подмена имени массива на указатель связана с тем, что структура одномерного массива в памяти идентична структуре динамически созданного массива -
это просто последовательность байт в памяти. Другое дело - двумерный массив.

Статический двумерный массив представляет собой одномерный массив, 
в котором элементы расположены друг за другом по рядам. Динамически созданный двумерный массив - это массив указателей. Каждый элемент этого массива хранит адрес динамически созданного массива.
Поэтому нельзя просто присвоить указателю на указатель имя статического двумерного массива - он не будет знать, 
как с ним работать.

Чтобы динамически созданный двумерный массив имел структуру статического двумерного массива, необходимо, чтобы он знал "число столбцов" двумерного массива, то
есть длину одной строки. Для этого можно воспользоваться указателем на одномерный массив. Неудобство такого подхода в том, что необходимо заранее знать 
число элементов каждого подмассива. Однако, многомерный массив всегда можно создать из одномерного, тогда вообще никаких проблем не обнаружится.

