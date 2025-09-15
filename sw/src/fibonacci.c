int main() {

    volatile int n = 10;
    volatile int a = 0;
    volatile int b = 1;
    volatile int temp;

    for (volatile int i = 0; i < n; i++) {
        temp = a + b;
        a = b;
        b = temp;
    }

    // No final, "a" terá fib(n-1)
    return 0;

}