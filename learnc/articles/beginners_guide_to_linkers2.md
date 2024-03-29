# Гид по линкерам для начинающих. Часть 2

## Windows DLL

Хотя общие принципы работы разделяемых библиотек в UNIX и Windows примерно одинаковые, есть ряд деталей, которые по невнимательности могут привести к проблемам.

## Экспортирование символов

Самое главное отличие в том, что в Windows символы не экспортируются автоматически. В UNIX системах все символы по умолчанию видны пользователю разделяемой библиотеки, в то время как на windows программист должен явно указать, что экспортировать.

Есть три способа экспорта символов в DLL (и все три способа могут быть использованы вместе в одной библиотеке).

```
EXPORTS
	my_exported_function
 	my_other_exported_function
```

Если добавить сюда С++, первая опция самая простая, потом что занимается подгонкой имён функций за вас.

## .LIB и другие связанные с библиотекой функции

Это подводи нас ко второму усложнению библиотек в Windows: информация об экспортированных символах, которые должен собрать 
компоновщик хранится не в самой DLL, а в соответствующей .LIB файле.

LIB файл, ассоциированный с DLL файлом, содержит информацию о представленных в DLL символах и их расположении. Программы, которые используют эту DLL, должны получать информацию из .LIB файла чтобы корректно разрешить все символы.

Для того чтобы всё стало ещё запутаннее - .LIB это ещё и расширение статических библиотек.

Существует большое количество файлов, связанный с Windows библиотеками

Линкер возвращает

Входные файлы линкера

Сравните с UNIX. Где информация из всех этих файлов обычно хранится непосредственно в файле библиотеки.

## Импорт символов

Windows, кроме явного декларирования импортируемых символов, также позволяет сделать это непосредственно в коде, с помощью __declspec, что также несколько ускоряет работу.

```
__declspec(dllimport) int function_from_some_dll(int x, double y);
__declspec(dllimport) extern int global_var_from_some_dll;
```

Для Си нормальной практикой является объявление всех функций и глобальных переменных в заголовочном файле. Это приводит к парадоксальной ситуации, когда код внутри DLL, который определяет глобальные переменные и функции, вынужден экспортировать символ, а весь код вне DLL должен импортировать это символ.

Обычно из этой ситуации выходят посредством макроса в заголовочном файле

```
#ifdef EXPORTING_XYZ_DLL_SYMS
#define XYZ_LINKAGE __declspec(dllexport)
#else
#define XYZ_LINKAGE __declspec(dllimport)
#endif

XYZ_LINKAGE int xyz_exported_function(int x);
XYZ_LINKAGE extern int xyz_exported_variable;
```

Если переменная препроцессора EXPORTING_XYZ_DLL_SYMS определена, то будет происходить экспорт, иначе импорт символа.

## Циклические зависимости

Последняя сложность с DLL в том, что Windows требует, чтобы во время компоновки все символы бы разрешены. В UNIX можно присобачить библиотеку с неопределёнными символами, которые линкер никогда не видел, и в этой ситуации любая программа, которая извлекает эту библиотеку обязана его предоставить, или программа не сможет загрузиться. Windows таких слабостей не позволяет.

Для большинства систем это не проблема. Программы зависят от высокоуровневых библиотек, которые в свою очередь зависят от низкоуровневых библиотек, и всё компонуется в обратном порядке – сначала низкоуровневые библиотеки, потом высокоуровневые, потом программа.

Если же существуют циклически зависимости, то всё становится немного более трудоёмким. Если X.DLL нуждается в символе из Y.DLL, а Y.DLL в символе из X.DLL, то мы получаем проблему курицы и яйца; первая собираемая библиотека не сможет разрешить все свои символы.

Windows предоставляет выход из положения, который грубо можно описать так

Конечно, лучшим решением будет сделать так, чтобы циклических зависимостей не было.

## Добавим С++

C++ добавляет кучу дополнительных возможностей в си, многие из которых взаимодействуют с линкером. Поначалу это не было проблемой, так как первые реализации си++ былы скорее фронтэндом к компилятору си, но дальнейшее совершенствование языка привело к тому, что линкер должен был улучшаться

## Перегрузка функций и декорирование имён

Первое нововведение – это перегрузка функций, то есть существование нескольких функций с одним именем и разными типами аргументов (функции имеют разные сигнатуры).

```
int max(int x, int y){
  if (x>y) return x;
  else return y;
}
float max(float x, float y){
  if (x>y) return x;
  else return y;
}
double max(double x, double y){
  if (x>y) return x;
  else return y;
}
```

Очевидно, это добавит проблем – если код обращается к функции max, то к какой именно?

Решение было названо декорированием имён, потому что информация о сигнатуре функции засовывается в переделанное имя функции. Функции с разными аргументами имеют разные имена.

Не буду углубляться в детали (разные реализации на разных платформах делают это по-разному), но вот как примерно выглядит объектный файл (напоминаю о nm – вашем верном друге)

