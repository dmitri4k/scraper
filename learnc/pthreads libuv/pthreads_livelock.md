## Livelock

Лайвлок (livelock) – ситуация, при которой два или более потока не могут выполнять полезной работы по 
причине борьбы за общий ресурс. От дедлока 
ситуация отличается тем, что потоки не просто ждут, но безуспешно пытаются выйти из состояния ступора (поэтому live, а не dead).

Самый простой пример – два вежливых сотрудника, которые идут по коридору навстречу друг другу. В тот момент, когда они встречаются, 
то первый отходит вправо от себя, второй, в свою очередь, отходит влево от себя. Они опять друг напротив друга. Первый тогда отходит влево, 
а второй вправо, но они опять оказываются друг у друга на пути. В реальной жизни такая ситуация быстро исправится, но (глупый) компьютер 
может делать это бесконечно.

Давайте рассмотрим нашу задачу обедающих философов. Начнём с ситуации с дедлоком, но попробуем разрешить её другим способом. Изменим 
алгоритм поведения философов.

Первый философ, вежливый, берёт левую вилку. В том случае, если правая вилка занята, то он кладёт левую вилку обратно и немного ждёт, после 
чего опять пытается взять левую вилку.

Пусть первый взял левую вилку. Второй, третий, четвёртый и пятый сделали то же самое. Первый уже не может взять правую (которая является левой у второго философа), чешет затылок  и решает положить вилку обратно. Но таким же образом поступают и все остальные философы. Первый кладёт левую вилку обратно, так поступают и все остальные. Теперь все философы сидят без вилок. Первый философ берёт левую вилку, второй берёт левую вилку и т.д.
Рассмотрим реализацию такой ситуации:

```
#include <pthread.h>
#include <stdlib.h>
#include <stdio.h>

#ifdef WIN32
#include <Windows.h>
#define sleep(X) Sleep(X)
#define wait() _getch()
#else
#define sleep(X) sleep(X)
#define wait() scanf(1)
#endif

#define PHT_SIZE 5

typedef struct philosopher_tag {
	const char *name;
	unsigned left_fork;
	unsigned right_fork;
} philosopher_t;

typedef struct table_tag {
	pthread_mutex_t forks[PHT_SIZE];
} table_t;

typedef struct philosopher_args_tag {
	const philosopher_t *philosopher;
	const table_t *table;
} philosopher_args_t;

void init_philosopher(philosopher_t *philosopher, 
					  const char *name, 
					  unsigned left_fork, 
					  unsigned right_fork) {
	philosopher->name = name;
	philosopher->left_fork = left_fork;
	philosopher->right_fork = right_fork;
}

void init_table(table_t *table) {
	size_t i;
	for (i = 0; i < PHT_SIZE; i++) {
		pthread_mutex_init(&table->forks[i], NULL);
	}
}

void* eat(void *args) {
	philosopher_args_t *arg = (philosopher_args_t*) args;
	const philosopher_t *philosopher = arg->philosopher;
	const table_t *table = arg->table;	

	do {
		printf("%s started dinner\n", philosopher->name);

		pthread_mutex_lock(&table->forks[philosopher->left_fork]);
		Sleep(100);
		if (pthread_mutex_trylock(&table->forks[philosopher->right_fork]) == EBUSY) {
			Sleep(100);
			pthread_mutex_unlock(&table->forks[philosopher->left_fork]);
			printf("%s: oh, I am so sorry!\n", philosopher->name);
			continue;
		}

		printf("%s is eating\n", philosopher->name);

		pthread_mutex_unlock(&table->forks[philosopher->right_fork]);
		pthread_mutex_unlock(&table->forks[philosopher->left_fork]);

		printf("%s finished dinner\n", philosopher->name);
	} while (1);
}

void main() {
	pthread_t threads[PHT_SIZE];

	philosopher_t philosophers[PHT_SIZE];
	philosopher_args_t arguments[PHT_SIZE];
	table_t table;

	size_t i;

	init_table(&table);

	init_philosopher(&philosophers[0], "Alice", 0, 1);
	init_philosopher(&philosophers[1], "Bob",   1, 2);
	init_philosopher(&philosophers[2], "Clark", 2, 3);
	init_philosopher(&philosophers[3], "Denis", 3, 4);
	init_philosopher(&philosophers[4], "Eugin", 4, 0);

	for (i = 0; i < PHT_SIZE; i++) {
		arguments[i].philosopher = &philosophers[i];
		arguments[i].table = &table;
	}

	for (i = 0; i < PHT_SIZE; i++) {
		pthread_create(&threads[i], NULL, eat, &arguments[i]);
	}

	for (i = 0; i < PHT_SIZE; i++) {
		pthread_join(threads[i], NULL);
	}

	wait();
}
```

В чём именно здесь проблема, очевидно. Абсолютная одинаковость действий философов не позволяет им выйти из порочного круга. 
Нарушение симметричности действий компенсируется функцией Sleep, которая сглаживает неодинаковость времени выполнения всех 
остальных инструкций.

Для того чтобы решить ситуацию, достаточно сделать так, чтобы действия философов отличались, например, заставив их спать случайное 
время. Добавим новый Sleep после разблокировки мьютекса (после того, как положил левую вилку обратно):

```
void* eat(void *args) {
	philosopher_args_t *arg = (philosopher_args_t*) args;
	const philosopher_t *philosopher = arg->philosopher;
	const table_t *table = arg->table;
	unsigned rand;
	size_t counter = 0;

	do {
		printf("%s started dinner\n", philosopher->name);
		pthread_mutex_lock(&table->forks[philosopher->left_fork]);

		Sleep(1000);

		if (pthread_mutex_trylock(&table->forks[philosopher->right_fork]) == EBUSY) {						
			Sleep(1000);
			printf("%s: oh, I am so sorry!\n", philosopher->name);
			pthread_mutex_unlock(&table->forks[philosopher->left_fork]);
			rand_s(&rand);
			if (rand % 2) {
				Sleep(rand % 5000);
			}					
			continue;
		}

		printf("%s is eating\n", philosopher->name);

		pthread_mutex_unlock(&table->forks[philosopher->right_fork]);
		pthread_mutex_unlock(&table->forks[philosopher->left_fork]);

		printf("%s finished dinner ===============> %d times\n", philosopher->name, ++counter);
	} while (1);
}
```

В данном случае ещё добавлена переменная counter, которая показывает, сколько раз пообедал философ.
Это решение можно назвать спорным, - задача статьи была показать, когда может возникнуть ситуация лайвлока.

