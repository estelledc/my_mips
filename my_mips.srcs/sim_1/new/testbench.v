`timescale 1ns/1ps

module mips_cpu_tb;

    reg clk;
    reg reset;
    
    // 实例化CPU
    mips_cpu cpu(.clk(clk), .reset(reset));
    
    // 时钟生成
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("cpu_trace.vcd");
        $dumpvars(0, mips_cpu_tb);
        
        // 基本监视信号
        $monitor("Time=%0t: PC=%h, Inst=%h", $time, cpu.pc, cpu.instruction);
    end
    
    // 初始化和reset配置
    initial begin
        // 应用reset
        reset = 1;
        #20;  // 保持reset一段时间
        reset = 0;
        
        // 运行足够的仿真时间
        #500;
        $finish;
    end
    
    // 保留R型指令解码函数供可能的调试使用
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