```
Symbols from fn_overload.o:

Name                  Value   Class        Type         Size     Line  Section

__gxx_personality_v0|        |   U  |            NOTYPE|        |     |*UND*
_Z3maxii            |00000000|   T  |              FUNC|00000021|     |.text
_Z3maxff            |00000022|   T  |              FUNC|00000029|     |.text
_Z3maxdd            |0000004c|   T  |              FUNC|00000041|     |.text
```

Мы видим, что три функции max в объектном файле имеют три разных имени. Последние две буквы, по-видимому, кодируют типы данных аргументов, которые передаются в функцию: “I” для int, "f“ для float, “d” для double (всё намного усложняются, если вспомнить ещё и о класса, шаблонах, пространствах имён, перегруженных операторах и т.п.).

Стоит также отметить, что обычно есть способ конверсии пользовательских имён (недекорированных) и имён функций, видимых линкеру. Это делается с помощью либо отдельной утилиты (c++filt), либо с помощью опции в командной строке (--demangle для nm). В результате получи что-то вроде

```
Symbols from fn_overload.o:

Name                  Value   Class        Type         Size     Line  Section

__gxx_personality_v0|        |   U  |            NOTYPE|        |     |*UND*
max(int, int)       |00000000|   T  |              FUNC|00000021|     |.text
max(float, float)   |00000022|   T  |              FUNC|00000029|     |.text
max(double, double) |0000004c|   T  |              FUNC|00000041|     |.text
```

Люди обычно запинаются на этой схеме декорирования, когда смешивают вместе код на си, и код на си++, потому что имена функций С++ модифицируются, а имена функций Си остаются как есть. Для решения проблемы в C++ можно обернуть объявление и определение сишных функций с помощью “extern C”, что говорит компилятору. По существу, директива говорит компилятору, что имена не надо декорировать, либо потому что это С++ функции, которые будут вызваны из Си кода, либо потому что это Си функции, которые будут вызваны из С++ кода.

Вот к примеру какая ошибка выпала бы, если бы мы вставили код из самого начала (см. первую часть) в С++ программу, забыв объявить её как extern c

```
g++ -o test1 test1a.o test1b.o
test1a.o(.text+0x18): In function `main':
: undefined reference to `findmax(int, int)'
collect2: ld returned 1 exit status
```

Подсказкой здесь  то, что сообщение об ошибке содержит сигнатуру функции, а не просто имя findmax. Другими словами, 
код С++ ищет что-то вроде "_Z7findmaxii", но находи лишь findmax, и поэтому не может скомпоновать файл.

Кстати, объявление кода extern c не работает для функций-членов класса (часть 7.5.4. стандарта С++).

## Инициализация статических переменных

Следующая особенность С++, которая сильно влияет на работу линкера – это конструкторы.  Конструктор – это часть кода, которая устанавливает содержимое объекта; концептуально, это похоже на инициализацию переменной начальным значением, но с ключевой особенностью – вовлечением в процесс произвольного участка кода.

Из предыдущих секций известно, что глобальная переменная может иметь начальное значение. В си конструирование инициализированной  глобальной переменной делается просто: из data сегмента кода исполняемой программы копируется значение в нужную область оперативной памяти.

В C++ всё гораздо сложнее обычного копирования фиксированного значения, потому что весь код всех конструкторов в иерархии наследования класса должен запуститься, прежде чем основной код программы начнёт работать как надо.

Для преодоления этой трудности компилятор добавляет в объектный файл дополнительную информацию – список конструкторов, которые должны быть запущены для этого конкретного файла. Во время компоновки линкер собирается всю эту информацию в один большой список и добавляет код, который проходит по списку, вызывая эти глобальные конструкторы объектов.

Можно выследить эти списки, опять же, с помощью nm. Пусть есть такой код на С++

```
class Fred {
private:
  int x;
  int y;
public:
  Fred() : x(1), y(2) {}
  Fred(int z) : x(z), y(3) {}
};

Fred theFred;
Fred theOtherFred(55);
```

Для этого кода nm выдаст (без декорирования)

```
0000000000000038 t _GLOBAL__sub_I_theFred
0000000000000000 B theFred
0000000000000008 B theOtherFred
0000000000000000 t __static_initialization_and_destruction_0(int, int)
0000000000000000 W Fred::Fred(int)
0000000000000000 W Fred::Fred()
0000000000000000 W Fred::Fred(int)
0000000000000000 W Fred::Fred()
0000000000000000 n Fred::Fred(int)
0000000000000000 n Fred::Fred()
```

Или так, с декорированием

```
0000000000000038 t _GLOBAL__sub_I_theFred
0000000000000000 B theFred
0000000000000008 B theOtherFred
0000000000000000 t _Z41__static_initialization_and_destruction_0ii
0000000000000000 W _ZN4FredC1Ei
0000000000000000 W _ZN4FredC1Ev
0000000000000000 W _ZN4FredC2Ei
0000000000000000 W _ZN4FredC2Ev
0000000000000000 n _ZN4FredC5Ei
0000000000000000 n _ZN4FredC5Ev
```

Здесь много всего интересного, но нас волнуют только два вхождения символов с классом W (что значит weak), а также с секциями с именами вроде .gnu.linkonce.t.stuff. Это маркеры глобальных конструкторов объектов. Соответствующие им имена – одино для каждого из конструкторов.

