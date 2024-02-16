# Бинарные файлы

Текстовые файлы хранят данные в виде текста (sic!). Это значит, что если, например, мы записываем целое число 12345678 в файл, то 
записывается 8 символов, а это 8 байт данных, несмотря на то, что число помещается в целый тип. Кроме того, вывод и ввод данных является форматированным, то 
есть каждый раз, когда мы считываем число из файла или записываем в файл происходит трансформация числа в строку или обратно. Это затратные операции, которых можно избежать.

Текстовые файлы позволяют хранить информацию в виде, понятном для человека. Можно, однако, хранить данные непосредственно в бинарном виде. Для этих целей используются 
бинарные файлы.

```
#include <conio.h>
#include <stdio.h>
#include <stdlib.h>

#define ERROR_FILE_OPEN -3

void main() {
	FILE *output = NULL;
	int number;

	output = fopen("D:/c/output.bin", "wb");
	if (output == NULL) {
		printf("Error opening file");
		getch();
		exit(ERROR_FILE_OPEN);
	}

	scanf("%d", &number);
	fwrite(&number, sizeof(int), 1, output);

	fclose(output);
	_getch();
}
```

Выполните программу и посмотрите содержимое файла output.bin. Число, которое ввёл пользователь записывается в файл непосредственно в бинарном виде. Можете 
открыть файл в любом редакторе, поддерживающем представление в шестнадцатеричном виде (Total Commander, Far)   и убедиться в этом.

Запись в файл осуществляется с помощью функции

```
size_t fwrite ( const void * ptr, size_t size, size_t count, FILE * stream );
```

Функция возвращает число удачно записанных элементов. В качестве аргументов принимает указатель на массив, размер одного элемента, число элементов и указатель на файловый поток. 
Вместо массив, конечно, может быть передан любой объект.

Запись в бинарный файл объекта похожа на его отображение: берутся данные из оперативной памяти и пишутся как есть. Для считывания используется функция fread

```
size_t fread ( void * ptr, size_t size, size_t count, FILE * stream );
```

Функция возвращает число удачно прочитанных элементов, которые помещаются по адресу ptr. Всего считывается count элементов по size байт. Давайте теперь считаем наше число 
обратно в переменную.

```
#include <conio.h>
#include <stdio.h>
#include <stdlib.h>

#define ERROR_FILE_OPEN -3

void main() {
	FILE *input = NULL;
	int number;

	input = fopen("D:/c/output.bin", "rb");
	if (input == NULL) {
		printf("Error opening file");
		getch();
		exit(ERROR_FILE_OPEN);
	}

	fread(&number, sizeof(int), 1, input);
	printf("%d", number);

	fclose(input);
	_getch();
}
```

## fseek

Одной из важных функций для работы с бинарными файлами является функция fseek

```
int fseek ( FILE * stream, long int offset, int origin );
```

Эта функция устанавливает указатель позиции, ассоциированный с потоком, на новое положение. Индикатор позиции указывает, на каком месте в файле мы остановились. 
Когда мы открываем файл, позиция равна 0. Каждый раз, записывая байт данных, указатель позиции сдвигается на единицу вперёд.

fseek принимает в качестве аргументов указатель на поток и сдвиг в offset байт относительно origin. origin  может принимать три значения

В случае удачной работы функция возвращает 0.

Дополним наш старый пример: запишем число, затем сдвинемся указатель на начало файла и прочитаем его.

```
#include <conio.h>
#include <stdio.h>
#include <stdlib.h>

#define ERROR_FILE_OPEN -3

void main() {
	FILE *iofile = NULL;
	int number;

	iofile = fopen("D:/c/output.bin", "w+b");
	if (iofile == NULL) {
		printf("Error opening file");
		getch();
		exit(ERROR_FILE_OPEN);
	}

	scanf("%d", &number);
	fwrite(&number, sizeof(int), 1, iofile);
	fseek(iofile, 0, SEEK_SET);
	number = 0;
	fread(&number, sizeof(int), 1, iofile);
	printf("%d", number);

	fclose(iofile);
	_getch();
}
```

