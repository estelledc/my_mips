module mips_cpu(
    input clk,
    input reset
);

    // �ڲ��źŶ���
    wire [31:0] pc, next_pc, instruction;
    wire [31:0] reg_data1, reg_data2, alu_result, mem_read_data;
    wire [31:0] sign_extend, zero_extend;
    wire [4:0] write_reg;
    wire [31:0] reg_write_data;
    wire reg_write_en, mem_write_en;
    wire [3:0] alu_control;
    wire [1:0] reg_dst, mem_to_reg;
    wire alu_src, branch, jump, zero;
    
    // ʱ�ӱ��ؿ���
    reg clk_rise = 0, clk_fall = 0;  // ���ӳ�ʼֵ
    always @(posedge clk) clk_rise <= ~clk_rise;
    always @(negedge clk) clk_fall <= ~clk_fall;
    
    // PC�Ĵ��� (�½��ظ���)
    reg [31:0] pc_reg;
    always @(negedge clk or posedge reset) begin
        if (reset) pc_reg <= 32'b0;
        else pc_reg <= next_pc;
    end
    assign pc = pc_reg;
    
    // ָ��洢�� (�����ض�ȡ)
    instruction_memory imem(
        .clk(clk),
        .addr(pc[7:2]),
        .instruction(instruction)
    );
    
    // �Ĵ����ļ�
    reg_file registers(
        .clk(clk),
        .reset(reset),
        .read_reg1(instruction[25:21]),
        .read_reg2(instruction[20:16]),
        .write_reg(write_reg),
        .write_data(reg_write_data),
        .write_en(reg_write_en),
        .read_data1(reg_data1),
        .read_data2(reg_data2)
    );
    
    // ���Ƶ�Ԫ
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
    
    // ������չ
    sign_extend sign_ext(
        .in(instruction[15:0]),
        .out(sign_extend)
    );
    
    // ����չ
    zero_extend zero_ext(
        .in(instruction[15:0]),
        .out(zero_extend)
    );
    
    // ���ݴ洢�� (�½���д��)
    data_memory dmem(
        .clk(clk_fall),
        .reset(reset),
        .addr(alu_result[7:2]),
        .write_data(reg_data2),
        .write_en(mem_write_en),
        .read_data(mem_read_data)
    );
    
    // ��һ��PC����
    pc_calculator pc_calc(
        .pc(pc),
        .jump_addr(instruction[25:0]),
        .branch_addr(sign_extend),
        .branch(branch),
        .jump(jump),
        .zero(zero),
        .reg_data1(reg_data1),
        .funct(instruction[5:0]),    // ����: ����funct�ֶ�
        .opcode(instruction[31:26]), // ����: ����opcode�ֶ�
        .next_pc(next_pc)
    );
    
    // д�ؼĴ���ѡ��
    assign write_reg = (reg_dst == 2'b00) ? instruction[20:16] :
                      (reg_dst == 2'b01) ? instruction[15:11] :
                      5'b11111; // ����JALָ��
    
    // д������ѡ��
    assign reg_write_data = (mem_to_reg == 2'b00) ? alu_result :
                           (mem_to_reg == 2'b01) ? mem_read_data :
                           (mem_to_reg == 2'b10) ? {pc + 32'd4} :
                           zero_extend; // ����LUIָ��
endmodule