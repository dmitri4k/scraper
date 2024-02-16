## Скачивание данных и выбор числа потоков

Второй пример полная противоположность первому – он не требует ресурсов процессора и основное время ожидает данные, которые к нему придут. 
Напишем программу, которая скачивает html страницы с известного сайта.

Время скачивания одного файла состоит из времени обращения к серверу, времени, необходимого для получения ответа от сервера и времени, необходимого для записи файла на диск. 
Выделение ресурсов занимает много меньше: если средний запрос/ответ от сервера составляет для нашего примера 400 мс., то выделение памяти под все массивы, создание сокетов, 
выделения ресурсов под потоки и пр. 10 мс.

Будем проводить измерение несколько раз, выбросив значения с максимальным отклонением. Далее найдём среднее время выполнения для различного числа потоков.

## Распределение нагрузки

В прошлом примере распределение было очень простым – каждому поровну. Такой подход работал, потому что количество операций для каждой из подзадач (почти) 
одинаковое, его даже можно подсчитать.

В теперешнем случае каждый из потоков ждёт неопределённое время. Пусть нужно скачать 20 страниц в 2 потока. Первый скачал 10 страниц по 150 мс. на каждую. Всего 1,5 сек. 
Второй поток скачивает одну страницу за 3 сек. Почему это происходит не важно. Может быть, сервер сильно нагружен, или страница оказалась большой. Важно то, что первый поток простаивает в это время. 
То есть, завершив свою работу, первый поток мог бы ещё работать, так как задачи ещё не выполнены.

Таким образом, нам необходим некоторый источник заданий, объект, который будет поставлять ссылки на скачивание, пока они ещё есть. Потоки в данном случае выступают потребителями 
ресурсов. В качестве источника может выступать, например, элементарная реализация стека, хранящего пару строк.

```
typedef struct inoutPair_tag {
	const char *link;
	const char *out;
} inoutPair_t;

typedef struct pStack_tag {
	pthread_mutex_t mut;
	inoutPair_t *data;
	size_t size;
	size_t limit;
} pStack_t;

pStack_t* createpStack(size_t limit) {
	pStack_t *tmp = (pStack_t*) malloc(sizeof(pStack_t));

	tmp->limit = limit;
	tmp->data = (inoutPair_t*) malloc(sizeof(inoutPair_t)* tmp->limit);
	tmp->size = 0;
	pthread_mutex_init(&tmp->mut, NULL);

	return tmp;
}

void ppush(pStack_t *s, const char *link, const char *out) {
	pthread_mutex_lock(&s->mut);
	s->data[s->size].link = link;
	s->data[s->size].out = out;
	s->size++;
	pthread_mutex_unlock(&s->mut);
}

inoutPair_t* ppop(pStack_t *s) {
	inoutPair_t *out = NULL;
	pthread_mutex_lock(&s->mut);
	if (s->size != 0) {
		s->size--;
		out = &(s->data[s->size]);
	}
	pthread_mutex_unlock(&s->mut);
	return out;
}

void deletepStack(pStack_t **s) {
	free((*s)->data);
	pthread_mutex_destroy(&(*s)->mut);
	free(*s);
	*s = NULL;
}
```

Каждое задание будет вытаскивать новую ссылку до тех пор, пока есть что снимать со стека. После этого поток закончит работу.

```
void* downloadTask2(void *args) {
	pStack_t *s = (pStack_t*) args;
	do {
		inoutPair_t *p = ppop(s);
		if (p == NULL) {
			break;
		}
		download(p->link, p->out);
	} while (1);
	return 0;
}
```

При этом результат работы остаётся неопределённым, так как мы не можем оценить время скачивания страницы. Диаграмма (a) показывает ситуацию, когда два потока скачивают одинаковое число страниц. Диаграммы (b) и (c) ситуацию, когда потоки выбирают задания из стека. Из-за разного порядка заданий мы получим различное время работы.

Сама функция, которая обращается к серверу и сохраняет ответ

```
//Генерируем строку для минимального GET запроса
char* genName(const char *src, char *out) {
	int len = strlen(src);
	strcpy(out, "GET ");
	strcpy(&out[4], src);
	strcpy(&out[4 + len], " HTTP/1.1\r\nHost: learnc.info\r\n\r\n");
	//out[len + 42] = 0;
	return out;
};

int download(const char *link, const char *out) {
	WSADATA wsa;
	SOCKET sock;
	struct sockaddr_in server;
	char message[2048];
	char server_reply[REPLY];
	ssize_t bytes_read;
	FILE *outFile = NULL;

	if (WSAStartup(MAKEWORD(2, 2), &wsa) != 0) {
		printf("Failed. Error Code : %d", WSAGetLastError());
		exit(1);
	}

	sock = socket(AF_INET, SOCK_STREAM, 0);
	if (sock == INVALID_SOCKET) {
		printf("Could not create socket : %d", WSAGetLastError());
	}

	server.sin_addr.s_addr = inet_addr("89.111.176.202");
	server.sin_family = AF_INET;
	server.sin_port = htons(80);

	if (connect(sock, (struct sockaddr*) &server, sizeof(server)) < 0) {
		puts("connect error");
		_getch();
		exit(1);
	}

	genName(link, message);
	if (send(sock, message, strlen(message), 0) < 0) {
		puts("Send failed");
		_getch();
		exit(1);
	}

	outFile = fopen(out, "wt");
	do {
		bytes_read = recv(sock, server_reply, REPLY, 0);
		if (bytes_read == SOCKET_ERROR) {
			perror("error recieving data");
			exit(1);
		}
		if (bytes_read > 0) {
			fprintf(outFile, "%.*s", bytes_read, server_reply);
		}
	} while (bytes_read == REPLY);

	closesocket(sock);
	fclose(outFile);
	//printf("[OK]\n");
	return 0;
}
```

Здесь для простоты ip адрес забит в код. Его можно находить динамически, например, так

```
void getIpByHost(const char *hostname, char **out) {
	WSADATA wsaData;
	struct hostent* hn = NULL;
	struct in_addr addr;
	WSAStartup(MAKEWORD(2, 2), &wsaData);
	hn = gethostbyname(hostname);
	if (hn != NULL) {
		int i = 0;
		while (hn->h_addr_list[i] != NULL) {
			addr.s_addr = hn->h_addr_list[i];
			strcpy(out[i], inet_ntoa(addr));
			i++;
		}
	}
	return;
}
```

Результат оказался очень интересным. Для тяжёлых задач с нулевыми IO минимум времени выполнения был при числе потоков, равном числу ядер. В случае малой нагрузки на процессор и большого числа IO операций подсчитать оптимальное число потоков затруднительно, так как на первый план выходят уже совершенно другие параметры.
Скорость работы замерялась для двух разных провайдеров. Двухъядерный работает в два раза быстрее, потому что у него «интернет быстрее и канал ширше». В общем и целом, поведение при росте числа потоков одинаковое и не зависит от железа: чем больше потоков, тем лучше. Очевидно, что есть предел: когда время, затрачиваемое на переключение между задачами, будет сравнимо со временем, необходимым для обработки запросов и выделения ресурсов, тогда дальнейший рост числа потоков будет только замедлять работу.

## Вывод

Код программы

