# Строки, строковые литералы и указатели на строки

Как показала практика, почти все студенты делают одни и те же ошибки, связанные с работой со 
строками, строковыми литералами и указателями на строки. Проясним  ситуацию.

Рассмотрим код

```
char *str = "String Literal";
printf("%s", str);
```

В данном случае str – это указатель, а "String Literal" – это строковый литерал. Особенность в том, что 
строковый литерал хранится в Read Only области памяти. Ничего не происходит, когда мы просто читаем значение. Однако указатель не объявлен 
как const, а это значит, что компилятор позволит изменить значение, на которое ссылается указатель:

```
char *str = "String Literal";
str[0] = 's';
```

Этот код упадёт с ошибкой, так как у нас нет прав на модификацию объекта. Для предотвращения такой ситуации нужно обязательно указывать, 
что это немодифицируемый объект

```
const char *str = "String Literal";
```

Тогда неправильный код не скомпилируется. Теперь второй случай

```
char str[] = "String Literal";
printf("%s", str);
```

В данном случае str это модифицируемый объект – массив типа char. "String Literal" - всё также строковый литерал, но в данном случае он 
копируется в массив. str не просто ссылается на read-only область памяти, он содержит копию строки.

```
char str[] = "String Literal";
str[0] = 's';
printf("%s", str);
```

Можно было бы написать и так

```
char str[] = {"String Literal"};
```

Для простоты, например, можно определить такую функцию, которая выделяет память и копирует туда строковый литерал

```
#include <conio.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>

char* copy_and_init(const char *src) {
	int length;
	char *out;

	assert(src != NULL);

	length = strlen(src) + 1;
	out = (char*) malloc(length);
	if (out == NULL) {
		return NULL;
	}
	memcpy(out, src, length);
	return out;
}

void main() {
	const char *example = "Hello, world!";
	char *mod = copy_and_init(example);
	mod[7] = 'W';
	printf("%s", mod);
	free(mod);
	_getch();
}
```

Единственная проблема – не забыть очистить память.