Вместо этого можно также использовать функцию rewind, которая перемещает индикатор позиции в начало.

В си определён специальный тип fpos_t, который используется для хранения позиции индикатора позиции в файле.

Функция

```
int fgetpos ( FILE * stream, fpos_t * pos );
```

используется для того, чтобы назначить переменной pos текущее положение. Функция

```
int fsetpos ( FILE * stream, const fpos_t * pos );
```

используется для перевода указателя в позицию, которая хранится в переменной pos. Обе функции в случае удачного завершения возвращают ноль.

```
long int ftell ( FILE * stream );
```

возвращает текущее положение индикатора относительно начала файла. Для бинарных файлов - это число  байт, для текстовых не определено (если текстовый файл состоит из однобайтовых 
символов, то также число байт).

Рассмотрим пример: пользователь вводит числа. Первые 4 байта файла: целое, которое обозначает, сколько чисел было введено. После того, как пользователь прекращает вводить числа, 
мы перемещаемся в начало файла и записываем туда число введённых элементов.

```
#include <stdio.h>
#include <conio.h>
#include <stdlib.h>

#define ERROR_OPEN_FILE -3
 
void main() {
    FILE *iofile = NULL;
	unsigned counter = 0;
	int num;
	int yn;

	iofile = fopen("D:/c/numbers.bin", "w+b");
	if (iofile == NULL) {
		printf("Error opening file");
		getch();
		exit(ERROR_OPEN_FILE);
	}

	fwrite(&counter, sizeof(int), 1, iofile);
	do {
		printf("enter new number? [1 - yes, 2 - no]");
		scanf("%d", &yn);
		if (yn == 1) {
			scanf("%d", &num);
			fwrite(&num, sizeof(int), 1, iofile);
			counter++;
		} else {
			rewind(iofile);
			fwrite(&counter, sizeof(int), 1, iofile);
			break;
		}
	} while(1);
	
	fclose(iofile);
	getch();
}
```

Вторая программа сначала считывает количество записанных чисел, а потом считывает и выводит числа по порядку.

```
#include <stdio.h>
#include <conio.h>
#include <stdlib.h>

#define ERROR_OPEN_FILE -3
 
void main() {
    FILE *iofile = NULL;
	unsigned counter;
	int i, num;

	iofile = fopen("D:/c/numbers.bin", "rb");
	if (iofile == NULL) {
		printf("Error opening file");
		getch();
		exit(ERROR_OPEN_FILE);
	}

	fread(&counter, sizeof(int), 1, iofile);
	for (i = 0; i < counter; i++) {
		fread(&num, sizeof(int), 1, iofile);
		printf("%d\n", num);
	}
	
	fclose(iofile);
	getch();
}
```

## Примеры

1. Имеется бинарный файл размером 10*sizeof(int) байт. Пользователь вводит номер ячейки, после чего в неё записывает число. После каждой операции выводятся все числа. Сначала пытаемся открыть файл в режиме чтения и записи. Если это не удаётся, то пробуем создать файл, если удаётся создать файл, то повторяем попытку открыть файл для чтения и записи.

```
#include <stdio.h>
#include <conio.h>
#include <stdlib.h>

#define SIZE 10

void main() {
	const char filename[] = "D:/c/state";
	FILE *bfile = NULL;
	int pos;
	int value = 0;
	int i;
	char wasCreated;

	do {
		wasCreated = 0;
		bfile = fopen(filename, "r+b");
		if (NULL == bfile) {
			printf("Try to create file...\n");
			getch();
			bfile = fopen(filename, "wb");
			if (bfile == NULL) {
				printf("Error when create file");
				getch();
				exit(1);
			}
			for (i = 0; i < SIZE; i++) {
				fwrite(&value, sizeof(int), 1, bfile);
			}
			printf("File created successfully...\n");
			fclose(bfile);
			wasCreated = 1;
		}
	} while(wasCreated);

	do {
		printf("Enter position [0..9] ");
		scanf("%d", &pos);
		if (pos < 0 || pos >= SIZE) {
			break;
		}
		printf("Enter value ");
		scanf("%d", &value);
		fseek(bfile, pos*sizeof(int), SEEK_SET);
		fwrite(&value, sizeof(int), 1, bfile);
		rewind(bfile);
		for (i = 0; i < SIZE; i++) {
			fread(&value, sizeof(int), 1, bfile);
			printf("%d ", value);
		}
		printf("\n");
	} while(1);

	fclose(bfile);
}
```

