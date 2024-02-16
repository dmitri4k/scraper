# Работа с текстовыми файлами

Работа с текстовым файлом похожа работу с консолью: с помощью функций форматированного ввода мы сохраняем данные в файл, с помощью функций форматированного вывода считываем данные из файла. Есть множество нюансов, которые мы позже рассмотрим.
Основные операции, которые необходимо проделать, это

Кроме того, существует ряд задач, когда нам не нужно обращаться к содержимому файла: переименование, перемещение, копирование и т.д. К сожалению, 
в стандарте си нет описания функций для этих нужд. Они, безусловно, имеются для каждой из реализаций компилятора. Считывание содержимого каталога 
(папки, директории) – это тоже обращение к файлу, потому что папка сама по себе является файлом с метаинформацией.

Иногда необходимо выполнять некоторые вспомогательные операции: переместиться в нужное место файла, запомнить текущее положение, определить длину файла и т.д.

Для работы с файлом необходим объект FILE. Этот объект хранит идентификатор файлового потока и информацию, которая нужна, чтобы им управлять, включая 
указатель на его буфер, индикатор позиции в файле и индикаторы состояния.

Объект FILE сам по себе является структурой, но к его полям не должно быть доступа. Переносимая программа должна работать с файлом как с абстрактным объектом, 
позволяющим получить доступ до файлового потока.

Создание и выделение памяти под объект типа FILE осуществляется  с помощью функции fopen или tmpfile (есть и другие, но мы остановимся только на этих).

Функция fopen открывает файл. Она получает два аргумента – строку с адресом файла и строку с режимом доступа к файлу. Имя файла может быть как абсолютным, так и относительным. 
fopen возвращает указатель на объект FILE, с помощью которого далее можно осуществлять доступ к файлу.

```
FILE* fopen(const char* filename, const char* mode);
```

Например, откроем файл и запишем в него Hello World

```
#include <stdio.h>
#include <conio.h>
#include <stdlib.h>

void main() {
	//С помощью переменной file будем осуществлять доступ к файлу
	FILE *file;
	//Открываем текстовый файл с правами на запись
	file = fopen("C:/c/test.txt", "w+t");
	//Пишем в файл
	fprintf(file, "Hello, World!");
	//Закрываем файл
	fclose(file);
	getch();
}
```

Функция fopen сама выделяет память под объект, очистка проводится функцией fclose. Закрывать файл обязательно, самостоятельно он не закроется.

Функция fopen может открывать файл в текстовом или бинарном режиме. По умолчанию используется текстовый. Режим доступа может быть следующим

Если необходимо открыть файл в бинарном режиме, то в конец строки добавляется буква b, например
“rb”, “wb”, “ab”, или, для смешанного режима “ab+”, “wb+”, “ab+”. Вместо b можно добавлять букву t, тогда файл будет открываться в текстовом режиме. Это зависит от реализации. В новом стандарте си (2011) буква x означает, что функция fopen должна завершиться с ошибкой, если файл уже существует.
Дополним нашу старую программу: заново откроем файл и считаем, что мы туда записали.

```
#include <stdio.h>
#include <conio.h>
#include <stdlib.h>

void main() {
	FILE *file;
	char buffer[128];

	file = fopen("C:/c/test.txt", "w");
	fprintf(file, "Hello, World!");
	fclose(file);
	file = fopen("C:/c/test.txt", "r");
	fgets(buffer, 127, file);
	printf("%s", buffer);
	fclose(file);
	getch();
}
```

Вместо функции fgets можно было использовать fscanf, но нужно помнить, что она может считать строку только до первого пробела.

fscanf(file, "%127s", buffer);

Также, вместо того, чтобы открывать и закрывать файл можно воспользоваться функцией freopen, которая «переоткрывает» файл с новыми правами доступа.

