# Сложные объявления

В си часто могут появляться сложные определения, состоящие из указателей на массивы, указатели на функции, указатели на функции возвращающие указатели на указатели на функции и т.п. В большинстве случаев такие проблемы разрешаются определением нового типа (с помощью typedef).

Самый простой случай – массивы.

```
int *a;
```

```
int (*a)[10];
```

```
int (*a)();
```

```
int (*a)(int*);
```

```
int* (*a)(double *);
```

```
int* (**a)(float);
```

```
double (*a[10])(int, int, int);
```

```
int* bar(int (*f)(void));
```

```
int* (*b)(int (void))
```

```
float bar2(int *(f)(int (void))) {...
```

```
float (*b2)(int* (int (void)));
```

```
int foo() {
	return 3;
}

int (*p)(void) = foo;
printf("%d\n", p());
```

```
int (*foo3())(float*) {
	return foo2;
}

int (*(*p3)(void))(float*) = foo3;
printf("%d\n", p3()(&a));
```

```
int (*(*foo4())(void))(float*) {
	return foo3;
}

int (*(*(*p4)(void))(void))(float*) = foo4;
printf("%d\n", p4()()(&a));
```

```
int (*(*(*foo5(char letter))(void))(void))(float*) {
	printf("inside foo5 got %c\n", letter);
	return foo4;
}

int (*(*(*(*p5)(char))(void))(void))(float*) = foo5;
printf("%d\n", p5('A')()()(&a));
```

```
int (*(*(*(*foo6(double *x))(char))(void))(void))(float*) {
	printf("inside foo6 got %.3f\n", *x);
	return foo5;
}

int (*(*(*(*(*p6)(double*))(char))(void))(void))(float*) = foo6;
printf("%d\n", p6(&d)('B')()()(&a));
```

```
int (*foobar (int (*f)(void)))(float*) {
	printf("inside foobar %d\n", f());
	return foo2;
}


int (*(*fb)(int (void)))(float*) = foobar;
printf("%d\n", foobar(foo)(&a));
```

```
int foo2(float *b) {
	return (int)(*b);
}

int (*p2)(float*) = foo2;
```

```
typedef int (*foo_type)(float *);

foo_type p2a = foo2;
```

```
typedef foo_type (*foo_foo_type)();
```

```
foo_foo_type p3a = foo3;
```

