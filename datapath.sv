//Resettable Flip-Flop Module
module flopr # (parameter WIDTH = 8)
		(input clk, reset,
		input [WIDTH-1:0] d,
		output reg [WIDTH-1:0] q);

always @ (posedge clk, posedge reset)
	if (reset) q  <= 0;
	else q  <= d;
endmodule


//Adder Module
module adder (input [31:0] a, b,
	output [31:0] y);

assign y = a + b;
endmodule

//Left Shift Module
module sl2 (input [31:0] a,
	    output [31:0] y);

assign y = {a[29:01], 2'b00};
endmodule

//Multiplexer Module
module mux2 # (parameter WIDTH = 8)
	      (input [WIDTH-1:0] d0, d1,
               input s,
               output [WIDTH-1:0] y);

assign y = s ? d1 : d0;
endmodule

//Register File Module
module regfile (input clk,
		input we3,
		input [4:0] ra1, ra2, wa3,
		input [31:0] wd3,
		output [31:0] rd1, rd2);

reg [31:0] rf[31:0];

always @ (posedge clk)
	if (we3) rf[wa3]  <= wd3;

assign rd1 = (ra1 != 0) ? rf[ra1] : 0;
assign rd2 = (ra2 != 0) ? rf[ra2] : 0;
endmodule

//Sign Extension Module
module signext (input [15:0] a,
		output [31:0] y);

assign y = {{16{a[15]}}, a};
endmodule

//ALU Module
module alu (input [31:0] a,
  	    input [31:0] b,
  	    input [2:0] alucontrol,
  	    output reg [31:0] y,
  	    output reg zero);

  always @* begin
    case (alucontrol)
      3'b000: y = a & b;         // AND
      3'b001: y = a | b;         // OR
      3'b010: y = a + b;         // ADD
      3'b110: y = a - b;         // SUBTRACT
      3'b111: y = a < b ? 1 : 0; // SET LESS THAN
      default: y = 32'b0;        // Default to 0 for unimplemented cases
    endcase
    
    zero = (y == 0); // Set zero flag
  end
endmodule

//Datapath Module
module datapath(input logic clk, reset,
		input logic memtoreg, pcsrc,
		input logic alusrc, regdst,
		input logic regwrite, jump,
		input logic [2:0] alucontrol,
		output logic zero,
		output logic [31:0] pc,
		input logic [31:0] instr,
		output logic [31:0] aluout, writedata,
		input logic [31:0] readdata);
  
wire [4:0] writereg;
wire [31:0] pcnext, pcnextbr, pcplus4, pcbranch;
wire [31:0] signimm, signimmsh;
wire [31:0] srca, srcb;
wire [31:0] result;

flopr #(32) pcreg(clk, reset, pcnext, pc);
  
adder pcadd1 (pc, 32'b100, pcplus4);
  
sl2 immsh(signimm, signimmsh);
  
adder pcadd2(pcplus4, signimmsh, pcbranch);
  
mux2 #(32) pcbrmux(pcplus4, pcbranch, pcsrc, pcnextbr);
  
mux2 #(32) pcmux(pcnextbr, {pcplus4[31:28],
                            instr[25:0], 2'b00},
jump, pcnext);

regfile rf(clk, regwrite, instr[25:21],
instr[20:16], writereg,
result, srca, writedata);
  
mux2 #(5) wrmux(instr[20:16], instr[15:11],
regdst, writereg);
  
mux2 #(32) resmux(aluout, readdata,
memtoreg, result);
  
signext se(instr[15:0], signimm);
  
mux2 #(32) srcbmux(writedata, signimm, alusrc,
srcb);
  
alu alu(srca, srcb, alucontrol,
aluout, zero);

endmodule