```
#include <stdio.h>
#include <conio.h>
#include <stdlib.h>

void main() {
	FILE *file;
	char buffer[128];

	file = fopen("C:/c/test.txt", "w");
	fprintf(file, "Hello, World!");
	freopen("C:/c/test.txt", "r", file);
	fgets(buffer, 127, file);
	printf("%s", buffer);
	fclose(file);
	getch();
}
```

Функции fprintf и  fscanf отличаются от printf и scanf только тем, что принимают в качестве первого аргумента указатель на FILE, в который они будут выводить или из которого 
они будут читать данные. 
Здесь стоит сразу же добавить, что функции printf и scanf могут быть без проблем заменены функциями fprintf и fscanf. В ОС (мы рассматриваем самые распространённые и 
адекватные операционные системы) существует три стандартных потока: стандартный поток вывода stdout, стандартный поток ввода stdin и стандартный поток вывода ошибок stderr. Они автоматически открываются во время запуска приложения и связаны с консолью. Пример

```
#include <stdio.h>
#include <conio.h>
#include <stdlib.h>

void main() {
	int a, b;
	fprintf(stdout, "Enter two numbers\n");
	fscanf(stdin, "%d", &a);
	fscanf(stdin, "%d", &b);
	if (b == 0) {
		fprintf(stderr, "Error: divide by zero");
	} else {
		fprintf(stdout, "%.3f", (float) a / (float) b);
	}
	getch();
}
```

## Ошибка открытия файла

Если вызов функции fopen прошёл неудачно, то она возвратит NULL. Ошибки во время работы с файлами встречаются достаточно часто, поэтому каждый раз, когда
мы окрываем файл, необходимо проверять результат работы

```
#include <stdio.h>
#include <conio.h>
#include <stdlib.h>

#define ERROR_OPEN_FILE -3

void main() {
	FILE *file;
	char buffer[128];

	file = fopen("C:/c/test.txt", "w");
	if (file == NULL) {
		printf("Error opening file");
		getch();
		exit(ERROR_OPEN_FILE);
	}
	fprintf(file, "Hello, World!");
	freopen("C:/c/test.txt", "r", file);
	if (file == NULL) {
		printf("Error opening file");
		getch();
		exit(ERROR_OPEN_FILE);
	}
	fgets(buffer, 127, file);
	printf("%s", buffer);
	fclose(file);
	getch();
}
```

Проблему вызывает случай, когда открывается сразу несколько файлов: если один из них нельзя открыть, то остальные также должны быть закрыты

```
...
FILE *inputFile, *outputFile;
	unsigned m, n;
	unsigned i, j;

	inputFile = fopen(INPUT_FILE, READ_ONLY);
	if (inputFile == NULL) {
		printf("Error opening file %s", INPUT_FILE);
		getch();
		exit(3);
	}
	outputFile = fopen(OUTPUT_FILE, WRITE_ONLY);
	if (outputFile == NULL) {
		printf("Error opening file %s", OUTPUT_FILE);
		getch();
		if (inputFile != NULL) {
			fclose(inputFile);
		}
		exit(4);
	}
...
```

В простых случаях можно действовать влоб, как в предыдущем куске кода. В более сложных случаях используются 
методы, подменяющиее RAII из С++: обёртки, или особенности компилятора (cleanup в GCC) и т.п.

## Буферизация данных

Как уже говорилось ранее, когда мы выводим данные, они сначала помещаются в буфер. Очистка буфера осуществляется

Форсировать выгрузку буфера можно с помощью вызова функции fflush(File *). Рассмотрим два примера – с очисткой и без.

```
#include <stdio.h>
#include <conio.h>
#include <stdlib.h>

void main() {
	FILE *file;
	char c;

	file = fopen("C:/c/test.txt", "w");
	
	do {
		c = getch();
		fprintf(file, "%c", c);
		fprintf(stdout, "%c", c);
		//fflush(file);
	} while(c != 'q');

	fclose(file);
	getch();
}
```

Раскомментируйте вызов fflush. Во время выполнения откройте текстовый файл и посмотрите на поведение.

