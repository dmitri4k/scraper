Библиотека string.h предоставляет функции для работы со строками (zero-terminated strings) в си, а также несколько функций для работы с массивами, которые сильно упрощают 
жизнь. Рассмотрим функции с примерами.

## Копирование

Копирует участок памяти из source в destination, размером num байт. Функция очень полезная, с помощью неё, например, можно скопировать объект или перенести участок массива, вместо поэлементного копирования. Функция производит бинарное копирование, тип данных не важен. Например, удалим элемент из массива и сдвинем остаток массива влево.

Функция меняет местами две переменные

Здесь хотелось бы отметить, что функция выделяет память под временную переменную. Это дорогостоящая операция. Для улучшения производительности стоит передавать функции временную переменную, которая будет создана один раз.

Копирует блок памяти из source в destination размером num байт с той разницей, что области могут пересекаться. Во время копирования используется промежуточный буфер, который предотвращает перекрытие областей.

Пример взят из cplusplus.com

Копирует одну строку в другую, вместе с нулевым символом. Также возвращает указатель на destination.

Можно копировать и по-другому

Копирует только num первых букв строки. 0 в конец не добавляется автоматически. При копировании из строки в эту же строку части не должны пересекаться (при пересечении используйте memmove)

## Конкатенация строк

Добавляет в конец destination строку source, при этом затирая первым символом нулевой. Возвращает указатель на destination.

Добавляет в конец строки destination num символов второй строки. В конец добавляется нулевой символ.

## Сравнение строк

Возвращает 0, если строки равны, больше нуля, если первая строка больше, меньше нуля, если первая строка меньше. Сравнение строк происходит посимвольно, сравниваются численные значения. Для сравнения строк на определённом языке используется strcoll

сравнение строк по первым num символам

Пример - сортировка массива строк по первым трём символам

Трансформация строки в соответствии с локалью. В строку destination копируется num трансформированных символов строки source и возвращается её длина. Если num == 0 и destination == NULL, то возвращается просто длина строки.

## Поиск

Проводит поиск среди первых num байтов участка памяти, на который ссылается ptr, первого вхождения значения value, которое трактуется как unsigned char. Возвращает указатель на найденный элемент, либо NULL.

Возвращает указатель на место первого вхождения character в строку str. Очень похожа на функцию memchr, но работает со строками, а не с произвольным блоком памяти.

Возвращает адрес первого вхождения любой буквы из строки str2 в строке str1. Если ни одно включение не найдено, то возвратит длину строки.

Пример - найдём положение всех гласных в строке

Здесь обратите внимание на строку i++ после printf. Если бы её не было, то strcspn возвращал бы всегда 0, потому что в начале строки стояла бы гласная, и произошло зацикливание.

Для решения этой задачи гораздо лучше подошла функция, которая возвращает указатель на первую гласную.

Функция очень похожа на strcspn, только возвращает указатель на первый символ из строки str1, который есть в строке str2.
Выведем все гласные в строке

Возвращает указатель на последнее вхождение символа в троку.

Возвращает длину куска строки str1, начиная от начала, который состоит только из букв строки str2.

Пример - вывести число, которое встречается в строке.

Возвращает указатель на первое вхождение строки str2 в строку str1.

Разбивает строку на токены. В данном случае токенами считаются последовательности символов, разделённых символами, входящими в группу разделителей.

## Ещё функции

Самая популярная функция

Возвращает длину строки - число символов от начала до первого вхождения нулевого.

## Конверсия число-строка и строка-число.

Переводит строку в целое

Переводит строку в число типа double.

Переводит строку в число типа long

Все функции такого рода имеют название XtoY, где X  и Y - сокращения типов. A обозначает ASCII. Соответственно, имеется обратная функция itoa (больше нет:)).
Таких функций в библиотеке stdlib.h очень много, все их рассматривать не хватит места.

## Форматированный ввод и вывод в буфер

Можно также выделить две функции sprintf и sscanf. Они отличаются от printf и scanf тем, что выводят данные и считывают их из буфера. Это, например, позволяет переводить строку в число и число в строку. Например

Вообще, работа со строками - задача более глобальная, чем можно себе представить. Так или иначе, практически каждое приложение связано с обработкой текста.

## Работа с локалью

Устанавливает локаль для данного приложения. Если locale равно NULL, то setlocale может быть использована для получения текущей локали.

Локаль хранит информацию о языке и регионе, специфичную для работы функций ввода, вывода и трансформации строк.
Во время работы приложения устанавливается локаль под названием "C", которая совпадает с настройками локали по умолчанию. Эта локаль содержит минимум информации, и работа программы максимально предсказуема. Локаль "C" также называется "".
Константы category определяют, на что воздействует изменение локали.

Строка locale содержит имя локали, например "En_US" или "cp1251"

![mail.png](../images/mail.png)
