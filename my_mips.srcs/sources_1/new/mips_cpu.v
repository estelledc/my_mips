module mips_cpu(
    input clk,
    input reset
);

    // 内部信号定义
    wire [31:0] pc, next_pc, instruction;
    wire [31:0] reg_data1, reg_data2, alu_result, mem_read_data;
    wire [31:0] sign_extend, zero_extend;
    wire [4:0] write_reg;
    wire [31:0] reg_write_data;
    wire reg_write_en, mem_write_en;
    wire [3:0] alu_control;
    wire [1:0] reg_dst, mem_to_reg;
    wire alu_src, branch, jump, zero;
    
    // 时钟边沿控制
    reg clk_rise = 0, clk_fall = 0;  // 添加初始值
    always @(posedge clk) clk_rise <= ~clk_rise;
    always @(negedge clk) clk_fall <= ~clk_fall;
    
    // PC寄存器 (下降沿更新)
    reg [31:0] pc_reg;
    always @(negedge clk or posedge reset) begin
        if (reset) pc_reg <= 32'b0;
        else pc_reg <= next_pc;
    end
    assign pc = pc_reg;
    
    // 指令存储器 (上升沿读取)
    instruction_memory imem(
        .clk(clk),
        .addr(pc[7:2]),
        .instruction(instruction)
    );
    
    // 寄存器文件
    reg_file registers(
        .clk(clk_fall),
        .reset(reset),
        .read_reg1(instruction[25:21]),
        .read_reg2(instruction[20:16]),
        .write_reg(write_reg),
        .write_data(reg_write_data),
        .write_en(reg_write_en),
        .read_data1(reg_data1),
        .read_data2(reg_data2)
    );
    
    // 控制单元
    control_unit control(
        .opcode(instruction[31:26]),
        .funct(instruction[5:0]),
        .reg_dst(reg_dst),
        .alu_src(alu_src),
        .mem_to_reg(mem_to_reg),
        .reg_write(reg_write_en),
        .mem_write(mem_write_en),
        .alu_control(alu_control),
        .branch(branch),
        .jump(jump)
    );
    
    // ALU
    alu main_alu(
        .a(reg_data1),
        .b(alu_src ? sign_extend : reg_data2),
        .control(alu_control),
        .result(alu_result),
        .zero(zero)
    );
    
    // 符号扩展
    sign_extend sign_ext(
        .in(instruction[15:0]),
        .out(sign_extend)
    );
    
    // 零扩展
    zero_extend zero_ext(
        .in(instruction[15:0]),
        .out(zero_extend)
    );
    
    // 数据存储器 (下降沿写入)
    data_memory dmem(
        .clk(clk_fall),
        .reset(reset),
        .addr(alu_result[7:2]),
        .write_data(reg_data2),
        .write_en(mem_write_en),
        .read_data(mem_read_data)
    );
    
    // 下一条PC计算
    pc_calculator pc_calc(
        .pc(pc),
        .jump_addr(instruction[25:0]),
        .branch_addr(sign_extend),
        .branch(branch),
        .jump(jump),
        .zero(zero),
        .reg_data1(reg_data1),
        .funct(instruction[5:0]),    // 添加: 传递funct字段
        .opcode(instruction[31:26]), // 添加: 传递opcode字段
        .next_pc(next_pc)
    );
    
    // 写回寄存器选择
    assign write_reg = (reg_dst == 2'b00) ? instruction[20:16] :
                      (reg_dst == 2'b01) ? instruction[15:11] :
                      5'b11111; // 用于JAL指令
    
    // 写回数据选择
    assign reg_write_data = (mem_to_reg == 2'b00) ? alu_result :
                           (mem_to_reg == 2'b01) ? mem_read_data :
                           (mem_to_reg == 2'b10) ? {pc + 32'd4} :
                           zero_extend; // 用于LUI指令
endmodule