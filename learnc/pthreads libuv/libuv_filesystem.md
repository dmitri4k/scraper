Для того, чтобы разобраться с библиотекой, начнём с файловой системы. Научимся 
открывать, читать и писать в файлы.



```
#include <uv.h>
#include <stdio.h>
#include <fcntl.h>

uv_loop_t* loop;

uv_fs_t open_req;
uv_fs_t close_req;

void open_cb(uv_fs_t*);
void close_cb(uv_fs_t*);

const char *filename = "C:/c/somedata.txt";

int main(int argc, char **argv) {
	int r;

	loop = uv_default_loop();

	r = uv_fs_open(loop, &open_req, filename, O_RDONLY, S_IREAD, open_cb);
	if (r < 0) {
		printf("Error at opening file: %s\n", uv_strerror(r));
	}

	uv_run(loop, UV_RUN_DEFAULT);
	return 0;
}

void open_cb(uv_fs_t* req) {
	int result = req->result;

	if (result < 0) {
		printf("Error at opening file: %s\n", uv_strerror(result));
	} else {
		printf("Successfully opened file.\n");
	}
	uv_fs_req_cleanup(req);
	uv_fs_close(loop, &close_req, open_req.result, close_cb);
}

void close_cb(uv_fs_t* req) {
	int result = req->result;

	if (result < 0) {
		printf("Error at closing file: %s\n", uv_strerror(result));
	} else {
		printf("Successfully closed file.\n");
	}
}
```

Сначала мы объявляем переменную loop, которая будет нашим главным циклом 
оповещения о событиях. Главный цикл собирает события и управляет их вызовом.

Библиотека основана на «запросах» разных типов, которые после своего завершения могут вызвать 
следующую функцию обратного вызова, которую мы будем называть дальше callback.

Запросы выполняются асинхронно, без ожидания завершения другими вызовами (сразу чтоит оговорить, что не все запросы асинхронны, и не при любых аргументах).
Для начала объявим два запроса для файловой системы – переменные типа uv_fs_t

```
uv_fs_t open_req;
uv_fs_t close_req;
```

а также объявим две функции колбэка – open_cb и close_cb. Эти функции будут вызываться ПОСЛЕ того, как выполнятся 
соответствующие функции. оpen_cb после вызова функции, открывающей файл, и close_cb после того, 
как выполнится функция закрытия файла.

Теперь заходим внутрь main. Сначала инициализируем наш event loop:

```
loop = uv_default_loop();
```

после чего помещаем в очередь операцию, открывающую файл

```
r = uv_fs_open(loop, &open_req, filename, O_RDONLY, S_IREAD, open_cb);
```

Вызов возвращает код ошибки меньше нуля, если функция не могла быть выполнена. Для того, чтобы получить текстовое 
сообщение ошибки, используется функция

```
uv_strerror(r);
```

Результатом операции uv_fs_open будет дескриптор файла. Это значение возвращается не непосредственно, 
а как поле result аргумента функции open_cb!

Вызов

```
uv_run(loop, UV_RUN_DEFAULT);
```

Запускает наш event loop.

После запуска происходит вызов функции, открывающей файл. После того, как файл открыт, будет вызван колбэк, переданный в 
качестве аргумента, то есть open_cb. Посмотрим ещё раз

```
int uv_fs_open(uv_loop_t* loop, uv_fs_t* req, const char* path, int flags, int mode, uv_fs_cb cb)
```

Первый аргумент – цикл событий, второй – запрос к файловой системе, третий – имя файла, затем идёт флаги доступа и тип 
доступа. Последним аргументом будет функция обратного вызова, которая автоматически сработает после завершения работы 
uv_fs_open и получит в качестве аргумента uv_fs_t – наш запрос, который будет содержать необходимые данные для работы 
с файлом.

Теперь собственно колбэки.

open_cb – вызывается после открытия файла. Внутри себя она проверяет результат. Если тот меньше нуля, то выводит ошибку.
Обязательным является вызов

