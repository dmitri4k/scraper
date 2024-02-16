## Обзор мьютексов

Рассмотрим простой пример: несколько потоков обращаются к одной общей переменной. Часть потоков 
эту переменную увеличивают (plus потоки), а часть уменьшают на единицу (minus потоки). Число plus и minus 
потоков равно. Таким образом, мы ожидаем, что к концу работы программы значение исходной переменной будет прежним.

```
#include <stdio.h>
#include <stdlib.h>
#include <conio.h>
#include <pthread.h>

static int counter = 0;

void* minus(void *args) {
	int local;

	local = counter;
	printf("min %d\n", counter);
	local = local - 1;
	counter = local;	
	return NULL;
}

void* plus(void *args) {
	int local;

	local = counter;
	printf("pls %d\n", counter);
	local = local + 1;
	counter = local;
	return NULL;
}

#define NUM_OF_THREADS 100

int main() {
	pthread_t threads[NUM_OF_THREADS];
	size_t i;

	printf("counter = %d\n", counter);
	for (i = 0; i < NUM_OF_THREADS/2; i++) {
		pthread_create(&threads[i], NULL, minus, NULL);
	}
	for (; i < NUM_OF_THREADS; i++) {
		pthread_create(&threads[i], NULL, plus, NULL);
	}
	for (i = 0; i < NUM_OF_THREADS; i++) {
		pthread_join(threads[i], NULL);
	}
	printf("counter = %d", counter);
	_getch();
	return 0;
}
```

Если выполнить код, то он будет возвращать различные значения. Чаще всего они не будут равны нулю. Разберёмся, почему так происходит.
Рассмотрим код функций, которые выполняются в отдельных потоках



```
void* minus(void *args) {
	int local;

	local = counter;
	printf("min %d\n", counter);
	local = local - 1;
	counter = local;	
	return NULL;
}
```

Во-первых, у нас имеется локальная переменная local. Во вторых, используется тяжёлая и медленная функция printf. В тот момент, когда мы 
присваиваем локальной переменной значение counter, другой поток может в то же самое время взять это значение и поменять.

Для простоты рассмотрим 4 потока – два plus и два minus

Это один из возможных сценариев развития событий. Очевидно, что могут быть значения от минус 2 до плюс 2. Какой из них будет выполнен, в общем случае не известно.

Проблема заключается в том, что у нас имеется несинхронизированный доступ к общему ресурсу. Мы бы хотели сделать так, чтобы на время 
работы с ресурсом (всё тело функций minus и plus) к ним имел доступ только один поток, а остальные ждали, пока ресурс освободится.
Это так называемое mutual exclusion – взаимное исключение, случай, когда необходимо удостовериться в том, что два (и более…) 
конкурирующих потока не находятся в критической секции кода одновременно.

В библиотеке pthreads один из методов разрешить эту ситуацию – это мьютексы. Мьютекс – это объект, который может находиться в двух состояниях. Он либо заблокирован (занят, залочен, захвачен) каким-то потоком, либо свободен.
Поток, который захватил мьютекс, работает с участком кода. Остальные потоки, когда достигают мьютекса, ждут его разблокировки. Разблокировать мьютекс может только тот поток, который его захватил. Обычно освобождение занятого мьютекса происходит после исполнения критичного к совместному доступу участка кода.

## Порядок использования мьютексов

Мьютекс – это экземпляр типа pthread_mutex_t. Перед использованием необходимо инициализировать 
мьютекс функцией pthread_mutex_init

```
int pthread_mutex_init(pthread_mutex_t *mutex, const pthread_mutexattr_t *attr);
```

где первый аргумент – указатель на мьютекс, а второй – аттрибуты мьютекса. Если указан NULL, то используются атрибуты по умолчанию. 
В случае удачной инициализации мьютекс переходит в состояние «инициализированный и свободный», а функция возвращает 0. 
Повторная инициализация инициализированного мьютекса приводит к неопределённому поведению.

Если мьютекс создан статически и не имеет дополнительных параметров, то он может быть инициализирован с помощью макроса 
PTHREAD_MUTEX_INITIALIZER

После использования мьютекса его необходимо уничтожить с помощью функции

```
int pthread_mutex_destroy(pthread_mutex_t *mutex);
```

В результате функция возвращает 0 в случае успеха или может возвратить код ошибки.

После создания мьютекса он может быть захвачен с помощью функции

```
int pthread_mutex_lock(pthread_mutex_t *mutex);
```

После этого участок кода становится недоступным остальным потокам – их выполнение блокируется до тех пор, пока мьютекс не будет освобождён. Освобождение должен провести поток, заблокировавший мьютекс, вызовом

```
int pthread_mutex_unlock(pthread_mutex_t *mutex);
```

Перейдём к реализации. Для начала сделаем глобальный объект мьютекс, доступный всем потокам.

Код

