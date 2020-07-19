module controller(input        clk, reset,
                  input  [5:0] op, funct,
                  input        zero,
                  output       pcen, memwrite, irwrite, regwrite,
                  output       alusrca, iord, memtoreg, regdst,
                  output [1:0] alusrcb, pcsrc,
                  output [2:0] alucontrol);

  wire [1:0] aluop;
  wire       branch, pcwrite;

  // Main Decoder and ALU Decoder subunits.
  maindec md(clk, reset, op,
             pcwrite, memwrite, irwrite, regwrite,
             alusrca, branch, iord, memtoreg, regdst,
             alusrcb, pcsrc, aluop);
  aludec  ad(funct, aluop, alucontrol);

  // Add combinational logic (i.e. an assign statement)
  // to produce the PCEn signal (pcen) from the branch,
  // zero, and pcwrite signals

  assign pcen = (branch & zero) | pcwrite;

endmodule

module maindec(input        clk, reset,
               input  [5:0] op,
               output       pcwrite, memwrite, irwrite, regwrite,
               output       alusrca, branch, iord, memtoreg, regdst,
               output [1:0] alusrcb, pcsrc,
               output [1:0] aluop);

  parameter   FETCH   = 4'b0000;  // State 0
  parameter   DECODE  = 4'b0001;  // State 1
  parameter   MEMADR  = 4'b0010;	// State 2
  parameter   MEMRD   = 4'b0011;	// State 3
  parameter   MEMWB   = 4'b0100;	// State 4
  parameter   MEMWR   = 4'b0101;	// State 5
  parameter   RTYPEEX = 4'b0110;	// State 6
  parameter   RTYPEWB = 4'b0111;	// State 7
  parameter   BEQEX   = 4'b1000;	// State 8
  parameter   ADDIEX  = 4'b1001;	// State 9
  parameter   ADDIWB  = 4'b1010;	// state 10
  parameter   JEX     = 4'b1011;	// State 11

  parameter   LW      = 6'b100011;	// Opcode for lw
  parameter   SW      = 6'b101011;	// Opcode for sw
  parameter   RTYPE   = 6'b000000;	// Opcode for R-type
  parameter   BEQ     = 6'b000100;	// Opcode for beq
  parameter   ADDI    = 6'b001000;	// Opcode for addi
  parameter   J       = 6'b000010;	// Opcode for j

  reg [3:0]  state, nextstate;
  reg [14:0] controls;

  // state register
  always @(posedge clk or posedge reset)
    if(reset) state <= FETCH;
    else state <= nextstate;

  // next state logic
  always @(*)
    case(state)
      FETCH:   nextstate <= DECODE;
      DECODE:  case(op)
                  LW:      nextstate <= MEMADR;
                  SW:      nextstate <= MEMADR;
                  RTYPE:   nextstate <= RTYPEEX;
                  BEQ:     nextstate <= BEQEX;
                  ADDI:    nextstate <= ADDIEX;
                  J:       nextstate <= JEX;
                  default: nextstate <= 4'bx; // should never happen
               endcase
      MEMADR:  case(op)
                  LW:      nextstate <= MEMRD;
                  SW:      nextstate <= MEMWR;
                  default: nextstate <= 4'bx; // should never happen
                endcase
      MEMRD:   nextstate <= MEMWB;
      MEMWB:   nextstate <= FETCH;
      MEMWR:   nextstate <= FETCH;
      RTYPEEX: nextstate <= RTYPEWB;
      RTYPEWB: nextstate <= FETCH;
      BEQEX:   nextstate <= FETCH;
      ADDIEX:  nextstate <= ADDIWB;
      ADDIWB:  nextstate <= FETCH;
      JEX:     nextstate <= FETCH;
      default: nextstate <= 4'bx; // should never happen
    endcase

  // output logic
  assign {pcwrite, memwrite, irwrite, regwrite,
          alusrca, branch, iord, memtoreg,
          regdst, alusrcb, pcsrc, aluop} = controls;

    always @ (*)
    case(state)
      FETCH:     controls <= 15'h5010;     //S0
      DECODE:    controls <= 15'h0030;     //S1
      MEMADR:    controls <= 15'h0420;     //S2
      MEMRD:     controls <= 15'h0100;     //S3
      MEMWB:     controls <= 15'h0880;     //S4
      MEMWR:     controls <= 15'h2100;     //S5
      RTYPEEX:   controls <= 15'h0402;     //S6
      RTYPEWB:   controls <= 15'h0840;     //S7
      BEQEX:     controls <= 15'h0605;     //S8
      ADDIEX:    controls <= 15'h0420;     //S9
      ADDIWB:    controls <= 15'h0800;     //S10
      JEX:       controls <= 15'h4008;     //S11
      default:   controls <= 15'hxxxx;     //should never happen
    endcase
endmodule

module aludec(input  [5:0] funct,
              input  [1:0] aluop,
              output reg [2:0] alucontrol);

  always@(*)
    case(aluop)
      2'b00: alucontrol <= 3'b010;  // add
      2'b01: alucontrol <= 3'b011;  // sub
      2'b11: alucontrol <= 3'b001;  // ori
      default: case(funct)           // 10 RTYPE
          6'b100000: alucontrol <= 3'b010; // ADD
          6'b100010: alucontrol <= 3'b110; // SUB
          6'b100100: alucontrol <= 3'b000; // AND
          6'b100101: alucontrol <= 3'b001; // OR
          6'b101010: alucontrol <= 3'b111; // SLT
          default:   alucontrol <= 4'bxxxx; // ???
        endcase
    endcase

endmodule