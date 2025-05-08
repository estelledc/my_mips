module pc_calculator(
    input [31:0] pc,
    input [25:0] jump_addr,
    input [31:0] branch_addr,
    input branch,
    input jump,
    input zero,
    input [31:0] reg_data1,
    input [5:0] funct,      // ���: �����ж��Ƿ�ΪJRָ��
    input [5:0] opcode,     // ���: ����ָ�������ж�
    output reg [31:0] next_pc
);

    wire [31:0] branch_offset = branch_addr << 2;
    wire [31:0] pc_plus_4 = pc + 32'd4;
    wire [31:0] branch_target = pc_plus_4 + branch_offset;
    wire [31:0] jump_target = {pc_plus_4[31:28], jump_addr, 2'b00};
    wire is_jr = (opcode == 6'b000000 && funct == 6'b001000); // �ж��Ƿ�ΪJRָ��
    
    always @(*) begin
        if (jump) begin
            if (is_jr) begin
                next_pc = reg_data1; // JRָ��: ��ת���Ĵ����еĵ�ַ
            end
            else begin
                next_pc = jump_target; // J/JALָ��: ��ת��������ָ���ĵ�ַ
            end
        end
        else if (branch && zero) begin // BEQ
            next_pc = branch_target;
        end
        else if (branch && !zero) begin // BNE
            next_pc = branch_target;
        end
        else if (branch && $signed(reg_data1) < 0) begin // BLTZ
            next_pc = branch_target;
        end
        else if (branch && $signed(reg_data1) >= 0) begin // BGEZ
            next_pc = branch_target;
        end
        else begin
            next_pc = pc_plus_4;
        end
    end
endmodule