Буфер файла можно назначить самостоятельно, задав свой размер. Делается это при помощи функции

```
void setbuf (FILE * stream, char * buffer);
```

которая принимает уже открытый FILE и указатель на новый буфер. Размер нового буфера должен быть не меньше чем BUFSIZ (к примеру, на текущей рабочей станции BUFSIZ равен 512 байт). 
Если передать в качестве буфера NULL, то поток станет небуферизированным. Можно также воспользоваться функцией

```
int setvbuf ( FILE * stream, char * buffer, int mode, size_t size );
```

которая принимает буфер произвольного размера size. Режим mode может принимать следующие значения

Пример: зададим свой буфер и посмотрим, как осуществляется чтение из файла. Пусть файл короткий (что-нибудь, типа Hello, World!), и считываем мы его посимвольно

```
#include <conio.h>
#include <stdio.h>
#include <stdlib.h>

void main() {
	FILE *input = NULL;
	char c;
	char buffer[BUFSIZ * 2] = {0};

	input = fopen("D:/c/text.txt", "rt");
	setbuf(input, buffer);

	while (!feof(input)) {
		c = fgetc(input);
		printf("%c\n", c);
		printf("%s\n", buffer);
		_getch();
	}

	fclose(input);
}
```

Видно, что данные уже находятся в буфере. Считывание посимвольно производится уже из буфера.

## feof

Функция int feof (FILE * stream);
возвращает истину, если конец файла достигнут. Функцию удобно использовать, когда необходимо пройти весь файл от начала до конца.
Пусть есть файл с текстовым содержимым text.txt. Считаем посимвольно файл и выведем на экран.

```
#include <conio.h>
#include <stdio.h>
#include <stdlib.h>

void main() {
	FILE *input = NULL;
	char c;

	input = fopen("D:/c/text.txt", "rt");
	if (input == NULL) {
		printf("Error opening file");
		_getch();
		exit(0);
	}
	while (!feof(input)) {
		c = fgetc(input);
		fprintf(stdout, "%c", c);
	}

	fclose(input);
	_getch();
}
```

Всё бы ничего, только функция feof работает неправильно... Это связано с тем, что понятие "конец файла" не определено. При использовании feof
часто возникает ошибка, когда последние считанные данные выводятся два раза. Это связано с тем, что данные записывается в буфер ввода, последнее
считывание происходит с ошибкой и функция возвращает старое считанное значение.

```
#include <conio.h>
#include <stdio.h>
#include <stdlib.h>
 
void main() {
    FILE *input = NULL;
    char c;
 
    input = fopen("D:/c/text.txt", "rt");
    if (input == NULL) {
        printf("Error opening file");
        _getch();
        exit(0);
    }
    while (!feof(input)) {
        fscanf(input, "%c", &c);
        fprintf(stdout, "%c", c);
    }
 
    fclose(input);
    _getch();
}
```

Этот пример сработает с ошибкой (скорее всего) и выведет последний символ файла два раза.

Решение – не использовать feof. Например, хранить общее количество записей или использовать тот факт, что функции
fscanf и пр. обычно возвращают число верно считанных и сопоставленных значений.

```
#include <conio.h>
#include <stdio.h>
#include <stdlib.h>

void main() {
    FILE *input = NULL;
    char c;
 
    input = fopen("D:/c/text.txt", "rt");
    if (input == NULL) {
        printf("Error opening file");
        _getch();
        exit(0);
    }
    while (fscanf(input, "%c", &c) == 1) {
        fprintf(stdout, "%c", c);
    }
 
    fclose(input);
    _getch();
}
```

## Примеры

1. В одном файле записаны два числа - размерности массива. Заполним второй файл массивом случайных чисел.

