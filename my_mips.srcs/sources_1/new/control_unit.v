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

    always @(*) begin
        case (opcode)
            6'b000000: begin // R-type
                reg_dst = 2'b01;
                alu_src = 1'b0;
                mem_to_reg = 2'b00;
                reg_write = 1'b1;
                mem_write = 1'b0;
                branch = 1'b0;
                jump = 1'b0;
                
                case (funct)
                    6'b100000: alu_control = 4'b0010; // ADD
                    6'b100010: alu_control = 4'b0110; // SUB
                    6'b100100: alu_control = 4'b0000; // AND
                    6'b100101: alu_control = 4'b0001; // OR
                    6'b101010: alu_control = 4'b0111; // SLT
                    6'b001000: begin alu_control = 4'b0000; jump = 1'b1; reg_write = 1'b0; end // JR
                    default: alu_control = 4'b0000;
                endcase
            end
            
            6'b100011: begin // LW
                reg_dst = 2'b00;
                alu_src = 1'b1;
                mem_to_reg = 2'b01;
                reg_write = 1'b1;
                mem_write = 1'b0;
                alu_control = 4'b0010;
                branch = 1'b0;
                jump = 1'b0;
            end
            
            6'b101011: begin // SW
                reg_dst = 2'b00;
                alu_src = 1'b1;
                mem_to_reg = 2'b00;
                reg_write = 1'b0;
                mem_write = 1'b1;
                alu_control = 4'b0010;
                branch = 1'b0;
                jump = 1'b0;
            end
            
            6'b000100: begin // BEQ
                reg_dst = 2'b00;
                alu_src = 1'b0;
                mem_to_reg = 2'b00;
                reg_write = 1'b0;
                mem_write = 1'b0;
                alu_control = 4'b0110;
                branch = 1'b1;
                jump = 1'b0;
            end
            
            6'b000101: begin // BNE
                reg_dst = 2'b00;
                alu_src = 1'b0;
                mem_to_reg = 2'b00;
                reg_write = 1'b0;
                mem_write = 1'b0;
                alu_control = 4'b0110;
                branch = 1'b1;
                jump = 1'b0;
            end
            
            6'b000010: begin // J
                reg_dst = 2'b00;
                alu_src = 1'b0;
                mem_to_reg = 2'b00;
                reg_write = 1'b0;
                mem_write = 1'b0;
                alu_control = 4'b0000;
                branch = 1'b0;
                jump = 1'b1;
            end
            
            6'b000011: begin // JAL
                reg_dst = 2'b10;
                alu_src = 1'b0;
                mem_to_reg = 2'b10;
                reg_write = 1'b1;
                mem_write = 1'b0;
                alu_control = 4'b0000;
                branch = 1'b0;
                jump = 1'b1;
            end
            
            6'b001000: begin // ADDI
                reg_dst = 2'b00;
                alu_src = 1'b1;
                mem_to_reg = 2'b00;
                reg_write = 1'b1;
                mem_write = 1'b0;
                alu_control = 4'b0010;
                branch = 1'b0;
                jump = 1'b0;
            end
            
            6'b001101: begin // ORI
                reg_dst = 2'b00;
                alu_src = 1'b1;
                mem_to_reg = 2'b00;
                reg_write = 1'b1;
                mem_write = 1'b0;
                alu_control = 4'b0001;
                branch = 1'b0;
                jump = 1'b0;
            end
            
            6'b100000: begin // LB
                reg_dst = 2'b00;
                alu_src = 1'b1;
                mem_to_reg = 2'b01;
                reg_write = 1'b1;
                mem_write = 1'b0;
                alu_control = 4'b0010;
                branch = 1'b0;
                jump = 1'b0;
            end
            
            6'b100100: begin // LBU
                reg_dst = 2'b00;
                alu_src = 1'b1;
                mem_to_reg = 2'b01;
                reg_write = 1'b1;
                mem_write = 1'b0;
                alu_control = 4'b0010;
                branch = 1'b0;
                jump = 1'b0;
            end
            
            6'b100001: begin // LH
                reg_dst = 2'b00;
                alu_src = 1'b1;
                mem_to_reg = 2'b01;
                reg_write = 1'b1;
                mem_write = 1'b0;
                alu_control = 4'b0010;
                branch = 1'b0;
                jump = 1'b0;
            end
            
            6'b100101: begin // LHU
                reg_dst = 2'b00;
                alu_src = 1'b1;
                mem_to_reg = 2'b01;
                reg_write = 1'b1;
                mem_write = 1'b0;
                alu_control = 4'b0010;
                branch = 1'b0;
                jump = 1'b0;
            end
            
            6'b000001: begin // BLTZ/BGEZ
                reg_dst = 2'b00;
                alu_src = 1'b0;
                mem_to_reg = 2'b00;
                reg_write = 1'b0;
                mem_write = 1'b0;
                alu_control = 4'b0111;
                branch = 1'b1;
                jump = 1'b0;
            end
            
            default: begin
                reg_dst = 2'b00;
                alu_src = 1'b0;
                mem_to_reg = 2'b00;
                reg_write = 1'b0;
                mem_write = 1'b0;
                alu_control = 4'b0000;
                branch = 1'b0;
                jump = 1'b0;
            end
        endcase
    end
endmodule