2. Пишем слова в бинарный файл. Формат такой - сначало число букв, потом само слово без нулевого символа. Ели длина слова равна нулю, то больше слов нет.
Сначала запрашиваем слова у пользователя, потом считываем обратно.

```
#include <stdio.h>
#include <conio.h>
#include <stdlib.h>
#include <string.h>

#define ERROR_FILE_OPEN -3

void main() {
	const char filename[] = "C:/c/words.bin";
	const char termWord[] = "exit";
	char buffer[128];
	unsigned int len;
	FILE *wordsFile = NULL;

	printf("Opening file...\n");

	wordsFile = fopen(filename, "w+b");
	if (wordsFile == NULL) {
		printf("Error opening file");
		getch();
		exit(ERROR_FILE_OPEN);
	}

	printf("Enter words\n");
	do {
		scanf("%127s", buffer);
		if (strcmp(buffer, termWord) == 0) {
			len = 0;
			fwrite(&len, sizeof(unsigned), 1, wordsFile);
			break;
		}
		len = strlen(buffer);
		fwrite(&len, sizeof(unsigned), 1, wordsFile);
		fwrite(buffer, 1, len, wordsFile);
	} while(1);
	
	printf("rewind and read words\n");
	rewind(wordsFile);
	getch();

	do {
		fread(&len, sizeof(int), 1, wordsFile);
		if (len == 0) {
			break;
		}
		fread(buffer, 1, len, wordsFile);
		buffer[len] = '\0';
		printf("%s\n", buffer);
	} while(1);
	fclose(wordsFile);
	getch();
}
```

3. Задача - считать данные из текстового файла и записать их в бинарный. Для решения зачи создадим функцию обёртку. Она будет принимать имя файла, режим доступа, 
функцию, которую необходимо выполнить, если файл был удачно открыт и аргументы этой функции. Так как аргументов может быть много  и они могут быть разного типа,
то их можно передавать в качестве указателя на структуру. После выполнения функции файл закрывается. Таким образом, нет необходимости думать об освобождении ресурсов.

```
#include <stdio.h>
#include <conio.h>
#include <stdlib.h>
#define DEBUG

#ifdef DEBUG
#define debug(data) printf("%s", data);
#else
#define debug(data)
#endif

const char inputFile[] = "D:/c/xinput.txt";
const char outputFile[] = "D:/c/output.bin";

struct someArgs {
	int* items;
	size_t number;
};

int writeToFile(FILE *file, void* args) {
	size_t i;
	struct someArgs *data = (struct someArgs*) args;
	debug("write to file\n")
	fwrite(data->items, sizeof(int), data->number, file);
	debug("write finished\n")
	return 0;
}

int readAndCallback(FILE *file, void* args) {
	struct someArgs data;
	size_t size, i = 0;
	int result;
	debug("read from file\n")
	fscanf(file, "%d", &size);
	data.items = (int*) malloc(size*sizeof(int));
	data.number = size;
	while (!feof(file)) {
		fscanf(file, "%d", &data.items[i]);
		i++;
	}
	debug("call withOpenFile\n")
	result = withOpenFile(outputFile, "w", writeToFile, &data);
	debug("read finish\n")
	free(data.items);
	return result;
}

int doStuff() {
	return withOpenFile(inputFile, "r", readAndCallback, NULL);
}

//Обёртка - функция открывает файл. Если файл был благополучно открыт,
//то вызывается функция fun. Так как аргументы могут быть самые разные,
//то они передаются через указатель void*. В качестве типа аргумента
//разумно использовать структуру
int withOpenFile(const char *filename, 
				 const char *mode,
				 int (*fun)(FILE* source, void* args), 
				 void* args) {
	FILE *file = fopen(filename, mode);
	int err;

	debug("try to open file ")
	debug(filename)
	debug("\n")

	if (file != NULL) {
		err = fun(file, args);
	} else {
		return 1;
	}
	debug("close file ")
	debug(filename)
	debug("\n")
	fclose(file);
	return err;
}

void main() {
	printf("result = %d", doStuff());
	getch();
}
```

