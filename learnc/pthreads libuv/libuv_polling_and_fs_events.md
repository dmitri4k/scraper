## Поллинг статуса файла

Отслеживание состояния файла и содержимого папки важная задача. Например, необходимо
обновлять сервер при изменении конфигурационного файла, чистить кеш при изменении или
добавлении новых файлов, оповещать о внесённых изменения и т.п. На различных ОС оптимальная реализация
решения этой задачи будет различной. Кроссплатформенная библиотека libuv предоставляет два
метода для мониторинга состояния файловой системы - поллинг и отслеживание событий файловой системы.

Поллинг – это процесс периодического опроса. В библиотеке libuv есть множество методов для работы с таймером и очередями, однако отдельно выделен метод опроса состояния файла.
Поллинг состоит из нескольких шагов

Для инициализации обработчика используется функция

```
int uv_fs_poll_init(uv_loop_t* loop, uv_fs_poll_t* handle)
```

которая принимает, как обычно, цикл и указатель на handle – обработчик типа uv_fs_poll_t

Для старта используется функция

```
int uv_fs_poll_start(uv_fs_poll_t* handle, uv_fs_poll_cb poll_cb, const char* path, unsigned int interval)
```

принимающая инициализированный хэндл, указатель на функцию обработчик, строку с именем файла и число миллисекунд (интервал опроса). В различных ОС  интервал меньше секунды может не восприниматься.



Функция обработчик имеет сигнатуру

```
void (*uv_fs_poll_cb)(uv_fs_poll_t* handle, int status, const uv_stat_t* prev, const uv_stat_t* curr)
```

Два аргумента prev и curr – это статус файла, предыдущий, и текущий (после произошедшего обновления). 
О статусе файла см. предыдущий раздел.

Для остановки процесса воспользуйтесь функцией

```
int uv_fs_poll_stop(uv_fs_poll_t* handle)
```

Пример поллинга

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
uv_fs_t stat_req;

static uv_fs_poll_t poll_handle;

void stat_cb(uv_fs_poll_t* handle, int status, const uv_stat_t* prev, const uv_stat_t* curr);

const char *filename = "C:/c/somefile.txt";
const unsigned interval = 2000;

int main(int argc, char **argv) {
	int r;

	uv_loop_t *loop = uv_default_loop();

	r = uv_fs_poll_init(loop, &poll_handle);
	printf("init result = %d\n", r);
	uv_fs_poll_start(&poll_handle, stat_cb, filename, interval);

	uv_run(loop, UV_RUN_DEFAULT);
	return 0;
}

void stat_cb(uv_fs_poll_t* handle, int status, const uv_stat_t* prev, const uv_stat_t* curr) {
	struct tm * timeinfo;
	char buff[20];

	timeinfo = localtime(&curr->st_atim);
	strftime(buff, 20, "%b %d %H:%M", timeinfo);
	printf("st_atime: %s\n", buff);

	wait();
}
```

После запуска программы изменяйте файл - меняйте содержимое, имя, удаляйте. Программа будет отслеживать изменение файла.

События файловой системы платформозависимы. Библиотека даёт обёртку, которая позволяет писать кроссплатформенный код, 
но ограничивает функционал.

Реализация детектирования событий (создание, изменение или удаление файлов) происходит наилучшим для данной ОС способом. Т.е., если нет иной возможности, то обработка событий скатывается к процессу поллинга.

Работа с событиями похожа на работу с поллингом. Сначала инициализируется хэндл, потом указывается директория, за которой следит  обработчик. После этого обработку событий можно отключить.

Инициализация производится с помощью функции

```
int uv_fs_event_init(uv_loop_t* loop, uv_fs_event_t* handle)
```

Для старта процесс

```
int uv_fs_event_start(uv_fs_event_t* handle, uv_fs_event_cb cb, const char* path, unsigned int flags)
```

где filename – имя папки, изменения в которой будут отслеживаться. Здесь флаги flags могут приниматься одно из значений перечисления

```
enum uv_fs_event_flags {
    UV_FS_EVENT_WATCH_ENTRY = 1,
    UV_FS_EVENT_STAT = 2,
    UV_FS_EVENT_RECURSIVE = 4
};
```

По умолчанию можно оставлять флаг равным нулю.

Колбэк имеет следующую сигнатуру

```
void (*uv_fs_event_cb)(uv_fs_event_t* handle, const char* filename, int events, int status)
```

Он принимает имя файла, изменения которого были отмечены, и тип изменения (флаг events). Ип изменение – одно из значений перечисления

```
enum uv_fs_event {
    UV_RENAME = 1,
    UV_CHANGE = 2
};
```

Для остановки воспользуйтесь функцей

```
int uv_fs_event_stop(uv_fs_event_t* handle)
```

Пример отслеживания событий

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
uv_fs_t stat_req;

static uv_fs_event_t event_handle;

void stat_cb(uv_fs_event_t* handle, const char* filename, int events, int status);

const char *filename = "C:/c";

int main(int argc, char **argv) {
	int r;

	uv_loop_t *loop = uv_default_loop();

	r = uv_fs_event_init(loop, &event_handle);
	printf("init result = %d\n", r);
	uv_fs_event_start(&event_handle, stat_cb, filename, 0);

	uv_run(loop, UV_RUN_DEFAULT);
	return 0;
}

void stat_cb(uv_fs_event_t* handle, const char* filename, int events, int status) {
	char buff[20];


	switch (events) {
	case UV_RENAME:
		printf("renamed");
		break;
	case UV_CHANGE: 
		printf("changed");
		break;
	case UV_RENAME | UV_CHANGE:
		printf("renamed and changed");
		break;
	}

	printf("\n%s\n", filename);
}
```

Эта программа мониторит папку C:/c. Изменение содержимого папки будет отображаться на экране.

