## Бинарные файлы

Текстовые файлы хранят данные в виде текста (sic!). Это значит, что если, например, мы записываем целое число 12345678 в файл, то 
записывается 8 символов, а это 8 байт данных, несмотря на то, что число помещается в целый тип. Кроме того, вывод и ввод данных является форматированным, то 
есть каждый раз, когда мы считываем число из файла или записываем в файл происходит трансформация числа в строку или обратно. Это затратные операции, которых можно избежать.

Текстовые файлы позволяют хранить информацию в виде, понятном для человека. Можно, однако, хранить данные непосредственно в бинарном виде. Для этих целей используются 
бинарные файлы.

Выполните программу и посмотрите содержимое файла output.bin. Число, которое ввёл пользователь записывается в файл непосредственно в бинарном виде. Можете 
открыть файл в любом редакторе, поддерживающем представление в шестнадцатеричном виде (Total Commander, Far)   и убедиться в этом.

Запись в файл осуществляется с помощью функции

Функция возвращает число удачно записанных элементов. В качестве аргументов принимает указатель на массив, размер одного элемента, число элементов и указатель на файловый поток. 
Вместо массив, конечно, может быть передан любой объект.

Запись в бинарный файл объекта похожа на его отображение: берутся данные из оперативной памяти и пишутся как есть. Для считывания используется функция fread

Функция возвращает число удачно прочитанных элементов, которые помещаются по адресу ptr. Всего считывается count элементов по size байт. Давайте теперь считаем наше число 
обратно в переменную.

## fseek

Одной из важных функций для работы с бинарными файлами является функция fseek

Эта функция устанавливает указатель позиции, ассоциированный с потоком, на новое положение. Индикатор позиции указывает, на каком месте в файле мы остановились. 
Когда мы открываем файл, позиция равна 0. Каждый раз, записывая байт данных, указатель позиции сдвигается на единицу вперёд.

fseek принимает в качестве аргументов указатель на поток и сдвиг в offset байт относительно origin. origin  может принимать три значения

В случае удачной работы функция возвращает 0.

Дополним наш старый пример: запишем число, затем сдвинемся указатель на начало файла и прочитаем его.

Вместо этого можно также использовать функцию rewind, которая перемещает индикатор позиции в начало.

В си определён специальный тип fpos_t, который используется для хранения позиции индикатора позиции в файле.

Функция

используется для того, чтобы назначить переменной pos текущее положение. Функция

используется для перевода указателя в позицию, которая хранится в переменной pos. Обе функции в случае удачного завершения возвращают ноль.

возвращает текущее положение индикатора относительно начала файла. Для бинарных файлов - это число  байт, для текстовых не определено (если текстовый файл состоит из однобайтовых 
символов, то также число байт).

Рассмотрим пример: пользователь вводит числа. Первые 4 байта файла: целое, которое обозначает, сколько чисел было введено. После того, как пользователь прекращает вводить числа, 
мы перемещаемся в начало файла и записываем туда число введённых элементов.

Вторая программа сначала считывает количество записанных чисел, а потом считывает и выводит числа по порядку.

## Примеры

1. Имеется бинарный файл размером 10*sizeof(int) байт. Пользователь вводит номер ячейки, после чего в неё записывает число. После каждой операции выводятся все числа. Сначала пытаемся открыть файл в режиме чтения и записи. Если это не удаётся, то пробуем создать файл, если удаётся создать файл, то повторяем попытку открыть файл для чтения и записи.

2. Пишем слова в бинарный файл. Формат такой - сначало число букв, потом само слово без нулевого символа. Ели длина слова равна нулю, то больше слов нет.
Сначала запрашиваем слова у пользователя, потом считываем обратно.

3. Задача - считать данные из текстового файла и записать их в бинарный. Для решения зачи создадим функцию обёртку. Она будет принимать имя файла, режим доступа, 
функцию, которую необходимо выполнить, если файл был удачно открыт и аргументы этой функции. Так как аргументов может быть много  и они могут быть разного типа,
то их можно передавать в качестве указателя на структуру. После выполнения функции файл закрывается. Таким образом, нет необходимости думать об освобождении ресурсов.

4. Функция saveInt32Array позволяет сохранить массив типа int32_t в файл. Обратная ей loadInt32Array считывает массив обратно.
Функция loadInt32Array сначала инициализирует переданный ей массив, поэтому мы должны передавать указатель на указатель; кроме того,
она записывает считанный размер массива в переданный параметр size, из-за чего он передаётся как указатель.

5. Создание таблицы поиска. Для ускорения работы программы вместо вычисления функции можно произвести сначала вычисление значений функции
на интервале с определённой точностью, после чего брать значения уже из таблицы. Программа сначала производит табулирование функции с заданными параметрами и сохраняет его в файл,
затем подгружает предвычисленный массив, который уже используется для определения значений. В этой программе все функции возвращают переменную типа Result,
которая хранит номер ошибки. Если функция отработала без проблем, то она возвращает Ok (0).

6. У нас имеются две структуры. Первая PersonKey хранит логин, пароль, id пользователя и поле offset. Вторая структура PersonInfo хранит имя и фамилию пользователя и его
возраст. Первые структуры записываются в бинарный файл keys.bin, вторые структуры в бинарный файл values.bin. Поле offset определяет положение соответствующей информации
о пользователе во втором файле. Таким образом, получив PersonKey из первого файла, по полю offset можно извлечь из второго файла связанную с данным ключом информацию.

Зачем так делать? Это выгодно в том случае, если структура PersonInfo имеет большой размер. Извлекать массив маленьких структур из
файла не накладно, а когда нам понадобится большая структура, её можно извлечь по уже известному адресу в файле.

![mail.png](../images/mail.png)