4. Функция saveInt32Array позволяет сохранить массив типа int32_t в файл. Обратная ей loadInt32Array считывает массив обратно.
Функция loadInt32Array сначала инициализирует переданный ей массив, поэтому мы должны передавать указатель на указатель; кроме того,
она записывает считанный размер массива в переданный параметр size, из-за чего он передаётся как указатель.

```
#include <stdio.h>
#include <conio.h>
#include <stdlib.h>
#include <stdint.h>

#define SIZE 100

int saveInt32Array(const char *filename, const int32_t *a, size_t size) {
	FILE *out = fopen(filename, "wb");
	if (!out) {
		return 0;
	}
	//Записываем длину массива
	fwrite(&size, sizeof(size_t), 1, out);
	//Записываем весь массив
	fwrite(a, sizeof(int32_t), size, out);
	fclose(out);
	return 1;
}

int loadInt32Array(const char *filename, int32_t **a, size_t *size) {
	FILE *in = fopen(filename, "rb");
	if (!in) {
		return 0;
	}
	//Считываем длину массива
	fread(size, sizeof(size_t), 1, in);
	//Инициализируем массив
	(*a) = (int32_t*) malloc(sizeof(int32_t) * (*size));
	if (!(*a)) {
		return 0;
	}
	//Считываем весь массив
	fread((*a), sizeof(int32_t), *size, in);
	fclose(in);
	return 1;
}

void main() {
	const char *tmpFilename = "tmp.bin";
	int32_t exOut[SIZE];
	int32_t *exIn = NULL;
	size_t realSize;
	int i;

	for (i = 0; i < SIZE; i++) {
		exOut[i] = i*i;
	}

	saveInt32Array(tmpFilename, exOut, SIZE);
	loadInt32Array(tmpFilename, &exIn, &realSize);

	for (i = 0; i < realSize; i++) {
		printf("%d ", exIn[i]);
	}

	_getch();
}
```

5. Создание таблицы поиска. Для ускорения работы программы вместо вычисления функции можно произвести сначала вычисление значений функции
на интервале с определённой точностью, после чего брать значения уже из таблицы. Программа сначала производит табулирование функции с заданными параметрами и сохраняет его в файл,
затем подгружает предвычисленный массив, который уже используется для определения значений. В этой программе все функции возвращают переменную типа Result,
которая хранит номер ошибки. Если функция отработала без проблем, то она возвращает Ok (0).