```
uv_fs_req_cleanup(uv_fs_t*).
```

Эта функция очищает выделенную по необходимости память.
После этого в очередь ставится новая задача – закрыть файл. Всё аналогично вызову открытия файла

```
uv_fs_close(loop, &close_req, open_req.result, close_cb);
```

только здесь свой вызов close_req и свой колбэк close_cb. Работа колбэка close_cb тривиальна.

Это самый простой пример. Теперь давайте прочитаем из файла. Заранее укажу, что размер файла меньше, 
чем размер буфера. Как прочитать большой файл выясним позднее.

Для чтения будет использоваться функция

```
int uv_fs_read(uv_loop_t* loop, uv_fs_t* req, uv_file file, const uv_buf_t bufs[], unsigned int nbufs, 
	int64_t offset, uv_fs_cb cb)
```

Эта функция возвращает код ошибки, а в поле result запроса возвращает число удачно считанных байт данных.

Первый аргумент – loop, как и раньше, главный цикл, req – запрос, bufs – массив буферов, типа uv_buf_t, nbufs – число буферов, 
offset – сдвиг в файле (если мы читаем не с начала, например), cb – колбэк.

Вот сама программа

```
#include <uv.h>
#include <stdio.h>
#include <fcntl.h>

uv_loop_t* loop;

uv_fs_t open_req;
uv_fs_t close_req;
uv_fs_t exit_req;
uv_fs_t read_req;

void open_cb(uv_fs_t*);
void read_cb(uv_fs_t*);
void exit_cb(uv_fs_t*);

uv_buf_t buffer;

const char *filename = "C:/c/testdata.txt";
const size_t len = 1024;

int main(int argc, char **argv) {
	char *base = (char *) malloc(len);
	int r;

	loop = uv_default_loop();
	buffer = uv_buf_init(base, len);

	r = uv_fs_open(loop, &open_req, filename, O_RDONLY, 0, open_cb);

	if (r < 0) {
		printf("Error at opening file: %s\n", uv_strerror(r));
	}

	uv_run(loop, UV_RUN_DEFAULT);
	return 0;
}

void read_cb(uv_fs_t* req) {
	int result = req->result;

	if (result < 0) {
		printf("Error at reading file: %s\n", uv_strerror(result));
	}
	printf("%.*s", result, buffer.base);

	uv_fs_req_cleanup(req);
	uv_fs_close(loop, &close_req, open_req.result, exit_cb);
}

void open_cb(uv_fs_t* req) {
	int result = req->result;

	if (result < 0) {
		printf("Error at opening file: %s\n", uv_strerror((int)req->result));
	}
	printf("Successfully opened file.\n"); 
	uv_fs_req_cleanup(req);
	uv_fs_read(loop, &read_req, result, &buffer, 1, 0, read_cb);
}

void exit_cb(uv_fs_t* req) {
	printf("exit");
	free(buffer.base);
}
```

Разберём её подробнее. Особое внимание надо обратить на буфер, который используется для чтения из файла.

```
uv_buf_t buffer;
```

Здесь сразу стоит указать – функция uv_fs_read принимает в качестве аргумента массив буферов, но мы можем передавать 
один элемент (точнее указатель на него), так как это не будет отличаться от передачи массива из одного элемента (вот почему).

Структура uv_buf_t владеет полем base, которое необходимо инициализировать отдельно. Поле base – собственно массив, который 
и хранит считанные данные.

Для сборки структуры используется функция

```
uv_buf_t uv_buf_init(char* base, unsigned int len)
```

Важно помнить, что программист ответственен за очистку поля base после использования

```
free(buffer.base);
```

Теперь отдельно посмотрим колбек на чтение

```
void read_cb(uv_fs_t* req) {
	int result = req->result;

	if (result < 0) {
		printf("Error at reading file: %s\n", uv_strerror(result));
	}
	printf("%.*s", result, buffer.base);

	uv_fs_req_cleanup(req);
	uv_fs_close(loop, &close_req, open_req.result, exit_cb);
}
```

