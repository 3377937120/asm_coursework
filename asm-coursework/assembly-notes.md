## GCC 示例

在 `sum_c.c` 所在目录打开终端：

```bash
gcc -O0 -S -masm=intel sum_c.c -o sum_c.s
```

`-O0` 关闭大部分优化，通常更容易对应 C 语言中的变量、循环和判断；`-S` 只生成汇编文件；`-masm=intel` 让 GCC 输出 Intel 风格的操作数顺序。生成的汇编取决于你所安装的 GCC 和目标平台。

查看文件：

```bash
# Windows PowerShell
notepad sum_c.s

# macOS / Linux
less sum_c.s
```

## 注释时重点观察

1. 函数入口与出口：编译器如何建立和恢复栈帧，如何返回。
2. 局部变量：`n`、`i`、`sum` 被放在寄存器还是栈内存中。
3. 输入输出：`printf` 和 `scanf` 通常表现为函数调用，而不是一条单独的 CPU 指令。
4. 循环：比较指令、条件跳转和无条件跳转如何构成 `for` 循环。
5. 累加：`sum += i` 对应的加法指令，以及变量在寄存器/内存间的读写。

可以在生成的 `.s` 文件中添加 `#` 注释，例如：

```asm
# Example only: actual compiler output may differ.
# Compare the loop counter with the upper bound.
# A conditional jump either continues the loop or exits it.
```

请在自己生成的 `sum_c.s` 上标注实际指令，并将带注释的文件保存进项目。
