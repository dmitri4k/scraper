## Оператор Switch

Рассмотрим пример из темы "ветвления". Программа выводит название дня недели по порядковому номера

Этот код состоит из семи идущих друг за другом операторов if. Его код можно упростить с помощью оператора switch

Оператор switch принимает в качестве аргумента число, и в зависимости от его значения выполняет те или иные команды.

Если значение переменной не соответствует ни одному case, то выполняется default ветвь. Она может отсутствовать, тогда вообще ничего не выполняется.

В примере выше каждая ветвь оканчивается оператором break. Это важно. Когда компьютер видит оператор break, он выходит из оператора switch. Если бы он отсутствовал, то программа "провалилась" бы дальше, и стала выполнять следующие ветви.

Введите значение, например 3, и вы увидите, что программа выведет 

WednesdayThursdayFridaySaturday

то есть все ветви, после найденной.

Операторы каждой из ветвей могут быть обрамлены фигурными скобками (и так даже лучше).
Тогда каждая из ветвей будет отдельным блоком, в котором можно определять свои переменные.
Пример программы, которая запрашивает у пользователя число, оператор и второе число и выполняет действие.

Если ввести 

1 + 2

то будет выведен результат операции 1 + 2 = 3

Хочу обратить внимание, что литеры типа '+' и т.п. воспринимаются в качестве чисел, поэтому их можно использовать в операторе switch.

В этой программе использовалась функция exit из библиотеки stdlib. Функция останавливает работу программы и возвращает результат её работы. Если возвращается истина (ненулевое значение), то это значит, что программа была выполнена с ошибкой.

Ветвь default может располагаться в любом месте, не обязательно в конце. Этот код также будет нормально работать

default здесь также нуждается в операторе break, как и другие ветви, иначе произойдёт сваливание вниз. Несмотря на то, что так можно писать, это плохой стиль программирования. Ветвь default
логически располагается в конце, когда других вариантов больше нет.

Возможные значения аргумента оператора switch могут располагаться в любом порядке, но должны быть константными значеними. Это значит, что следующий код не заработает

![mail.png](../images/mail.png)
