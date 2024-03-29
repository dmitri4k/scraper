# Целые типы фиксированного размера

Часто необходимо работать не просто с какими-то целыми, а с числами известной, фиксированной длины. Работа с целыми числами одного типа, но разной длины сильно усложняет написание переносимого кода и приводит к массе ошибок.
К счастью, в стандарте си предусмотрены типы с известными размерами.

Эти типы имеют гарантированный непрерывный размер, если объявлены. К сожалению, по стандарту они могут и не существовать. Также иногда встречаются и более крупные по размеру типы, например int128_t, но это уже экзотика.

Эти типы объявлены в заголовочном файле stdint.h.

Кроме этих типов, есть ещё несколько важный.

intmax_t и uintmaxt – знаковые и беззнаковые целочисленные типы с максимальной поддерживаемой длиной на данной платформе. Для вывода на печать (с помощью функции printf) используется модификатор j и ju.

Более того, имеется ещё несколько специфических типов.

uint_fast32_t – тип, который может вмещать 32 бита, но на данной платформе работает максимально эффективно (например, 8 байтный на x64 архитектуре).

Также объявлены типы

uint_least32_t – Тип с самым маленьким размером, который гарантированно может вместить 32 бита (например, если на данном компьютере целые 64 бита, а 32-битных нет).

Также объявлены типы

Также, вместе с этими типами объявлены константы с соответствующими именами, которые помогают оперировать с числами. Например минимальные значения

И максимальные

Для least и fast объявлены соответствующие значения INT_LEAST8_MAX и INT_FAST8_MAX и т.п.

Пример. Пусть платформа little endian (а другой вы и найдёте). Пользователь вводит целое число, не более 8 байт длиной.  Необходимо вывести, сколько в этом числе ненулевых байт.
Для начала, просто выведем побайтно целое. Для этого считаем его в 8 байтное целое

```
int64_t input;
scanf("%" SCNd64, &input);
```

SCNd64 – это макрос, определённый в библиотеке inttypes. Он используется для ввода целых 64 битных чисел. Напомню, что в си строковые литералы, записанные рядом, конкатенируются.

Далее, если у нас есть адрес переменной, то мы можем пройти по каждому байту этой переменной. Для этого приведём её к типу указатель на unsigned char (то есть один байт), а потом будем работать с этим указателем как с массивом.

```
for (i = 0; i < sizeof(input); i++) {
	byte = ((unsigned char*)(&input))[i];
	printf("%02X ", byte);
}
```

Вот весь код

```
#define _CRT_SECURE_NO_WARNINGS
#include <stdio.h>
#include <conio.h>
#include <inttypes.h>

int main(void) {
	int64_t input;
	uint8_t i;
	unsigned char byte;

	scanf("%" SCNd64, &input);

	for (i = 0; i < sizeof(input); i++) {
		byte = ((unsigned char*)(&input))[i];
		printf("%02X ", byte);
	}
	_getch();
}
```

Теперь уже совсем просто узнать, сколько ненулевых байт в числе

```
i = 0;
for (;;) {
if (!((unsigned char*)(&input))[i]) {
		break;
	}
	++i;
};
printf("%" PRId8 " non-zero bytes", i);
```

Этот цикл можно переписать множеством разных способов.

