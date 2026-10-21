# 8086 汇编语言课程作业：求和与进制转换

本项目按照 16 位 DOS 汇编环境编写，使用 MASM/TASM 兼容语法和 DOS `INT 21H` 服务。

## 文件说明

| 文件 | 内容 |
|---|---|
| `sum_variants.asm` | 计算 1+2+...+100，分别演示寄存器 AX、数据段变量、堆栈三种结果存储方式 |
| `sum_n.asm` | 输入 1～100 的整数，计算 1+2+...+n 并输出十进制结果 |
| `hex_to_dec.asm` | 输入 1～2 位十六进制数（支持大小写），输出十进制数 |
| `dec_to_hex.asm` | 输入 0～65535 的十进制整数，输出大写十六进制数 |
| `sum_c.c` | C 语言版本的 1～n 求和程序 |
| `assembly-notes.md` | 生成 C 编译器汇编输出并添加注释的步骤 |
| `.gitignore` | 忽略汇编/链接生成的临时文件 |

## 运行环境

建议使用 DOSBox 加 MASM/TASM，或课程指定的 8086 DOS 模拟环境。代码使用 `.MODEL SMALL`、`.STACK`、`.DATA`、`.CODE` 和 DOS `INT 21H` 服务，不能直接当作 Linux x86-64 汇编程序运行。

### MASM 示例

在 DOSBox 中切换到源文件所在目录后执行：

```dos
MASM SUM_VARIANTS.ASM;
LINK SUM_VARIANTS.OBJ;
SUM_VARIANTS.EXE
```

其他三个 `.asm` 文件也按同样方式分别汇编和链接。例如：

```dos
MASM HEX_TO_DEC.ASM;
LINK HEX_TO_DEC.OBJ;
HEX_TO_DEC.EXE
```

### TASM 示例

```dos
TASM SUM_VARIANTS.ASM
TLINK SUM_VARIANTS.OBJ
SUM_VARIANTS.EXE
```

请按你安装的 MASM/TASM 版本调整命令。若使用老师指定的 IDE/模拟器，优先遵循课程环境的编译运行方式。

## 预期测试

### `sum_variants.asm`

应输出三行，结果均为：

```text
Register result (AX): 5050
Data segment result: 5050
Stack result: 5050
```

### `sum_n.asm`

输入 `100`，应输出 `5050`；输入 `10`，应输出 `55`；输入 0、101 或非数字应提示输入错误。

### `hex_to_dec.asm`

输入 `ff` 或 `FF`，应输出 `255`；输入 `A`，应输出 `10`；输入 `10`，应输出 `16`。

### `dec_to_hex.asm`

输入 `255`，应输出 `FF`；输入 `65535`，应输出 `FFFF`；输入 `0`，应输出 `0`。

## 算法要点

- 求和使用循环累加：`sum = sum + i`。
- 十六进制转十进制：每读入一位，执行 `value = value * 16 + digit`。
- 十进制转十六进制：不断除以 16，保存余数，最后按余数的逆序输出。
- DOS `INT 21H` 常用服务：`AH=09H` 输出 `$` 结尾字符串，`AH=0AH` 缓冲键盘输入，`AH=02H` 输出一个字符，`AH=4CH` 结束程序。

## 上传到 GitHub 前

请在课程指定环境实际汇编并运行，确认输出与预期一致。`assembly-notes.md` 说明了如何生成并注释 `sum_c.s`；由于编译器和平台会影响输出，请把自己生成并注释后的文件加入仓库，而不要假定所有机器生成的汇编都相同。
