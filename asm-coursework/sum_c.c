#include <stdio.h>

int main(void)
{
    unsigned int n;
    unsigned int i;
    unsigned int sum = 0;

    printf("Enter n (1-100): ");
    if (scanf("%u", &n) != 1 || n < 1 || n > 100) {
        fprintf(stderr, "Invalid input. Enter an integer from 1 to 100.\n");
        return 1;
    }

    for (i = 1; i <= n; ++i) {
        sum += i;
    }

    printf("Sum from 1 to %u = %u\n", n, sum);
    return 0;
}