Напомню, что поле result запроса req содержит число удачно прочитанных символов. Как обычно, вызываем uv_fs_req_cleanup 
для очистки памяти, которая могла быть выделена в ходе выполнения. Вызов uv_fs_req_cleanup не обязательно проводить 
внутри колбэка. Все эти вызовы можно сгруппировать вместе после выполнения операций, например, так

```
void exit_cb(uv_fs_t* req) {
	printf("exit");
	free(buffer.base);
	uv_fs_req_cleanup(&open_req);
	uv_fs_req_cleanup(&close_req);
	uv_fs_req_cleanup(&read_req);
}
```

В конце делаем запрос на закрытие uv_fs_close.

Теперь прочитаем большой файл, который не помещается в буфер. Для этого будем проверять результат выполнения. Если 
считалось байт столько, какой и размер буфера, то считываем дальше, увеличивая offset – сдвиг в читаемом файле.

```
void read_cb(uv_fs_t* req) {
	int result = req->result; 
	int r;

	if (result < 0) {
		printf("Error at reading file: %s\n", uv_strerror(result));
	}
	//Если буфер заполнен, то читаем ещё раз
	printf("%.*s\n", result, buffer.base);
	if (result == len) {
		offset += len;
		r = uv_fs_read(loop, &read_req, req->file.fd, &buffer, 1, offset, read_cb);
	} else {
		r = uv_fs_close(loop, &close_req, open_req.result, exit_cb);
	}
}
```

Отметим следующие моменты

```
req->file.id
```

Весь код

```
#include <uv.h>
#include <stdio.h>
#include <fcntl.h>

uv_loop_t* loop;

uv_fs_t open_req;
uv_fs_t close_req;
uv_fs_t exit_req;
uv_fs_t read_req;

void open_cb(uv_fs_t*);
void read_cb(uv_fs_t*);
void exit_cb(uv_fs_t*);

uv_buf_t buffer;

const char *filename = "C:/c/testdata.txt";
const size_t len = 1024;
unsigned long offset = 0;

int main(int argc, char **argv) {
	char *base = (char *) malloc(len);
	int r;

	loop = uv_default_loop();
	buffer = uv_buf_init(base, len);

	r = uv_fs_open(loop, &open_req, filename, O_RDONLY, 0, open_cb);

	if (r < 0) {
		printf("Error at opening file: %s\n", uv_strerror(r));
	}

	uv_run(loop, UV_RUN_DEFAULT);
	return 0;
}

void read_cb(uv_fs_t* req) {
	int result = req->result; 
	int r;

	if (result < 0) {
		printf("Error at reading file: %s\n", uv_strerror(result));
	}
	//Если буфер заполнен, то читаем ещё раз
	printf("%.*s\n", result, buffer.base);
	if (result == len) {
		offset += len;
		r = uv_fs_read(loop, &read_req, open_req.result, &buffer, 1, offset, read_cb);
	} else {
		r = uv_fs_close(loop, &close_req, open_req.result, exit_cb);
	}
}

void open_cb(uv_fs_t* req) {
	int result = req->result;
	int r;

	if (result < 0) {
		printf("Error at opening file: %s\n", uv_strerror((int)req->result));
	}
	printf("Successfully opened file.\n"); 
	uv_fs_req_cleanup(req);
	r = uv_fs_read(loop, &read_req, result, &buffer, 1, 0, read_cb);
}

void exit_cb(uv_fs_t* req) {
	printf("exit");
	free(buffer.base);
	uv_fs_req_cleanup(&read_req);
}
```

Это просто – делаем запрос на запись.

