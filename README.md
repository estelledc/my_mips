## 目录
 1. 实验任务、目标
 2. 微处理器各个模块硬件设计原理、verilog代码
 3. Rom汇编程序设计、代码
 4. 各个模块的仿真激励代码、仿真结果截图以及文字说明如何验证其正确性
 5. 心得体会



## 1. 实验任务与目标

### 实验任务

- 使用Verilog HDL设计实现一个简单指令集的单周期MIPS微处理器

- 实现基本的MIPS指令集，包括算术运算、逻辑运算、数据传输和控制转移指令

- 实现扩展指令：JAL和JR

- 完成各模块的功能仿真和整体系统仿真

### 实验目标

- 掌握MIPS微处理器的基本架构和设计方法

- 理解各功能模块的工作原理和实现方式

- 验证所有指令的正确执行

- 掌握Verilog HDL的模块化设计方法

## 2. 微处理器各模块硬件设计原理

### 2.1 整体架构
主要包含以下模块：

- 程序计数器(PC)

- 指令存储器(Instruction Memory)

- 寄存器文件(Register File)

- 算术逻辑单元(ALU)

- 控制单元(Control Unit)

- 数据存储器(Data Memory)

- 符号扩展单元(Sign Extend)

- PC计算单元(PC Calculator)

### 2.2 各模块详细设计

#### 2.2.1 寄存器文件(reg_file.v)

```verilog

Apply to reg_file.v

module reg_file(

    input clk,

    input reset,

    input [4:0] read_reg1,

    input [4:0] read_reg2,

    input [4:0] write_reg,

    input [31:0] write_data,

    input write_en,

    output reg [31:0] read_data1,

    output reg [31:0] read_data2

);
```

- 包含32个32位通用寄存器

- 支持双端口读取和单端口写入

- 在时钟下降沿进行写入操作

- 复位时寄存器值初始化为寄存器编号×4

#### 2.2.2 ALU(alu.v)

```verilog

Apply to reg_file.v

module alu(

    input [31:0] a,

    input [31:0] b,

    input [3:0] control,

    output reg [31:0] result,

    output zero

);
```

- 支持AND、OR、ADD、SUB、SLT、NOR等运算

- 提供零标志位输出

#### 2.2.3 控制单元(control_unit.v)

```verilog

Apply to reg_file.v

module control_unit(

    input [5:0] opcode,

    input [5:0] funct,

    output reg [1:0] reg_dst,

    output reg alu_src,

    output reg [1:0] mem_to_reg,

    output reg reg_write,

    output reg mem_write,

    output reg [3:0] alu_control,

    output reg branch,

    output reg jump

);
```

- 根据指令opcode和funct字段生成控制信号

- 支持R型、I型和J型指令的控制

#### 2.2.4 数据存储器(data_memory.v)

```verilog

Apply to reg_file.v

module data_memory(

    input clk,

    input reset,

    input [5:0] addr,

    input [31:0] write_data,

    input write_en,

    output reg [31:0] read_data

);
```

- 32×32位存储器

- 地址对齐为4的整数倍

- 在时钟下降沿进行写入操作

#### 2.2.5 指令存储器(instruction_memory.v)

```verilog

Apply to reg_file.v

module instruction_memory(

    input clk,

    input [5:0] addr,

    output reg [31:0] instruction

);
```

- 在时钟上升沿读取指令

- 预装载测试程序

## 3. ROM汇编程序设计

### 3.1 测试程序

```assembly

main:    add $4,$2,$3        # R型指令：$4 = $2 + $3

         lw $4,4($2)         # I型指令：$4 = Memory[$2 + 4]

         sw $5,8($2)         # I型指令：Memory[$2 + 8] = $5

         sub $2,$4,$3        # R型指令：$2 = $4 - $3

         or $2,$4,$3         # R型指令：$2 = $4 | $3

         and $2,$4,$3        # R型指令：$2 = $4 & $3

         slt $2,$4,$3        # R型指令：$2 = ($4 < $3) ? 1 : 0

         beq $3,$3,equ       # 分支指令：if($3 == $3) goto equ

         lw $2,0($3)         # I型指令：$2 = Memory[$3]

equ:     beq $3,$4,exit      # 分支指令：if($3 == $4) goto exit

         sw $2,0($3)         # I型指令：Memory[$3] = $2

exit:    j main              # 跳转指令：goto main
```

