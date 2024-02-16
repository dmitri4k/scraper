# Переполнение целых чисел

Вы уже знаете, что при сложении целых может происходить переполнение. Загвоздка в том, что компьютер не выдаёт предупреждения при переполнении: 
программа продолжит работать с неверными данными. Более того, поведение при переполнении определено только для целых без знака.

Переполнение может привести к серьёзным проблемам: обнулению и потере данных, возможным эксплойтам, трудноуловимым ошибкам, которые будут накапливаться с течением времени.

Рассмотрим несколько приёмов отслеживания переполнения целых со знаком и переполнения целых без знака.

1. Предварительная проверка данных. Мы знаем, из файла limits.h, максимальное и минимальное значение для чисел типа int. Если оба числа положительные, 
то их сумма не превысит INT_MAX, если разность INT_MAX и одного из чисел меньше второго числа. Если оба числа отрицательные, то разность INT_MIN и 
одного из чисел должна быть больше другого. Если же оба числа имеют разные знаки, то однозначно их сумма не превысит INT_MAX или INT_MIN.

```
int sum1(int a, int b, int *overflow) {
	int c = 0;
	if (a > 0 && b > 0 && (INT_MAX - b < a) || 
		a < 0 && b < 0 && (INT_MIN - b > a)) {
		*overflow = 1;
	} else {
		*overflow = 0;
		c = a + b;
	}
	return c;
}
```

В этой функции переменной overflow будет присвоено значение 1, если было переполнение. Функция возвращает сумму, независимо от результата сложения.

2. Второй способ проверки – взять для суммы тип, максимальное (и минимальное) значение которого заведомо больше суммы двух целых. После сложения необходимо проверить, чтобы сумма была не больше , чем INT_MAX и не меньше INT_MIN.

```
int sum2(int a, int b, int *overflow) {
	signed long long c = (signed long long) a + (signed long long) b;
	if (c < INT_MAX && c > INT_MIN) {
		*overflow = 0;
		c = a + b;
	} else {
		*overflow = 1;
	}
	return (int) c;
}
```

Обратите внимание на явное приведение типов. Без него сначала произойдёт переполнение, и неправильное число будет записано в переменную c.

3. Третий способ проверки платформозависимый, более того, его реализация будет разной для разных компиляторов. При переполнении целых (обычно) поднимается флаг переполнения в регистре флагов. Можно на ассемблере проверить значение флага сразу же после выполнения суммирования.

```
int sum3(int a, int b, int *overflow) {
	int noOverflow = 1;
	int c = a + b;
	__asm {
		jno NO_OVERFLOW
		mov noOverflow, 0
	NO_OVERFLOW:
	}
	if (noOverflow) {
		*overflow = 0;
	} else {
		*overflow = 1;
	}
	return c;
}
```

Здесь переменная noOverflow равна 1, если нет переполнения. jno (jump if no overflow) выполняет переход к метке NO_OVERFLOW, если переполнения не было. 
Если же переполнение было, то выполняется

```
mov noOverflow, 0
```

Работа с числами без знака гораздо проще: при переполнении происходит обнуление и известно, что получившееся число заведомо будет меньше каждого из слагаемых.

```
unsigned usumm(unsigned a, unsigned b, int *overflow) {
	unsigned c = a + b;
	if (c < a || c < b) {
		*overflow = 1;
	} else {
		*overflow = 0;
	}
	return c;
}
```

Вот полный код, с проверками.

```
#include <conio.h>
#include <stdio.h>
#include <limits.h>

int sum1(int a, int b, int *overflow) {
	int c = 0;
	if (a > 0 && b > 0 && (INT_MAX - b < a) || 
		a < 0 && b < 0 && (INT_MIN - b > a)) {
		*overflow = 1;
	} else {
		*overflow = 0;
		c = a + b;
	}
	return c;
}

int sum2(int a, int b, int *overflow) {
	signed long long c = (signed long long) a + (signed long long) b;
	if (c < INT_MAX && c > INT_MIN) {
		*overflow = 0;
		c = a + b;
	} else {
		*overflow = 1;
	}
	return (int) c;
}

int sum3(int a, int b, int *overflow) {
	int noOverflow = 1;
	int c = a + b;
	__asm {
		jno NO_OVERFLOW
		mov noOverflow, 0
	NO_OVERFLOW:
	}
	if (noOverflow) {
		*overflow = 0;
	} else {
		*overflow = 1;
	}
	return c;
}

unsigned usumm(unsigned a, unsigned b, int *overflow) {
	unsigned c = a + b;
	if (c < a || c < b) {
		*overflow = 1;
	} else {
		*overflow = 0;
	}
	return c;
}

void main() {
	int overflow;
	int sum;
	unsigned usum;
	//sum1
	sum = sum1(3, 5, &overflow);
	printf("%d + %d = %d (%d)\n", 3, 5, sum, overflow);
	sum = sum1(INT_MAX, 5, &overflow);
	printf("%d + %d = %d (%d)\n", INT_MAX, 5, sum, overflow);
	sum = sum1(INT_MIN, -5, &overflow);
	printf("%d + %d = %d (%d)\n", INT_MIN, -5, sum, overflow);
	sum = sum1(INT_MAX, INT_MIN, &overflow);
	printf("%d + %d = %d (%d)\n", INT_MAX, INT_MIN, sum, overflow);
	sum = sum1(-10, -20, &overflow);
	printf("%d + %d = %d (%d)\n", -10, -20, sum, overflow);
	//sum2
	sum = sum2(3, 5, &overflow);
	printf("%d + %d = %d (%d)\n", 3, 5, sum, overflow);
	sum = sum2(INT_MAX, 5, &overflow);
	printf("%d + %d = %d (%d)\n", INT_MAX, 5, sum, overflow);
	sum = sum2(INT_MIN, -5, &overflow);
	printf("%d + %d = %d (%d)\n", INT_MIN, -5, sum, overflow);
	sum = sum2(INT_MAX, INT_MIN, &overflow);
	printf("%d + %d = %d (%d)\n", INT_MAX, INT_MIN, sum, overflow);
	sum = sum2(-10, -20, &overflow);
	printf("%d + %d = %d (%d)\n", -10, -20, sum, overflow);
	//sum3
	sum = sum3(3, 5, &overflow);
	printf("%d + %d = %d (%d)\n", 3, 5, sum, overflow);
	sum = sum3(INT_MAX, 5, &overflow);
	printf("%d + %d = %d (%d)\n", INT_MAX, 5, sum, overflow);
	sum = sum3(INT_MIN, -5, &overflow);
	printf("%d + %d = %d (%d)\n", INT_MIN, -5, sum, overflow);
	sum = sum3(INT_MAX, INT_MIN, &overflow);
	printf("%d + %d = %d (%d)\n", INT_MAX, INT_MIN, sum, overflow);
	sum = sum3(-10, -20, &overflow);
	printf("%d + %d = %d (%d)\n", -10, -20, sum, overflow);
	//usum
	usum = usumm(10u, 20u, &overflow);
	printf("%u + %u = %u (%d)\n", 10u, 20u, usum, overflow);
	usum = usumm(UINT_MAX, 20u, &overflow);
	printf("%u + %u = %u (%d)\n", UINT_MAX, 20u, usum, overflow);
	usum = usumm(20u, UINT_MAX, &overflow);
	printf("%u + %u = %u (%d)\n", 20u, UINT_MAX, usum, overflow);
	getch();
}
```