## Шаблоны

В предыдущих разделах мы привели пример функции с одним именем max и тремя наборами аргументов. Тем не менее, код всех трёх функций идентичен, а копирование и вставка одного и того же кода вызывает досаду.

С++ представил шаблоны, которые позволяют для таких случаев писать код единожды и навсегда. Создадим заголовочный файл max_template.h с единственным кодом для max

```
template <class T>
T max(T x, T y) {
  if (x>y) return x;
  else return y;
}
```

Для использования шаблонной функции подключим его

```
#include "max_template.h"

int main(){
  int a=1;
  int b=2;
  int c;
  c = max(a,b);  // Compiler automatically figures out that max(int,int) is needed
  double x = 1.1;
  float y = 2.2;
  double z;
  z = max(x,y); // Compiler can't resolve, so force use of max(double,double)
  return 0;
}
```

Этот С++ файл использует как max<int>(int ,int). Так и max<double>(double, double), но разные файлы С++ могут использовать и другие реализации, например max<float>(float,float), или даже max<MyFloatingPointClass>(MyFloatingPointClass,MyFloatingPointClass).

Каждая их этих разных реализаций включает разный машинный код. Во время компиляции линкер должен убедиться в том, что код всех реализаций добавлен, а также что нет ненужных реализаций, которые будут раздувать код.

Как это делается? Обычно используют два способа – удалением дублированных реализаций, и откладыванием инстанциирования до этапа компоновки.

В первом случае, каждый объектный файл включает все свои реализации шаблонной функции.

```
0000000000000000 T main
0000000000000000 W _Z3maxIdET_S0_S0_
0000000000000000 W _Z3maxIiET_S0_S0_
```

Видно, что представлены как max<int>(int, int), так и max<double>(double, double).

Эти определения обозначены как weak-символы, что значит, что в конечной исполняемой программе линкер может исключить все эти символы (оставив как минимум один). Самый большой недостаток такого подхода в том, что на жёстком диске объектные файлы будут занимать больше места.

Второй подход (который используется компилятором Solaris C++) вообще не включать код этих функций в объектный файл. Оставляя символы неопределёнными. Во время компоновки линкер может собрать все эти неопределённые символы и тогда уже сгенерировать для них код и включить в программу.

Такой подход уменьшает размер объектных файлов, однако требует от компилятора знать, в каких заголовочных файлах какие шаблоны объявлены и уметь вызывать компилятор для генерации кода. Всё это замедляет линковку.

## Динамически подгружаемые библиотеки

Последняя особенность, которую мы обсудим, это динамическое подключение разделяемых библиотек. В предыдущем разделе рассказано о том, что финальная компоновка откладывается до момента работы программы. На современных системах она может быть отложена ещё дальше.

Это делается с помощью двух системных вызовов dlopen и dlsym (грубые аналоги на Windows это LoadLibrary и GetProcaddress).Првый вызов по имени библиотеки подгружает её в адресное пространство исполняемого процесса. Конечно, эта библиотека сама может содержать неопределённые символы и её подгрузка приведёт к вызову dlopen.

Также можно указать dlopen что в этом случае делать. Флаг RTLD_NOW приведёт к подгрузке всех необходимых библиотек, а RTLD_LAZY будет подключать библиотеки по одной, по мере необхомости. Первый подход гораздо медленнее, но во во втором случае возможна ситуация, когда дополнительная библиотек не найдена, что приведёт к завершению работы программы.

У символа из динамически подгружаемой библиотеки нет имени. Тем не менее, как обычно в программировании, это решается ещё одним уровнем косвенной адресации. В этом случае, используя указатель на символ, а не обращаясь к нему по имени. Системный вызов dlsym принимает строковый параметр – имя символа – и возвращает указатель на него (или NULL, если найти не удалось).

## Взаимодействие с возможностями С++

Каким же образом вышеприведённая динамическая загрузка вязана с возможностями С++, которые влияют на поведение линкера?

Первое наблюдение – декорирование имён достаточно каверзное. Вызов dlsym ищет символ по имени, это имя должно быть видимым компоновщику; поэтому именно декорированное имя должно быть в качестве аргумента. Из-за того, что способ модификации имён не стандартизирован и отличается от платформы к платформе, почти невозможно кроссплатформенно найти адрес символа динамически. Если вам и посчастливилось работать только с одним компилятором и покопаться в его внутренностях, есть ещё проблемы – кроме чистых С-подобных функций вам придётся тащить разные виртуальные таблицы методов и пр.

Обычно проще всего придерждиваться одного компилятора, оборачивать точку входа в extern c, которую легко получить с помощью dlsym. Эта точка входа может быть фабричным методом, возвращающим указатели на полные экземпляры  С++ классов.

Компилятор может ещё достать конструкторы для глобальных объектов, открыв библиотеку с помощью dlopen, так как существует набор спецсимволов, которые будут вызваны при загрузке или выгрузке библиотеки. В UNIX системах это _init и _fini, в GNU __attribute__((constructor)) или . __attribute__((destructor)). В Windows DllMain с параметрами или DLL_PROCESS_ATTACH и DLL_PROCESS_DETACH.

