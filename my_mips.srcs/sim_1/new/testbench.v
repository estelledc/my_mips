`timescale 1ns/1ps

module mips_cpu_tb;

    reg clk;
    reg reset;
    integer cycle_count = 0;
    reg [31:0] prev_regs [0:31];
    reg [31:0] prev_mem [0:63];
    
    // ʵ����CPU
    mips_cpu cpu(.clk(clk), .reset(reset));
    
    // ʱ������
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("cpu_trace.vcd");
        $dumpvars(0, mips_cpu_tb);
        
        // �����Զ����
        $monitor("ʱ��=%0t: PC=%h, ָ��=%h, ALU=%h", 
                 $time, cpu.pc, cpu.instruction, cpu.alu_result);
    end
    
    // �����źż��
    always @(cpu.reg_write_en) begin
        if (cpu.reg_write_en)
            $display("�Ĵ���д��ʹ�ܼ���: д��r%d, ֵ=%h", cpu.write_reg, cpu.reg_write_data);
    end
    // ��ȷ��reset����
    initial begin
        // ��ʼ�����мĴ������ڴ��"previous"ֵ
        for (integer i = 0; i < 32; i = i + 1) begin
            prev_regs[i] = 0;
        end
        for (integer i = 0; i < 64; i = i + 1) begin
            prev_mem[i] = 0;
        end
        
        // Ӧ��reset
        reset = 1;
        #20;  // ����resetһ��ʱ��
        reset = 0;
        
        // �����㹻����ʱ��
        #500;
        $finish;
    end
    
    // R��ָ����븨������
    function [64:0] get_r_type_name;
        input [5:0] funct;
        begin
            case (funct)
                6'b100000: get_r_type_name = "ADD";
                6'b100010: get_r_type_name = "SUB";
                6'b100100: get_r_type_name = "AND";
                6'b100101: get_r_type_name = "OR";
                6'b101010: get_r_type_name = "SLT";
                6'b001000: get_r_type_name = "JR";
                default: get_r_type_name = "δ֪R��";
            endcase
        end
    endfunction
    
    // ���ÿ�����ڵı仯
    always @(posedge clk) begin
        if (!reset) begin
            cycle_count = cycle_count + 1;
            
            // ��ʾ��ǰ������Ϣ
            $display("\n==== ���� %0d ====", cycle_count);
            $display("PC = %h, ָ�� = %h", cpu.pc, cpu.instruction);
            
            // ��ʾ�����ź�
            $display("�����ź�: opcode=%b, funct=%b", 
                     cpu.instruction[31:26], cpu.instruction[5:0]);
            $display("reg_dst=%b, alu_src=%b, mem_to_reg=%b, reg_write=%b, mem_write=%b", 
                     cpu.control.reg_dst, cpu.control.alu_src, 
                     cpu.control.mem_to_reg, cpu.control.reg_write, 
                     cpu.control.mem_write);
            $display("alu_control=%b, branch=%b, jump=%b",
                     cpu.control.alu_control, cpu.control.branch, 
                     cpu.control.jump);
            
            // ����ָ������
            case (cpu.instruction[31:26])
                6'b000000: $display("R��ָ��: %s", get_r_type_name(cpu.instruction[5:0]));
                6'b100011: $display("ָ��: LW r%0d, %0d(r%0d)", cpu.instruction[20:16], $signed(cpu.instruction[15:0]), cpu.instruction[25:21]);
                6'b101011: $display("ָ��: SW r%0d, %0d(r%0d)", cpu.instruction[20:16], $signed(cpu.instruction[15:0]), cpu.instruction[25:21]);
                6'b000100: $display("ָ��: BEQ r%0d, r%0d, %0d", cpu.instruction[25:21], cpu.instruction[20:16], $signed(cpu.instruction[15:0]));
                6'b000101: $display("ָ��: BNE r%0d, r%0d, %0d", cpu.instruction[25:21], cpu.instruction[20:16], $signed(cpu.instruction[15:0]));
                6'b000010: $display("ָ��: J %h", {cpu.pc[31:28], cpu.instruction[25:0], 2'b00});
                6'b001000: $display("ָ��: ADDI r%0d, r%0d, %0d", cpu.instruction[20:16], cpu.instruction[25:21], $signed(cpu.instruction[15:0]));
                6'b001101: $display("ָ��: ORI r%0d, r%0d, %0d", cpu.instruction[20:16], cpu.instruction[25:21], cpu.instruction[15:0]);
                default: $display("����ָ������");
            endcase
            
            // ��ʾ�Ĵ����仯
            $display("�Ĵ����仯:");
            for (integer i = 0; i < 32; i = i + 1) begin
                if (prev_regs[i] != cpu.registers.registers[i]) begin
                    $display("  r%0d: %h -> %h", i, prev_regs[i], cpu.registers.registers[i]);
                    prev_regs[i] = cpu.registers.registers[i];
                end
            end
            
            // ��ʾ�ڴ�仯
            $display("�ڴ�仯:");
            for (integer i = 0; i < 64; i = i + 1) begin
                if (prev_mem[i] != cpu.dmem.mem[i]) begin
                    $display("  mem[%0d]: %h -> %h", i, prev_mem[i], cpu.dmem.mem[i]);
                    prev_mem[i] = cpu.dmem.mem[i];
                end
            end
            
            // ALU���
            $display("ALU: a=%h, b=%h, result=%h, zero=%b", 
                     cpu.reg_data1, 
                     cpu.alu_src ? cpu.sign_extend : cpu.reg_data2, 
                     cpu.alu_result, 
                     cpu.zero);
            
            $display("Next PC = %h", cpu.next_pc);
        end
    end
endmodule