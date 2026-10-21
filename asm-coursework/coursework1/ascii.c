#include <stdio.h>

int main(void)
{
    int i;

    for (i = 0; i < 26; i++)
    {
        putchar('a' + i);       // 输出当前小写字母

        if (i % 13 == 12)
            putchar('\n');      // 每输出 13 个字母后换行
        else
            putchar(' ');       // 字母之间输出空格
    }

    return 0;
}