```
#include <stdio.h>
#include <stdlib.h>
#include <conio.h>
#include <pthread.h>

static int counter = 0;
pthread_mutex_t mutex;

void* minus(void *args) {
	int local;
	//Блокировка: теперь к ресурсам имеет доступ только один
	//поток, который владеет мьютексом. Он же единственный, 
	//кто может его разблокировать
	pthread_mutex_lock(&mutex);
		local = counter;
		printf("min %d\n", counter);
		local = local - 1;
		counter = local;
	pthread_mutex_unlock(&mutex);
	return NULL;
}

void* plus(void *args) {
	int local;
	pthread_mutex_lock(&mutex);
		local = counter;
		printf("pls %d\n", counter);
		local = local + 1;
		counter = local;
	pthread_mutex_unlock(&mutex);
	return NULL;
}

#define NUM_OF_THREADS 100

int main() {
	pthread_t threads[NUM_OF_THREADS];
	size_t i;

	printf("counter = %d\n", counter);
	//Инициализация мьютекса
	pthread_mutex_init(&mutex, NULL);
	for (i = 0; i < NUM_OF_THREADS/2; i++) {
		pthread_create(&threads[i], NULL, minus, NULL);
	}
	for (; i < NUM_OF_THREADS; i++) {
		pthread_create(&threads[i], NULL, plus, NULL);
	}
	for (i = 0; i < NUM_OF_THREADS; i++) {
		pthread_join(threads[i], NULL);
	}
	//Уничтожение мьютекса
	pthread_mutex_destroy(&mutex);
	printf("counter = %d", counter);
	_getch();
	return 0;
}
```

Заметьте, при использовании мьютекса исполнение защищённого участка кода происходит последовательно всеми потоками, а не параллельно. Порядок доступа отдельных потоков не определён.
Напишем теперь реализацию, в которой мьютекс будет передаваться в качестве параметра функции. Для начала, определим новый тип данных

```
typedef struct use_mutex_tag {
	pthread_mutex_t mutex;
} use_mutex_t;
```

И перепишем фунции

```
void* minus(void *args) {
	int local;
	use_mutex_t *arg = (use_mutex_t*) args;
	pthread_mutex_lock(&(arg->mutex));
	local = counter;
	printf("min %d\n", counter);
	local = local - 1;
	counter = local;
	pthread_mutex_unlock(&(arg->mutex));
	return NULL;
}
```

Весь код

```
#include <stdio.h>
#include <stdlib.h>
#include <conio.h>
#include <pthread.h>

static int counter = 0;

typedef struct use_mutex_tag {
	pthread_mutex_t mutex;
} use_mutex_t;

void* minus(void *args) {
	int local;
	use_mutex_t *arg = (use_mutex_t*) args;
	pthread_mutex_lock(&(arg->mutex));
	local = counter;
	printf("min %d\n", counter);
	local = local - 1;
	counter = local;
	pthread_mutex_unlock(&(arg->mutex));
	return NULL;
}

void* plus(void *args) {
	int local;
	use_mutex_t *arg = (use_mutex_t*) args;
	pthread_mutex_lock(&(arg->mutex));
	local = counter;
	printf("pls %d\n", counter);
	local = local + 1;
	counter = local;
	pthread_mutex_unlock(&(arg->mutex));
	return NULL;
}

#define NUM_OF_THREADS 100

int main() {
	pthread_t threads[NUM_OF_THREADS];
	size_t i;
	use_mutex_t param;

	printf("counter = %d\n", counter);
	pthread_mutex_init(&(param.mutex), NULL);
	for (i = 0; i < NUM_OF_THREADS/2; i++) {
		pthread_create(&threads[i], NULL, minus, &param);
	}
	for (; i < NUM_OF_THREADS; i++) {
		pthread_create(&threads[i], NULL, plus, &param);
	}
	for (i = 0; i < NUM_OF_THREADS; i++) {
		pthread_join(threads[i], NULL);
	}
	pthread_mutex_destroy(&(param.mutex));
	printf("counter = %d", counter);
	_getch();
	return 0;
}
```

Хочется обратить внимание, что мьютекс один на всех. Если бы у каждого потока был свой собственный мьютекс, то они бы не блокировали работу друг друга. Например, этот код будет работать неправильно

```
#include <stdio.h>
#include <stdlib.h>
#include <conio.h>
#include <pthread.h>

static int counter = 0;

void* minus(void *args) {
	int local;
	pthread_mutex_t mutex;
	pthread_mutex_init(&mutex, NULL);
	pthread_mutex_lock(&mutex);
	local = counter;
	printf("min %d\n", counter);
	local = local - 1;
	counter = local;
	pthread_mutex_unlock(&mutex);
	pthread_mutex_destroy(&mutex);
	return NULL;
}

void* plus(void *args) {
	int local;
	pthread_mutex_t mutex;
	pthread_mutex_init(&mutex, NULL);
	pthread_mutex_lock(&mutex);
	local = counter;
	printf("pls %d\n", counter);
	local = local + 1;
	counter = local;
	pthread_mutex_unlock(&mutex);
	pthread_mutex_destroy(&mutex);
	return NULL;
}

#define NUM_OF_THREADS 100

int main() {
	pthread_t threads[NUM_OF_THREADS];
	size_t i;

	printf("counter = %d\n", counter);
	for (i = 0; i < NUM_OF_THREADS/2; i++) {
		pthread_create(&threads[i], NULL, minus, NULL);
	}
	for (; i < NUM_OF_THREADS; i++) {
		pthread_create(&threads[i], NULL, plus, NULL);
	}
	for (i = 0; i < NUM_OF_THREADS; i++) {
		pthread_join(threads[i], NULL);
	}
	printf("counter = %d", counter);
	_getch();
	return 0;
}
```

Остановимся подробнее на функциях для работы с мьютексами

Функция может упасть с ошибкой

pthread_mutex_destroy  может вернуть следующие ошибки

pthread_nutex_lock возвращает ошибки

pthread_mutex_lock и pthread_mutex_unlock могут вылететь с ошибками

