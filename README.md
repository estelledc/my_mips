# my_mips · 单周期 MIPS CPU Verilog 实现

## 这个 CPU 能做什么

用 Verilog 写了一颗单周期 MIPS CPU，跑得动写在指令存储器里的 MIPS 汇编测试程序。
- 指令集范围：算术（add / sub）、逻辑（and / or / nor）、比较（slt）、访存（lw / sw）、分支（beq）、跳转（j）
- 扩展指令：jal（跳转并链接）、jr（跳转寄存器），覆盖最朴素的子函数调用与返回
- 验证粒度：reg_file / alu / control_unit / data_memory 各自有独立 testbench，整机通过预装载 ROM 程序看波形验证

## 模块组装

整体由 8 个模块拼装：PC 给地址，指令存储器吐指令，控制单元解码 opcode + funct 后拉控制线，寄存器文件吐两路操作数，符号扩展处理立即数，ALU 算结果，数据存储器处理 lw/sw，PC 计算单元算下一条 PC（顺序 / 分支 / 跳转）。核心 5 个模块的接口和设计点：

### 寄存器文件 (reg_file.v)

```verilog

Apply to reg_file.v

module reg_file(

    input clk,

    input reset,

    input [4:0] read_reg1,

    input [4:0] read_reg2,

    input [4:0] write_reg,

    input [31:0] write_data,

    input write_en,

    output reg [31:0] read_data1,

    output reg [31:0] read_data2

);
```

32 个 32 位通用寄存器，双端口读 + 单端口写，写在时钟下降沿，复位时寄存器初值置为编号 × 4 方便仿真观察。

### ALU (alu.v)

```verilog

Apply to reg_file.v

module alu(

    input [31:0] a,

    input [31:0] b,

    input [3:0] control,

    output reg [31:0] result,

    output zero

);
```

支持 AND / OR / ADD / SUB / SLT / NOR，靠 4 位 control 选运算，并输出零标志位供 beq 判分支。

### 控制单元 (control_unit.v)

```verilog

Apply to reg_file.v

module control_unit(

    input [5:0] opcode,

    input [5:0] funct,

    output reg [1:0] reg_dst,

    output reg alu_src,

    output reg [1:0] mem_to_reg,

    output reg reg_write,

    output reg mem_write,

    output reg [3:0] alu_control,

    output reg branch,

    output reg jump

);
```

根据 opcode + funct 生成所有控制信号，覆盖 R 型 / I 型 / J 型，jal 与 jr 在这里也分流处理。

### 数据存储器 (data_memory.v)

```verilog

Apply to reg_file.v

module data_memory(

    input clk,

    input reset,

    input [5:0] addr,

    input [31:0] write_data,

    input write_en,

    output reg [31:0] read_data

);
```

32 × 32 位小存储，[5:0] addr 当 word index 用（外部把 byte offset 右移 2 位喂进来），写在时钟下降沿，与寄存器文件写时序对齐避免一拍内读写打架。

### 指令存储器 (instruction_memory.v)

```verilog

Apply to reg_file.v

module instruction_memory(

    input clk,

    input [5:0] addr,

    output reg [31:0] instruction

);
```

时钟上升沿取指，预装载测试程序，与下降沿的写回 / PC 更新错半拍构成单周期时序。

## ROM 测试程序

ROM 塞两段：一段把 R / I / J 主干指令跑一遍，一段单独打 jal + jr 的子函数往返。

### 测试程序

```assembly

main:    add $4,$2,$3        # R型指令：$4 = $2 + $3

         lw $4,4($2)         # I型指令：$4 = Memory[$2 + 4]

         sw $5,8($2)         # I型指令：Memory[$2 + 8] = $5

         sub $2,$4,$3        # R型指令：$2 = $4 - $3

         or $2,$4,$3         # R型指令：$2 = $4 | $3

         and $2,$4,$3        # R型指令：$2 = $4 & $3

         slt $2,$4,$3        # R型指令：$2 = ($4 < $3) ? 1 : 0

         beq $3,$3,equ       # 分支指令：if($3 == $3) goto equ

         lw $2,0($3)         # I型指令：$2 = Memory[$3]

equ:     beq $3,$4,exit      # 分支指令：if($3 == $4) goto exit

         sw $2,0($3)         # I型指令：Memory[$3] = $2

exit:    j main              # 跳转指令：goto main
```

### 扩展指令测试

```assembly
         jal 20              # 跳转并链接：$31 = PC + 4, PC = 20

         jr $31              # 跳转寄存器：PC = $31
```