### 3.2 扩展指令测试

```assembly
         jal 20              # 跳转并链接：$31 = PC + 4, PC = 20

         jr $31              # 跳转寄存器：PC = $31
```

## 4. 仿真验证
### 各个模块的仿真激励代码
#### 寄存器文件(reg_file)仿真激励
```verilog
module reg_file_tb;
    // 定义信号
    reg clk, reset, write_en;
    reg [4:0] read_reg1, read_reg2, write_reg;
    reg [31:0] write_data;
    wire [31:0] read_data1, read_data2;
    
    // 实例化被测模块
    reg_file uut(
        .clk(clk),
        .reset(reset),
        .read_reg1(read_reg1),
        .read_reg2(read_reg2),
        .write_reg(write_reg),
        .write_data(write_data),
        .write_en(write_en),
        .read_data1(read_data1),
        .read_data2(read_data2)
    );
    
    // 时钟生成
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // 测试激励
    initial begin
        // 初始化
        reset = 1;
        write_en = 0;
        read_reg1 = 0;
        read_reg2 = 0;
        write_reg = 0;
        write_data = 0;
        
        // 复位测试
        #20;
        reset = 0;
        
        // 测试写入
        #10;
        write_en = 1;
        write_reg = 5;
        write_data = 32'h12345678;
        
        // 测试读取
        #10;
        read_reg1 = 5;
        read_reg2 = 0;
        
        // 测试寄存器0的特殊性
        #10;
        write_reg = 0;
        write_data = 32'hFFFFFFFF;
        
        // 测试双端口读取
        #10;
        read_reg1 = 5;
        read_reg2 = 5;
        
        // 结束仿真
        #20;
        $finish;
    end
    
    // 监控输出
    initial begin
        $monitor("Time=%t reset=%b write_en=%b write_reg=%d write_data=%h read_data1=%h read_data2=%h",
                 $time, reset, write_en, write_reg, write_data, read_data1, read_data2);
    end
endmodule
```
#### ALU仿真激励
```verilog
module alu_tb;
    // 定义信号
    reg [31:0] a, b;
    reg [3:0] control;
    wire [31:0] result;
    wire zero;
    
    // 实例化被测模块
    alu uut(
        .a(a),
        .b(b),
        .control(control),
        .result(result),
        .zero(zero)
    );
    
    // 测试激励
    initial begin
        // 初始化
        a = 0;
        b = 0;
        control = 0;
        
        // 测试AND运算
        #10;
        a = 32'hFFFFFFFF;
        b = 32'h0000FFFF;
        control = 4'b0000;
        
        // 测试OR运算
        #10;
        control = 4'b0001;
        
        // 测试ADD运算
        #10;
        a = 32'h00000001;
        b = 32'h00000002;
        control = 4'b0010;
        
        // 测试SUB运算
        #10;
        control = 4'b0110;
        
        // 测试SLT运算
        #10;
        a = 32'h00000001;
        b = 32'h00000002;
        control = 4'b0111;
        
        // 测试NOR运算
        #10;
        a = 32'hFFFFFFFF;
        b = 32'h00000000;
        control = 4'b1100;
        
        // 测试零标志位
        #10;
        a = 32'h00000000;
        b = 32'h00000000;
        control = 4'b0010;
        
        // 结束仿真
        #10;
        $finish;
    end
    
    // 监控输出
    initial begin
        $monitor("Time=%t control=%b a=%h b=%h result=%h zero=%b",
                 $time, control, a, b, result, zero);
    end
endmodule
```