```
#include <uv.h>
#include <stdio.h>
#include <fcntl.h>
#include <string.h>

uv_loop_t* loop;

uv_fs_t open_req;
uv_fs_t close_req;
uv_fs_t exit_req;
uv_fs_t write_req;

void open_cb(uv_fs_t*);
void write_cb(uv_fs_t*);
void exit_cb(uv_fs_t*);

uv_buf_t buffer;

const char *filename = "C:/c/testdata2.txt";
const size_t len = 1024;
unsigned long offset = 0;

int main(int argc, char **argv) {
	char *base = (char *) malloc(len);
	int r;

	loop = uv_default_loop();
	buffer = uv_buf_init(base, len);
	//Заносим данные, которые надо записать, в буфер
	memcpy(base, "Some data to save", 17);
	//Указываем, сколько байт записать
	buffer.len = 17;

	r = uv_fs_open(loop, &open_req, filename, O_RDWR | O_CREAT, 0666, open_cb);
	if (r < 0) {
		printf("Error at opening file: %s\n", uv_strerror(r));
	}

	uv_run(loop, UV_RUN_DEFAULT);
	return 0;
}

void write_cb(uv_fs_t* req) {
	int result = req->result; 
	int r;

	if (result < 0) {
		printf("Error at writing file: %s\n", uv_strerror(result));
	}
	r = uv_fs_close(loop, &close_req, req->file.fd, exit_cb);
}

void open_cb(uv_fs_t* req) {
	int result = req->result;
	int r;

	if (result < 0) {
		printf("Error at opening file: %s\n", uv_strerror((int)req->result));
	}
	printf("Successfully opened file.\n"); 
	uv_fs_req_cleanup(req);
	r = uv_fs_write(loop, &write_req, result, &buffer, 1, 0, write_cb);
}

void exit_cb(uv_fs_t* req) {
	printf("exit");
	free(buffer.base);
	uv_fs_req_cleanup(&write_req);
}
```

Теперь обсудим запрос на запись

```
r = uv_fs_open(loop, &open_req, filename, O_APPEND | O_CREAT, 0666, open_cb);
```

Здесь важно правильно указать права – O_CREAT – на создание, если файл ещё не создан, O_APPEND – добавить данные в конец 
(т.е. при нескольких запусках программы будет несколько раз записано одно и то же).

Колбэк на запись почти ничего не делает, он будет вызван тогда, когда данные записались, и после этого сразу же закрывает файл.

Для удаления файла используется функция uv_fs_unlink

```
int uv_fs_unlink(uv_loop_t* loop, uv_fs_t* req, const char* path, uv_fs_cb cb)
```

```
#include <uv.h>
#include <stdio.h>
#include <fcntl.h>
#ifdef _WIN32
#include <conio.h>
#define wait() _getch()
#else
#define wait() scanf("1");
#endif
 
uv_loop_t* loop;
uv_fs_t remove_file_req;
 
void remove_file_cb(uv_fs_t*);
 
const char *filename_remove = "C:/c/toremove.txt";
 
int main(int argc, char **argv) {
    int r;
 
    loop = uv_default_loop();
    r = uv_fs_unlink(loop, &remove_file_req, filename_remove, remove_file_cb);
    if (r) {
        printf("Error when remove file: %s\n", uv_strerror(r));
    }
    uv_run(loop, UV_RUN_DEFAULT);
    return 0;
}
 
void remove_file_cb(uv_fs_t* req) {
    int r = req->result;
    printf("file removed successfully with result = %d", r);
    uv_fs_req_cleanup(&remove_file_req);
    wait();
}
```

Следует указать, что все запросы к файловой системе буду выполнены синхронно в том случае, если в качестве колбэка стоит NULL:

```
int main(int argc, char **argv) {
	int r;

	loop = uv_default_loop();
	r = uv_fs_unlink(loop, &remove_file_req, filename_remove, NULL);
	uv_fs_req_cleanup(&remove_file_req);
	if (r < 0) {
		printf("Error when remove file: %s\n", uv_strerror(r));
	}
	uv_run(loop, UV_RUN_DEFAULT);
	return 0;
}
```