## 仿真验证

每个核心模块单独仿真后再上整机：先用 testbench 喂典型激励看每个模块独立行为对不对，再把预装载 ROM 放进整机看波形跑完整指令流。

### 各个模块的仿真激励代码

下面四个 testbench 分别覆盖寄存器文件、ALU、控制单元、数据存储器，激励都按"复位 → 典型用例 → 边界用例"的顺序排列，用 `$monitor` 打印关键信号。

#### 寄存器文件 (reg_file) 仿真激励
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
#### ALU 仿真激励
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
将寄存器 `$2` 和 `$3` 中的值视为 32 位有符号整数相加，结果存入 `$4`。opcode `0x00`（R 型），funct `0x20`（add）。
![](https://raw.githubusercontent.com/estelledc/photos/master/2025-05-08_17-14-44.png)
![](https://raw.githubusercontent.com/estelledc/photos/master/2025-05-08_17-19-31.png)

##### lw $4,4($2)
语法 `lw rt, offset(base)`：rt = `$4` 接收数据，offset = `4`，base = `$2` 给基址。机器码字段：
- opcode `0x23` → `100011`
- base `$2` → `00010`
- rt `$4` → `00100`
- offset `4` → `0000000000000100`

完整机器码：
```
        100011 00010 00100 0000000000000100 → 十六进制 0x8C440004
```
 ![](https://raw.githubusercontent.com/estelledc/photos/master/2025-05-08_17-25-29.png)

![](https://raw.githubusercontent.com/estelledc/photos/master/2025-05-08_23-43-40.png)

##### sw $5,8($2)
语法 `sw rt, offset(base)`：rt = `$5` 提供待写入数据，offset = `8`，base = `$2` 给基址。机器码字段：
- opcode `0x2B` → `101011`
- base `$2` → `00010`
- rt `$5` → `00101`
- offset `8` → `0000000000001000`

完整机器码：
```
    101011 00010 00101 0000000000001000 → 十六进制 0xAC450008
```
![](https://raw.githubusercontent.com/estelledc/photos/master/2025-05-08_18-13-57.png)

##### slt $2,$4,$3
语法 `slt $d, $s, $t`，把 `$4` 和 `$3` 当 32 位有符号数比较：`$4 < $3` 时 `$2 = 1`，否则 `$2 = 0`，源寄存器值不变。
![](https://raw.githubusercontent.com/estelledc/photos/master/2025-05-08_18-31-13.png)

##### beq $3,$3,equ (PC+1+1)
指令格式 `beq rs, rt, offset`，rs / rt 都是 `$3`，offset 是相对下一条指令的字偏移量（16 位有符号）。`$3` 必然等于自身，分支条件恒成立，等效于无条件跳到 `equ`。
![](https://raw.githubusercontent.com/estelledc/photos/master/2025-05-08_18-29-23.png)

##### j main (PC = 0)
![](https://raw.githubusercontent.com/estelledc/photos/master/2025-05-08_18-19-18.png)

#### 扩展指令(jal & jr)
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
注释：1 处 `$31` 保存返回地址 `32'h03e00008`，2 处进入子函数中的 `slt`。中间隔了一个周期是 `mem[5] = 32'h00000000` NOP——指令存储器取指时序与 PC 更新时序错半拍（上升沿取指 / 下降沿写回 + PC 更新），不补 NOP 会取错指令。

![](https://raw.githubusercontent.com/estelledc/photos/master/2025-05-08_16-57-26.png)
注释：3 处 PC 变为 `32'h00000008`，实现跳回主函数。

## 几条具体的设计选择

几条具体的设计选择记录如下。

模块拆分：reg_file、alu、control_unit、data_memory 各自一个 .v 文件，接口在头部写死，方便单独写 testbench 仿真。

时钟边沿分工：指令存储器上升沿取指，寄存器写、数据存储器写、PC 更新统一放在下降沿。这样同一拍里读到的是旧值、写的是新值，不会出现一拍内读写打架。

地址对齐：data_memory 用 [5:0] addr，访问按 4 字节对齐处理。

JAL/JR 时序坑：跳到子函数后第一条有效指令前需要插一条 NOP（mem[5] = 0），原因是指令存储器上升沿取指、PC 下降沿更新，中间差半拍，不补 NOP 就会取到错的指令。

还可以做的：分支延迟槽、更多 I 型指令、对 testbench 加自动断言而不是只看波形。