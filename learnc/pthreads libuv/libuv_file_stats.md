## Получение свойств файла

Для кроссплатформенного получения свойств файла в библиотеке libuv есть три функции

```
int uv_fs_stat(uv_loop_t* loop, uv_fs_t* req, const char* path, uv_fs_cb cb)
int uv_fs_fstat(uv_loop_t* loop, uv_fs_t* req, uv_file file, uv_fs_cb cb)
int uv_fs_lstat(uv_loop_t* loop, uv_fs_t* req, const char* path, uv_fs_cb cb)
```

Первая функция uv_fs_stat, возвращает статистику по файлу (статус файла). Отличие uv_fs_lstat в том, что 
если указанный файл является ссылкой, то будет возвращена статистика непосредственно по файлу-ссылке, 
а не по файлу, на который ссылка ссылается. Функция uv_fs_fstat получает в качестве аргумента не строку – имя файла, -  а 
уже открытый файл типа uv_file – кроссплатформенная реализация дескриптора файлов.
Статистика будет в поле statbuf запроса в колбэке. Поле statbuf имеет тип uv_stat_t, поля которого несут информацию 
о файле

```
typedef struct {
    uint64_t st_dev;
    uint64_t st_mode;
    uint64_t st_nlink;
    uint64_t st_uid;
    uint64_t st_gid;
    uint64_t st_rdev;
    uint64_t st_ino;
    uint64_t st_size;
    uint64_t st_blksize;
    uint64_t st_blocks;
    uint64_t st_flags;
    uint64_t st_gen;
    uv_timespec_t st_atim;
    uv_timespec_t st_mtim;
    uv_timespec_t st_ctim;
    uv_timespec_t st_birthtim;
} uv_stat_t;
```

Получение статистики довольно простая задача. Единственная проблема – перевод времени в печатный формат. В коде программы указано, как это сделать.

```
#include <uv.h>
#include <stdio.h>
#include <fcntl.h>
#include <sys/stat.h>
#ifdef _WIN32
#include <conio.h>
#define wait() _getch()
#define S_IFBLK   0
#define S_IFSOCK  0    
#define	S_ISFIFO(mode) (((mode) & S_IFMT) == S_IFMT)
#define	S_ISDIR(mode)  (((mode) & S_IFMT) == S_IFDIR)
#define	S_ISREG(mode)  (((mode) & S_IFMT) == S_IFREG)
#define	S_ISLNK(mode)  (((mode) & S_IFMT) == S_IFLNK)
#define	S_ISSOCK(mode) (((mode) & S_IFMT) == S_IFSOCK)
#define	S_ISCHR(mode)  (((mode) & S_IFMT) == S_IFCHR)
#define	S_ISBLK(mode)  (((mode) & S_IFMT) == S_IFBLK)
#else
#define wait() scanf("1");
#endif

uv_loop_t* loop;
uv_fs_t stat_req;

void stat_cb(uv_fs_t*);

const char *filename = "C:/c/somefile.txt";

int main(int argc, char **argv) {
	int r;

	loop = uv_default_loop();
	uv_fs_stat(loop, &stat_req, filename, stat_cb);

	uv_run(loop, UV_RUN_DEFAULT);
	return 0;
}

void stat_cb(uv_fs_t* req) {
	uv_stat_t stat;
	struct tm * timeinfo;
	char buff[20];

	stat = req->statbuf;

	//number of hard links to file
	printf("st_nlink %d\n", stat.st_nlink);
	//blocksize
	printf("st_blksize %d\n", stat.st_blksize);
	//number of blocks allocated
	printf("st_blocks %d\n", stat.st_blocks);
	//st_atime - time of last access
	timeinfo = localtime(&stat.st_atim);
	strftime(buff, 20, "%b %d %H:%M", timeinfo);
	printf("st_atime: %s\n", buff);
	//st_mtime - time of last modification
	timeinfo = localtime(&stat.st_mtim);
	strftime(buff, 20, "%b %d %H:%M", timeinfo);
	printf("st_mtime: %s\n", buff);
	//st_ctime - time of last status change
	timeinfo = localtime(&stat.st_ctim);
	strftime(buff, 20, "%b %d %H:%M", timeinfo);
	printf("st_ctime: %s\n", buff);

	wait();
}
```

Небольшое дополнение. В самом начале программы идёт набор макросов. Это кроссплатформенная реализация стандартных POSIX макросов для определения типа файлов. Эту информация можно получить с использованием функций чтения содержимого папки 
(см. предыдущий раздел). Для работы программы эти макросы не нужны.

