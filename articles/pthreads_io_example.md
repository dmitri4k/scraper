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

Каждое задание будет вытаскивать новую ссылку до тех пор, пока есть что снимать со стека. После этого поток закончит работу.

При этом результат работы остаётся неопределённым, так как мы не можем оценить время скачивания страницы. Диаграмма (a) показывает ситуацию, когда два потока скачивают одинаковое число страниц. Диаграммы (b) и (c) ситуацию, когда потоки выбирают задания из стека. Из-за разного порядка заданий мы получим различное время работы.

Сама функция, которая обращается к серверу и сохраняет ответ

Здесь для простоты ip адрес забит в код. Его можно находить динамически, например, так

Результат оказался очень интересным. Для тяжёлых задач с нулевыми IO минимум времени выполнения был при числе потоков, равном числу ядер. В случае малой нагрузки на процессор и большого числа IO операций подсчитать оптимальное число потоков затруднительно, так как на первый план выходят уже совершенно другие параметры.
Скорость работы замерялась для двух разных провайдеров. Двухъядерный работает в два раза быстрее, потому что у него «интернет быстрее и канал ширше». В общем и целом, поведение при росте числа потоков одинаковое и не зависит от железа: чем больше потоков, тем лучше. Очевидно, что есть предел: когда время, затрачиваемое на переключение между задачами, будет сравнимо со временем, необходимым для обработки запросов и выделения ресурсов, тогда дальнейший рост числа потоков будет только замедлять работу.

## Вывод

Код программы

![mail.png](../images/mail.png)