#### 控制单元仿真激励
```verilog
module control_unit_tb;
    // 定义信号
    reg [5:0] opcode, funct;
    wire [1:0] reg_dst;
    wire alu_src;
    wire [1:0] mem_to_reg;
    wire reg_write;
    wire mem_write;
    wire [3:0] alu_control;
    wire branch;
    wire jump;
    
    // 实例化被测模块
    control_unit uut(
        .opcode(opcode),
        .funct(funct),
        .reg_dst(reg_dst),
        .alu_src(alu_src),
        .mem_to_reg(mem_to_reg),
        .reg_write(reg_write),
        .mem_write(mem_write),
        .alu_control(alu_control),
        .branch(branch),
        .jump(jump)
    );
    
    // 测试激励
    initial begin
        // 初始化
        opcode = 0;
        funct = 0;
        
        // 测试R型指令
        #10;
        opcode = 6'b000000;
        funct = 6'b100000; // ADD
        
        #10;
        funct = 6'b100010; // SUB
        
        #10;
        funct = 6'b100100; // AND
        
        // 测试I型指令
        #10;
        opcode = 6'b100011; // LW
        
        #10;
        opcode = 6'b101011; // SW
        
        #10;
        opcode = 6'b000100; // BEQ
        
        // 测试J型指令
        #10;
        opcode = 6'b000010; // J
        
        #10;
        opcode = 6'b000011; // JAL
        
        // 测试JR指令
        #10;
        opcode = 6'b000000;
        funct = 6'b001000; // JR
        
        // 结束仿真
        #10;
        $finish;
    end
    
    // 监控输出
    initial begin
        $monitor("Time=%t opcode=%b funct=%b reg_dst=%b alu_src=%b mem_to_reg=%b reg_write=%b mem_write=%b alu_control=%b branch=%b jump=%b",
                 $time, opcode, funct, reg_dst, alu_src, mem_to_reg, reg_write, mem_write, alu_control, branch, jump);
    end
endmodule
```

