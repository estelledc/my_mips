`timescale 1ns/1ps

module mips_cpu_tb;

    reg clk;
    reg reset;
    
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
        
        // ���������ź�
        $monitor("Time=%0t: PC=%h, Inst=%h", $time, cpu.pc, cpu.instruction);
    end
    
    // ��ʼ����reset����
    initial begin
        // Ӧ��reset
        reset = 1;
        #20;  // ����resetһ��ʱ��
        reset = 0;
        
        // �����㹻�ķ���ʱ��
        #500;
        $finish;
    end
    
    // ����R��ָ����뺯�������ܵĵ���ʹ��
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
                default: get_r_type_name = "Unknown";
            endcase
        end
    endfunction
endmodule