```
#define _CRT_SECURE_NO_WARNINGS
//Да, это теперь обязательно добавлять, иначе не заработает

#include <stdio.h>
#include <conio.h>
#include <stdlib.h>
#include <stdint.h>
#include <math.h>
//Каждая функция возвращает результат. Если он равен Ok, то функция
//отработала без проблем
typedef int Result;

//Возможные результаты работы
#define Ok 0
#define ERROR_OPENING_FILE  1
#define ERROR_OUT_OF_MEMORY 2

//Функция, которую мы будем табулировать
double mySinus(double x) {
	return sin(x);
}

Result tabFunction(const char *filename, double from, double to, double step, double (*f)(double)) {
	Result r;
	FILE *out = fopen(filename, "wb");
	double value;
	if (!out) {
		r = ERROR_OPENING_FILE;
		goto EXIT;
	}
	
	fwrite(&from, sizeof(from), 1, out);
	fwrite(&to, sizeof(to), 1, out);
	fwrite(&step, sizeof(step), 1, out);
	
	for (from; from < to; from += step) {
		value = f(from);
		fwrite(&value, sizeof(double), 1, out);
	}	

	r = Ok;
EXIT:
	fclose(out);
	return r;
}

Result loadFunction(const char *filename, double **a, double *from, double *to, double *step) {
	Result r;
	uintptr_t size;
	FILE *in = fopen(filename, "rb");
	if (!in) {
		r = ERROR_OPENING_FILE;
		goto EXIT;
	}
	//Считываем вспомогательную информацию
	fread(from, sizeof(*from), 1, in);
	fread(to, sizeof(*to), 1, in);
	fread(step, sizeof(*step), 1, in);
	//Инициализируем массив
	size = (uintptr_t) ((*to - *from) / *step);
	(*a) = (double*) malloc(sizeof(double)* size);
	if (!(*a)) {
		r = ERROR_OUT_OF_MEMORY;
		goto EXIT;
	}
	//Считываем весь массив
	fread((*a), sizeof(double), size, in);
	r = Ok;
EXIT:
	fclose(in);
	return r;
}

void main() {
	const char *tmpFilename = "tmp.bin";

	Result r;
	double *exIn = NULL;
	int accuracy, option;
	double from, to, step, arg;
	uintptr_t index;

	//Запрашиваем параметры для создания таблицы поиска
	printf("Enter parameters\nfrom = ");
	scanf("%lf", &from);
	printf("to = ");
	scanf("%lf", &to);
	printf("step = ");
	scanf("%lf", &step);

	r = tabFunction(tmpFilename, from, to, step, mySinus);
	if (r != Ok) {
		goto CATCH_SAVE_FUNCTION;
	}

	//Обратите внимание на формат вывода. Точность определяется
	//во время работы программы. Формат * подставит значение точности,
	//взяв его из списка аргументов
	accuracy = (int) (-log10(step));
	printf("function tabulated from %.*lf to %.*lf with accuracy %.*lf\n", 
			accuracy, from, accuracy, to, accuracy, step);

	r = loadFunction(tmpFilename, &exIn, &from, &to, &step);
	if (r != Ok) {
		goto CATCH_LOAD_FUNCTION;
	}
	
	accuracy = (int)(-log10(step));
	do {
		printf("1 to enter values, 0 to exit : ");
		scanf("%d", &option);
		if (option == 0) {
			break;
		}
		else if (option != 1) {
			continue;
		}

		printf("Enter value from %.*lf to %.*lf : ", accuracy, from, accuracy, to);
		scanf("%lf", &arg);
		if (arg < from || arg > to) {
			printf("bad value\n");
			continue;
		}
		index = (uintptr_t) ((arg - from) / step);
		printf("saved %.*lf\ncomputed %.*lf\n", accuracy, exIn[index], accuracy, mySinus(arg));
	} while (1);

	r = Ok;
	goto EXIT;
	CATCH_SAVE_FUNCTION: {
		printf("Error while saving values");
		goto EXIT;
	} 
	CATCH_LOAD_FUNCTION: {
		printf("Error while loading values");
		goto EXIT;
	}

EXIT:
	free(exIn);
	_getch();
	exit(r);
}
```

6. У нас имеются две структуры. Первая PersonKey хранит логин, пароль, id пользователя и поле offset. Вторая структура PersonInfo хранит имя и фамилию пользователя и его
возраст. Первые структуры записываются в бинарный файл keys.bin, вторые структуры в бинарный файл values.bin. Поле offset определяет положение соответствующей информации
о пользователе во втором файле. Таким образом, получив PersonKey из первого файла, по полю offset можно извлечь из второго файла связанную с данным ключом информацию.

Зачем так делать? Это выгодно в том случае, если структура PersonInfo имеет большой размер. Извлекать массив маленьких структур из
файла не накладно, а когда нам понадобится большая структура, её можно извлечь по уже известному адресу в файле.