#### 数据存储器仿真激励
```verilog
module data_memory_tb;
    // 定义信号
    reg clk, reset, write_en;
    reg [5:0] addr;
    reg [31:0] write_data;
    wire [31:0] read_data;
    
    // 实例化被测模块
    data_memory uut(
        .clk(clk),
        .reset(reset),
        .addr(addr),
        .write_data(write_data),
        .write_en(write_en),
        .read_data(read_data)
    );
    
    // 时钟生成
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // 测试激励
    initial begin
        // 初始化
        reset = 1;
        write_en = 0;
        addr = 0;
        write_data = 0;
        
        // 复位测试
        #20;
        reset = 0;
        
        // 测试写入
        #10;
        write_en = 1;
        addr = 6'h01;
        write_data = 32'h12345678;
        
        // 测试读取
        #10;
        write_en = 0;
        addr = 6'h01;
        
        // 测试地址对齐
        #10;
        write_en = 1;
        addr = 6'h02;
        write_data = 32'h87654321;
        
        // 测试多个地址
        #10;
        addr = 6'h03;
        write_data = 32'hFFFFFFFF;
        
        // 结束仿真
        #20;
        $finish;
    end
    
    // 监控输出
    initial begin
        $monitor("Time=%t reset=%b write_en=%b addr=%h write_data=%h read_data=%h",
                 $time, reset, write_en, addr, write_data, read_data);
    end
endmodule
```
### 仿真截图及说明
#### 基础指令
```verilog
        // 基础功能
        mem[0] = 32'h00000000;
        mem[1] = 32'h00432020; // add $4,$2,$3
        mem[2] = 32'h8c440004; // lw $4,4($2)
        mem[3] = 32'hac450008; // sw $5,8($2)
        mem[4] = 32'h00831022; // sub $2,$4,$3
        mem[5] = 32'h00831025; // or $2,$4,$3
        mem[6] = 32'h00831024; // and $2,$4,$3
        mem[7] = 32'h0083102a; // slt $2,$4,$3
        mem[8] = 32'h10630001; // beq $3,$3,equ (PC+1+1)
        mem[9] = 32'h8c620000; // lw $2,0($3)
		//equ:
        mem[10] = 32'h10640001; // beq $3,$4,exit (PC+1+1)
        mem[11] = 32'hac620000; // sw $2,0($3)
		//exit:
        mem[12] = 32'h08000000; // j main (PC = 0)
```
##### add $4,$2,$3
将寄存器`$2` 和 `$3`中的值视为32位有符号整数下相加，运算结果存入`$4`
![](https://raw.githubusercontent.com/estelledc/photos/master/2025-05-08_17-14-44.png)
操作码（opcode）​​：`0x00`（表示R型指令）
​​功能码（funct）​​：`0x20`（表示 `add` 操作）
![](https://raw.githubusercontent.com/estelledc/photos/master/2025-05-08_17-19-31.png)
##### lw $4,4($2)
- ​**​语法​**​：`lw rt, offset(base)`
    - ​**​`rt`​**​：目标寄存器（此处是 `$4`），用于存储从内存加载的数据。
    - ​**​`offset`​**​：16位有符号偏移量（此处是 `4`）。
    - ​**​`base`​**​：基址寄存器（此处是 `$2`），用于指定内存地址的基址。
- ​**​机器码格式​**​：
    - ​**​操作码（opcode）​**​：`0x23`（十六进制），对应二进制 `100011`。
    - ​**​基址寄存器（base）​**​：`$2` 的编号为 `2`，二进制编码为 `00010`。
    - ​**​目标寄存器（rt）​**​：`$4` 的编号为 `4`，二进制编码为 `00100`。
    - ​**​偏移量（offset）​**​：`4` 的16位二进制补码为 `0000000000000100`。
- ​**​完整机器码​**​：
```
        100011 00010 00100 0000000000000100 → 十六进制 0x8C440004
```
 ![](https://raw.githubusercontent.com/estelledc/photos/master/2025-05-08_17-25-29.png)

![](https://raw.githubusercontent.com/estelledc/photos/master/2025-05-08_23-43-40.png)
##### sw $5,8($2)
 - ​**​语法​**​：`sw rt, offset(base)`
    - ​**​`rt`​**​：源寄存器（此处是 `$5`），存储待写入内存的数据。
    - ​**​`offset`​**​：16位有符号偏移量（此处是 `8`）。
    - ​**​`base`​**​：基址寄存器（此处是 `$2`），用于计算内存地址。
- ​**​机器码格式​**​：
    - ​**​操作码（opcode）​**​：`0x2B`（十六进制），对应二进制 `101011`。
    - ​**​基址寄存器（base）​**​：`$2` 的编号为 `2`，二进制编码 `00010`。
    - ​**​源寄存器（rt）​**​：`$5` 的编号为 `5`，二进制编码 `00101`。
    - ​**​偏移量（offset）​**​：`8` 的16位二进制补码为 `0000000000001000`。
- ​**​完整机器码​**​：
```
    101011 00010 00101 0000000000001000 → 十六进制 0xAC450008
```
![](https://raw.githubusercontent.com/estelledc/photos/master/2025-05-08_18-13-57.png)
##### slt $2,$4,$3
**语法​**​：`slt $d, $s, $t`
- `$d`：目标寄存器（此处为 `$2`），存储比较结果。
- `$s` 和 `$t`：源寄存器（此处为 `$4` 和 `$3`），提供比较的两个操作数。
- ​**​有符号比较​**​：将 `$4` 和 `$3` 的值视为 ​**​32位有符号整数​**​，进行大小比较。
    - ​**​规则​**​：
        - 若 `$4` 的值 ​**​<​**​ `$3` 的值 → `$2` 设为 `1`。
        - 否则 → `$2` 设为 `0`。
    - ​**​结果存储​**​：比较结果直接写入 `$2`，源寄存器 (`$4` 和 `$3`) 的值不变。
![](https://raw.githubusercontent.com/estelledc/photos/master/2025-05-08_18-31-13.png)
##### beq $3,$3,equ (PC+1+1)
- ​**​指令格式​**​：`beq rs, rt, offset`
    - `rs`（源寄存器1）：`$3`
    - `rt`（源寄存器2）：`$3`
    - `offset`（偏移量）：目标地址相对于下一条指令的 ​
- **​字偏移量​**​**条件判断​**​：比较 `$3` 和 `$3` 的值是否相等。
	由于 `$3` 的值一定等于自身，​**​分支条件恒成立​**​，因此该指令等效于 ​**​无条件跳转​**​ 到标签 `equ`。（16位有符号数）。
![](https://raw.githubusercontent.com/estelledc/photos/master/2025-05-08_18-29-23.png)
##### j main (PC = 0)
![](https://raw.githubusercontent.com/estelledc/photos/master/2025-05-08_18-19-18.png)
#### 扩展指令（ jal & jr ）
```verilog
        //jal jr测试
        mem[0] = 32'h00000000;        // NOP
        mem[1] = 32'h0c000005;        // jal 20 (20为函数slt $2,$4,$3)
        mem[2] = 32'h00432020;        // add $4,$2,$3
        mem[3] = 32'h08000000;        // j 0
        mem[4] = 32'h00000000;        // NOP
        // 子函数
        mem[5] = 32'h00000000;        // NOP原因：指令存储器的取指时序与PC更新时序之间的不匹配
        mem[6] = 32'h0083102a;        // slt $2,$4,$3
        mem[7] = 32'h03e00008;        // jr $31 (return 主函数)
```

![](https://raw.githubusercontent.com/estelledc/photos/master/2025-05-08_16-53-09.png)
注释：
1处`$31`保存返回地址即`32'h03e00008`，2处进入子函数中的`slt`
中间隔了一个周期是mem[5] = 32'h00000000;  NOP原因：指令存储器的取指时序与PC更新时序之间的不匹配，为了达到上升沿取指，下降沿寄存器文件写入、数据存储器写入和PC更新，故增加nop。

![](https://raw.githubusercontent.com/estelledc/photos/master/2025-05-08_16-57-26.png)
注释
3处PC变为`32'h00000008`实现跳转回主函数
## 5. 心得体会

通过本次MIPS微处理器的设计与实现，我深入理解了微处理器的工作原理和设计方法。在代码实现过程中，我采用了模块化的设计思想，将处理器分解为寄存器文件(reg_file)、ALU(alu)、控制单元(control_unit)、数据存储器(data_memory)等独立模块。每个模块都有清晰的接口定义，如寄存器文件的读写接口(input [4:0] write_reg, input [31:0] write_data, input write_en)，ALU的运算接口(input [31:0] a, input [31:0] b, input [3:0] control)。在时序控制方面，我特别注意了时钟边沿的设计，指令存储器在时钟上升沿读取指令，而寄存器文件写入、数据存储器写入和PC更新在时钟下降沿进行，这种设计有效避免了数据竞争问题。在地址对齐方面，我确保了数据存储器的地址都是4的整数倍，这符合MIPS架构的基本要求。通过实现基本的MIPS指令集，包括算术运算、逻辑运算、数据传输和控制转移指令，以及扩展的JAL和JR指令，我不仅验证了所有指令的正确性，也掌握了微处理器设计的基本方法。在调试过程中，我学会了使用波形查看器分析信号变化，提高了硬件调试能力。虽然当前实现已经能够正确执行所有指令，但仍有改进空间，如优化时序、增加更多指令支持、改进测试覆盖度等。这次实验不仅让我深入理解了MIPS架构，也提高了我的Verilog HDL编程能力和硬件调试技能，为今后的学习和工作打下了坚实的基础。

