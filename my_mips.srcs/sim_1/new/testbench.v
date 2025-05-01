`timescale 1ns/1ps

module mips_cpu_tb;

    reg clk;
    reg reset;
    integer cycle_count = 0;
    reg [31:0] prev_regs [0:31];
    reg [31:0] prev_mem [0:63];
    
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
        
        // 设置自动监控
        $monitor("时间=%0t: PC=%h, 指令=%h, ALU=%h", 
                 $time, cpu.pc, cpu.instruction, cpu.alu_result);
    end
    
    // 敏感信号监控
    always @(cpu.reg_write_en) begin
        if (cpu.reg_write_en)
            $display("寄存器写入使能激活: 写入r%d, 值=%h", cpu.write_reg, cpu.reg_write_data);
    end
    // 正确的reset处理
    initial begin
        // 初始化所有寄存器和内存的"previous"值
        for (integer i = 0; i < 32; i = i + 1) begin
            prev_regs[i] = 0;
        end
        for (integer i = 0; i < 64; i = i + 1) begin
            prev_mem[i] = 0;
        end
        
        // 应用reset
        reset = 1;
        #20;  // 保持reset一段时间
        reset = 0;
        
        // 运行足够长的时间
        #500;
        $finish;
    end
    
    // R型指令解码辅助函数
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
                default: get_r_type_name = "未知R型";
            endcase
        end
    endfunction
    
    // 监控每个周期的变化
    always @(posedge clk) begin
        if (!reset) begin
            cycle_count = cycle_count + 1;
            
            // 显示当前周期信息
            $display("\n==== 周期 %0d ====", cycle_count);
            $display("PC = %h, 指令 = %h", cpu.pc, cpu.instruction);
            
            // 显示控制信号
            $display("控制信号: opcode=%b, funct=%b", 
                     cpu.instruction[31:26], cpu.instruction[5:0]);
            $display("reg_dst=%b, alu_src=%b, mem_to_reg=%b, reg_write=%b, mem_write=%b", 
                     cpu.control.reg_dst, cpu.control.alu_src, 
                     cpu.control.mem_to_reg, cpu.control.reg_write, 
                     cpu.control.mem_write);
            $display("alu_control=%b, branch=%b, jump=%b",
                     cpu.control.alu_control, cpu.control.branch, 
                     cpu.control.jump);
            
            // 解码指令类型
            case (cpu.instruction[31:26])
                6'b000000: $display("R型指令: %s", get_r_type_name(cpu.instruction[5:0]));
                6'b100011: $display("指令: LW r%0d, %0d(r%0d)", cpu.instruction[20:16], $signed(cpu.instruction[15:0]), cpu.instruction[25:21]);
                6'b101011: $display("指令: SW r%0d, %0d(r%0d)", cpu.instruction[20:16], $signed(cpu.instruction[15:0]), cpu.instruction[25:21]);
                6'b000100: $display("指令: BEQ r%0d, r%0d, %0d", cpu.instruction[25:21], cpu.instruction[20:16], $signed(cpu.instruction[15:0]));
                6'b000101: $display("指令: BNE r%0d, r%0d, %0d", cpu.instruction[25:21], cpu.instruction[20:16], $signed(cpu.instruction[15:0]));
                6'b000010: $display("指令: J %h", {cpu.pc[31:28], cpu.instruction[25:0], 2'b00});
                6'b001000: $display("指令: ADDI r%0d, r%0d, %0d", cpu.instruction[20:16], cpu.instruction[25:21], $signed(cpu.instruction[15:0]));
                6'b001101: $display("指令: ORI r%0d, r%0d, %0d", cpu.instruction[20:16], cpu.instruction[25:21], cpu.instruction[15:0]);
                default: $display("其他指令类型");
            endcase
            
            // 显示寄存器变化
            $display("寄存器变化:");
            for (integer i = 0; i < 32; i = i + 1) begin
                if (prev_regs[i] != cpu.registers.registers[i]) begin
                    $display("  r%0d: %h -> %h", i, prev_regs[i], cpu.registers.registers[i]);
                    prev_regs[i] = cpu.registers.registers[i];
                end
            end
            
            // 显示内存变化
            $display("内存变化:");
            for (integer i = 0; i < 64; i = i + 1) begin
                if (prev_mem[i] != cpu.dmem.mem[i]) begin
                    $display("  mem[%0d]: %h -> %h", i, prev_mem[i], cpu.dmem.mem[i]);
                    prev_mem[i] = cpu.dmem.mem[i];
                end
            end
            
            // ALU结果
            $display("ALU: a=%h, b=%h, result=%h, zero=%b", 
                     cpu.reg_data1, 
                     cpu.alu_src ? cpu.sign_extend : cpu.reg_data2, 
                     cpu.alu_result, 
                     cpu.zero);
            
            $display("Next PC = %h", cpu.next_pc);
        end
    end
endmodule