```
#include <stdio.h>
#include <conio.h>
#include <stdlib.h>
#include <time.h>

//Имена файлов и права доступа
#define INPUT_FILE  "D:/c/input.txt"
#define OUTPUT_FILE "D:/c/output.txt"
#define READ_ONLY  "r"
#define WRITE_ONLY "w"
//Максимальное значение для размера массива
#define MAX_DIMENSION 100
//Ошибка при открытии файла
#define ERROR_OPEN_FILE -3

void main() {
	FILE *inputFile, *outputFile;
	unsigned m, n;
	unsigned i, j;

	inputFile = fopen(INPUT_FILE, READ_ONLY);
	if (inputFile == NULL) {
		printf("Error opening file %s", INPUT_FILE);
		getch();
		exit(ERROR_OPEN_FILE);
	}
	outputFile = fopen(OUTPUT_FILE, WRITE_ONLY);
	if (outputFile == NULL) {
		printf("Error opening file %s", OUTPUT_FILE);
		getch();
//Если файл для чтения удалось открыть, то его необходимо закрыть
		if (inputFile != NULL) {
			fclose(inputFile);
		}
		exit(ERROR_OPEN_FILE);
	}

	fscanf(inputFile, "%ud %ud", &m, &n);
	if (m > MAX_DIMENSION) {
		m = MAX_DIMENSION;
	}
	if (n > MAX_DIMENSION) {
		n = MAX_DIMENSION;
	}
	srand(time(NULL));
	for (i = 0; i < n; i++) {
		for (j = 0; j < m; j++) {
			fprintf(outputFile, "%8d ", rand());
		}
		fprintf(outputFile, "\n");
	}

//Закрываем файлы
	fclose(inputFile);
	fclose(outputFile);
}
```

2. Пользователь копирует файл, при этом сначала выбирает режим работы: файл может выводиться как на консоль, так и копироваться в новый файл.

```
#include <stdio.h>
#include <conio.h>
#include <stdlib.h>

#define ERROR_FILE_OPEN -3

void main() {
	FILE *origin = NULL;
	FILE *output = NULL;
	char filename[1024];
	int mode;

	printf("Enter filename: ");
	scanf("%1023s", filename);

	origin = fopen(filename, "r");
	if (origin == NULL) {
		printf("Error opening file %s", filename);
		getch();
		exit(ERROR_FILE_OPEN);
	}

	printf("enter mode: [1 - copy, 2 - print] ");
	scanf("%d", &mode);

	if (mode == 1) {
		printf("Enter filename: ");
		scanf("%1023s", filename);
		output = fopen(filename, "w");
		if (output == NULL) {
			printf("Error opening file %s", filename);
			getch();
			fclose(origin);
			exit(ERROR_FILE_OPEN);
		}
	} else {
		output = stdout;
	}

	while (!feof(origin)) {
		fprintf(output, "%c", fgetc(origin));
	}

	fclose(origin);
	fclose(output);

	getch();
}
```

3. Пользователь вводит данные с консоли и они записываются в файл до тех пор, пока не будет нажата клавиша esc. Проверьте программу и посмотрите. как она себя ведёт в случае, если вы вводите backspace: что выводится в файл и что выводится на консоль.

```
#include <stdio.h>
#include <conio.h>
#include <stdlib.h>

#define ERROR_FILE_OPEN -3

void main() {
	FILE *output = NULL;
	char c;

	output = fopen("D:/c/test_output.txt", "w+t");
	if (output == NULL) {
		printf("Error opening file");
		_getch();
		exit(ERROR_FILE_OPEN);
	}

	for (;;) {
		c = _getch();
		if (c == 27) {
			break;
		}
		fputc(c, output);
		fputc(c, stdout);
	}

	fclose(output);
}
```

4. В файле записаны целые числа. Найти максимальное из них. Воспользуемся тем, что функция fscanf возвращает число верно прочитанных и сопоставленных объектов. Каждый раз должно возвращаться число 1.