```
#define _CRT_SECURE_NO_WARNINGS

#include <conio.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct PersonKey {
	long long id;
	char login[64];
	char password[64];
	long offset;//Положение соответствующих значений PersonInfo
} PersonKey;

typedef struct PersonInfo {
	unsigned age;
	char firstName[64];
	char lastName[128];
} PersonInfo;

/*
 Функция запрашивает у пользователя данные и пишет их подряд в два файла
*/
void createOnePerson(FILE *keys, FILE *values) {
	static long long id = 0;
	PersonKey pkey;
	PersonInfo pinfo;

	pkey.id = id++;
	//Так как все значения пишутся друг за другом, то текущее положение
	//указателя во втором файле будет позицией для новой записи
	pkey.offset = ftell(values);

	printf("Login: ");
	scanf("%63s", pkey.login);
	printf("Password: ");
	scanf("%63s", pkey.password);
	printf("Age: ");
	scanf("%d", &(pinfo.age));
	printf("First Name: ");
	scanf("%63s", pinfo.firstName);
	printf("Last Name: ");
	scanf("%127s", pinfo.lastName);

	fwrite(&pkey, sizeof(pkey), 1, keys);
	fwrite(&pinfo, sizeof(pinfo), 1, values);
}

void createPersons(FILE *keys, FILE *values) {
	char buffer[2];
	int repeat = 1;
	int counter = 0;//Количество элементов в файле
	//Резервируем место под запись числа элементов
	fwrite(&counter, sizeof(counter), 1, keys);
	printf("CREATE PERSONS\n");
	do {
		createOnePerson(keys, values);
		printf("\nYet another one? [y/n]");
		scanf("%1s", buffer);
		counter++;
		if (buffer[0] != 'y' && buffer[0] != 'Y') {
			repeat = 0;
		}
	} while(repeat);
	//Возвращаемся в начало и пишем количество созданных элементов
	rewind(keys);
	fwrite(&counter, sizeof(counter), 1, keys);
}

/*
 Создаём массив ключей
*/
PersonKey* readKeys(FILE *keys, int *size) {
	int i;
	PersonKey *out = NULL;
	rewind(keys);
	fread(size, sizeof(*size), 1, keys);
	out = (PersonKey*) malloc(*size * sizeof(PersonKey));
	fread(out, sizeof(PersonKey), *size, keys);
	return out;
}

/*
 Функция открывает сразу два файла. Чтобы упростить задачу, возвращаем массив файлов.
*/
FILE** openFiles(const char *keysFilename, const char *valuesFilename) {
	FILE **files = (FILE**)malloc(sizeof(FILE*)*2);
	files[0] = fopen(keysFilename, "w+b");
	if (!files[0]) {		
		return NULL;
	}
	files[1] = fopen(valuesFilename, "w+b");
	if (!files[1]) {
		fclose(files[0]);
		return NULL;
	}
	return files;
}

/*
 Две вспомогательные функции для вывода ключа и информации
*/
void printKey(PersonKey pk) {
	printf("%d. %s [%s]\n", (int)pk.id, pk.login, pk.password);
}

void printInfo(PersonInfo info) {
	printf("%d %s %s\n", info.age, info.firstName, info.lastName);
}

/*
 Функция по ключу (вернее, по его полю offset)
 достаёт нужное значение из второго файла
*/
PersonInfo readInfoByPersonKey(PersonKey pk, FILE *values) {
	PersonInfo out;
	rewind(values);
	fseek(values, pk.offset, SEEK_SET);
	fread(&out, sizeof(PersonInfo), 1, values);
	return out;
}

void getPersonsInfo(PersonKey *keys, FILE *values, int size) {
	int index;
	PersonInfo p;
	do {
	printf("Enter position of element. To exit print bad index: ");
	scanf("%d", &index);
		if (index < 0 || index >= size) {
			printf("Bad index");
			return;
		}
		p = readInfoByPersonKey(keys[index], values);
		printInfo(p);
	} while (1);
}

void main() {
	int size;
	int i;
	PersonKey *keys = NULL;
	FILE **files = openFiles("C:/c/keys.bin", "C:/c/values.bin");
	if (files == 0) {
		printf("Error opening files");
		goto FREE;
	}
	createPersons(files[0], files[1]);
	keys = readKeys(files[0], &size);

	for (i = 0; i < size; i++) {
		printKey(keys[i]);
	}

	getPersonsInfo(keys, files[1], size);

	fclose(files[0]);
	fclose(files[1]);
FREE:
	free(files);
	free(keys);
	_getch();
}
```

