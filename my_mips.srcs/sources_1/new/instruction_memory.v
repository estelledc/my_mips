module instruction_memory(
    input clk,
    input [5:0] addr,
    output reg [31:0] instruction
);

    reg [31:0] mem [0:63];
    
    // ��ʼ��ָ��洢��?
    initial begin
        // ���Գ��������?
        mem[0] = 32'h00000000;
        mem[1] = 32'h00432020; // add $4,$2,$3
        mem[2] = 32'h8c440004; // lw $4,4($2)
        mem[3] = 32'hac450008; // sw $5,8($2)
//        mem[3] = 32'h0c000000;
        mem[4] = 32'h00831022; // sub $2,$4,$3
        mem[5] = 32'h00831025; // or $2,$4,$3
        mem[6] = 32'h00831024; // and $2,$4,$3
        mem[7] = 32'h0083102a; // slt $2,$4,$3
        mem[8] = 32'h10630001; // beq $3,$3,equ (PC+1+1)
        mem[9] = 32'h8c620000; // lw $2,0($3)
//        equ:
        mem[10] = 32'h10640001; // beq $3,$4,exit (PC+1+1)
        mem[11] = 32'hac620000; // sw $2,0($3)
//        exit:
        mem[12] = 32'h08000000; // j main (PC = 0)
        
        // ��չָ��
        mem[13] = 32'h2062000a; // addi $2,$3,10
        mem[14] = 32'h3462000f; // ori $2,$3,0xf
        mem[15] = 32'h80420000; // lb $2,0($2)
        mem[16] = 32'h90420000; // lbu $2,0($2)
        mem[17] = 32'h84420000; // lh $2,0($2)
        mem[18] = 32'h94420000; // lhu $2,0($2)
        mem[19] = 32'h14640001; // bne $3,$4,exit (PC+1+1)
        mem[20] = 32'h04600001; // bltz $3,exit (PC+1+1)
        mem[21] = 32'h04610001; // bgez $3,exit (PC+1+1)
        mem[22] = 32'h0c000000; // jal 0
        mem[23] = 32'h03e00008; // jr $31
    end
    
    always @(posedge clk) begin
        instruction <= mem[addr];
    end
endmodule