```
#include <stdio.h>
#include <stdlib.h>
#include <limits.h>

#define ERROR_FILE_OPEN -3

void main() {
	FILE *input = NULL;
	int num, maxn, hasRead;

	input = fopen("D:/c/input.txt", "r");
	if (input == NULL) {
		printf("Error opening file");
		_getch();
		exit(ERROR_FILE_OPEN);
	}

	maxn = INT_MIN;
	hasRead = 1;
	while (hasRead == 1) {
		hasRead = fscanf(input, "%d", &num);
		if (hasRead != 1) {
			continue;
		}
		if (num > maxn) {
			maxn = num;
		}
	}
	printf("max number = %d", maxn);
	fclose(input);
	_getch();
}
```

Другое решение считывать числа, пока не дойдём до конца файла.

```
#include <conio.h>
#include <stdio.h>
#include <stdlib.h>
#include <limits.h>

#define ERROR_FILE_OPEN -3

void main() {
	FILE *input = NULL;
	int num, maxn, hasRead;

	input = fopen("D:/c/input.txt", "r");
	if (input == NULL) {
		printf("Error opening file");
		_getch();
		exit(ERROR_FILE_OPEN);
	}

	maxn = INT_MIN;
	while (!feof(input)) {
		fscanf(input, "%d", &num);
		if (num > maxn) {
			maxn = num;
		}
	}
	printf("max number = %d", maxn);

	fclose(input);
	_getch();
}
```

5. В файле записаны слова: русское слово, табуляция, английское слово, в несколько рядов. Пользователь вводит английское слово, необходимо вывести русское.

Файл с переводом выглядит примерно так

и сохранён в кодировке cp866 (OEM 866). При этом важно: последняя пара cлов также заканчивается переводом строки.

Алгоритм следующий - считываем строку из файла, находим в строке знак табуляции, подменяем знак табуляции нулём, копируем русское слово из буфера, копируем английское слово из буфера, проверяем на равенство.

```
#include <conio.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define ERROR_FILE_OPEN -3

void main() {
	FILE *input = NULL;
	char buffer[512];
	char enWord[128];
	char ruWord[128];
	char usrWord[128];
	unsigned index;
	int length;
	int wasFound;

	input = fopen("D:/c/input.txt", "r");
	if (input == NULL) {
		printf("Error opening file");
		_getch();
		exit(ERROR_FILE_OPEN);
	}

	printf("enter word: ");
	fgets(usrWord, 127, stdin);
	wasFound = 0;
	while (!feof(input)) {
		fgets(buffer, 511, input);
		length = strlen(buffer);
		for (index = 0; index < length; index++) {
			if (buffer[index] == '\t') {
				buffer[index] = '\0';
				break;
			}
		}
		strcpy(ruWord, buffer);
		strcpy(enWord, &buffer[index + 1]);
		if (!strcmp(enWord, usrWord)) {
			wasFound = 1;
			break;
		}
	}

	if (wasFound) {
		printf("%s", ruWord);
	} else {
		printf("Word not found");
	}

	fclose(input);
	_getch();
}
```

6. Подсчитать количество строк в файле. Будем считывать файл посимвольно, считая количество символов '\n' до тех пор, пока не встретим символ EOF. EOF – это спецсимвол,
который указывает на то, что ввод закончен и больше нет данных для чтения. Функция возвращает отрицательное значение в случае ошибки.
ЗАМЕЧАНИЕ: EOF имеет тип int, поэтому нужно использовать int для считывания символов. Кроме того, значение EOF не определено стандартом.

```
#define _CRT_SECURE_NO_WARNINGS

#include <conio.h>
#include <stdio.h>
#include <stdlib.h>

int cntLines(const char *filename) {
	int lines = 0;
	int any;	//any типа int, потому что EOF имеет тип int!
	FILE *f = fopen(filename, "r");
	if (f == NULL) {
		return -1;
	}
	do {
		any = fgetc(f);
		//printf("%c", any);//debug
		if (any == '\n') {
			lines++;
		}
	} while(any != EOF);
	fclose(f);
	return lines;
}

void main() {
	printf("%d\n", cntLines("C:/c/file.txt"));
	_getch();
}
```

