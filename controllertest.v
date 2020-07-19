module testbench();

    reg         clk;
    reg         reset;
    reg         zero;
    reg [5:0]  op, funct;

    wire        memwrite, pcen, irwrite, regwrite,
                alusrca, iord, memtoreg, regdst;
    wire [1:0]  alusrcb, pcsrc;
    wire [2:0]  alucontrol;

    controller dut(clk, reset, op, funct, zero, pcen, memwrite,
                    irwrite, regwrite, alusrca, iord, memtoreg, regdst,
                    alusrcb, pcsrc, alucontrol);

    initial
        begin
            reset <= 1; # 10; reset <= 0;
        end

    always
        begin
            clk <= 1; # 5; clk <= 0; # 5;
        end

    initial
        begin
            op = 6'b100011; funct = 6'bx; zero = 0; // lw
            #50 op = 6'b101011; funct = 6'bx; zero = 0; // sw
            #40 op = 6'b000100; funct = 6'bx; zero = 0; // beq
            #30 op = 6'b000100; funct = 6'bx; zero = 1; // beq
            #30 op = 6'b001000; funct = 6'bx; zero = 0; // addi
            #40 op = 6'b000010; funct = 6'bx; zero = 0; // j
            #30 op = 6'b000000; funct = 6'b100000; zero = 0; // add
            #40 op = 6'b000000; funct = 6'b100010; zero = 0; // sub
            #40 op = 6'b000000; funct = 6'b100100; zero = 0; // and
            #40 op = 6'b000000; funct = 6'b100101; zero = 0; // or
            #40 op = 6'b000000; funct = 6'b101010; zero = 0; // slt
            #40 $finish;
        end


    initial begin
            $dumpfile("controller.vcd");
            $dumpvars;
    end

endmodule