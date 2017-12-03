`include "CPU.vh"

// Asynchronous ROM (Program Memory)

// COMMAND GROUP
`define NOP 4'b0000
`define JMP 4'b1000
`define ATC 4'b0100
`define MOV 4'b0010
`define ACC 4'b0001

// Commands JMP
`define UNC 3'b000
`define EQ 3'b010
`define ULT 3'b100
`define SLT 3'b101
`define ULE 3'b110
`define SLE 3'b111

// Commands MOV
`define PUR 3'b000
`define SHL 3'b001
`define SHR 3'b010

// Commands ACC
`define UAD 3'b000
`define SAD 3'b001
`define UMT 3'b010
`define SMT 3'b011
`define AND 3'b100
`define OR 3'b101
`define XOR 3'b110


`define NUM 2'b00
`define REG 2'b01
`define N8 8'd0
`define DOUT 8'd30
`define GOUT 8'd29
`define FLAG 8'd31

`define REG 2'b01
`define IND 2'b10
`define N10 10'd0
`define REG0 8'd0
`define REG1 8'd1
`define REG2 8'd2
`define REG3 8'd3
`define REG4 8'd4
`define RDIN 8'd28
`define ZERO 8'd0
`define ONE 8'd1
`define EIGHT 8'd8

module AsyncROM(input [7:0] addr, output reg [34:0] data);
	always@(addr)
		case(addr)
			0: data = {`JMP,`ULT,`REG,`GOUT,`REG,`REG4,8'd54};
			1: data = atc(3'd0,8'd46);								// Check MULT
			2: data = atc(3'd1,8'd33);								// Check ADD
			3: data = atc(3'd2,8'd21);								// Check POP
			4: data = atc(3'd3,8'd6);								// Check PUSH -----
			5: data = jmp(8'd0);									// Back to loop   | 
			/********************** PUSH *************************/ 				  
			6: data = mov(`REG2,`REG3);								// R2 -> R3 <-----|
			7: data = mov(`REG1,`REG2);								// R1 -> R2
			8: data = mov(`REG0,`REG1);								// R0 -> R1
			9: data = mov(`RDIN,`REG0);								// RDIN -> R0
			10: data = mov(`REG0,`DOUT);								// R0 -> RDOUT
			11: data = {`JMP,`EQ,`REG,`REG4,`NUM,`EIGHT,8'd17}; 	// Stack FULL ? 17 : IP+1
			12: data = {`JMP,`EQ,`REG,`REG4,`NUM,`ZERO,8'd19};		// Stack EMPTY ? 19 : IP+1
			13: data = {`MOV,`SHL,`REG,`REG4,`REG,`REG4,`N8};		// R4 <<
			14: data = mov(`REG4,`GOUT);							// R4 -> RGOUT
			15: data = set_bit(`GOUT,3'd7);							// Set ENABLE
			16: data = jmp(`ZERO);									// Back to Loop
			17: data = set_bit(`GOUT,3'd4);							// Set OVERFLOW STACK bit
			18: data = jmp(`ZERO);									// Back to Loop
			19: data = set(`REG4,`ONE);								// Set R4 = 8'd1
			20: data = jmp(8'd14);									// Jump to 14
			/*****************************************************/

			/*********************** POP *************************/
			21: data = {`JMP,`EQ,`REG,`REG4,`NUM,`ZERO,8'd31};		// Stack EMPTY ? 31 : IP+1
			22: data = mov(`REG1,`REG0);							// R1 -> R0
			23: data = mov(`REG2,`REG1);							// R2 -> R1
			24: data = mov(`REG3,`REG2);							// R3 -> R2
			25: data = mov(`REG0,`DOUT);							// R0 -> RDOUT
			26: data = {`MOV,`SHR,`REG,`REG4,`REG,`REG4,`N8};		// R4 >> 
			27: data = mov(`REG4,`GOUT);							// R4 -> GOUT
			28: data = {`JMP,`EQ,`REG,`REG4,`NUM,`ZERO,8'd31};		// Stack EMPTY ? 31 : IP+1
			29: data = set_bit(`GOUT,3'd7);							// Set ENABLE
			30: data = jmp(`ZERO);									// Back to Loop
			31: data = clr_bit(`GOUT,3'd7);							// Clear ENABLE
			32: data = jmp(`ZERO);									// Back to Loop
			/*****************************************************/

			/*********************** ADD *************************/
			33: data = clr_bit(`GOUT,3'd5);							// Clear ARITHMETIC OVERFLOW
			34: data = {`JMP,`ULT,`REG,`REG4,`NUM,8'd2,8'd0};		// Stack > 1 Element ? IP+1: 0 
			35: data = {`ACC,`SAD,`REG,`REG0,`REG,`REG1,`N8};		// RO + R1
			36: data = mov(`REG0,`DOUT);							// R0 -> RDOUT
			37: data = mov(`REG2,`REG1);							// R2 -> R1
			38: data = mov(`REG3,`REG2);							// R3 -> R2
			39: data = {`MOV,`SHR,`REG,`REG4,`REG,`REG4,`N8};		// R4 >>
			40: data = mov(`REG4,`GOUT);							// R4 -> RGOUT
			41: data = set_bit(`GOUT,3'd7);							// Set ENABLE
			42: data = atc(3'd4,8'd44);								// ARITHMETHIC OVERFLOW ? 44: IP+1
			43: data = jmp(`ZERO);									// Back to Loop
			44: data = set_bit(`GOUT,3'd5);							// Set ARITHMETIC OVERFLOW Led
			45: data = jmp(`ZERO);									// Back to Loop
			/*****************************************************/

			/************************ MULT ***********************/
			46: data = {`JMP,`EQ,`REG,`REG4,`NUM,8'd0,8'd0};		// Stack EMPTY ? 0:IP+1
			47: data = clr_bit(`GOUT,3'd5);							// Clear ARITHMETIC OVERFLOW bit
			48: data = {`JMP,`EQ,`REG,`REG4,`NUM,8'd1,8'd51};		// Stack == 1 Element ? 51:IP+1
			49: data = {`ACC,`SMT,`REG,`REG0,`REG,`REG1,`N8};		// R0 = R0*R1
			50: data = jmp(8'd36);									// Same instructions as Addition	
			51: data = set(`ZERO,`REG0);							// R0 = 0
			52: data = mov(`REG0,`DOUT);							// R0 -> RDOUT
			53: data = jmp(`ZERO);									// Back to loop
			/*****************************************************/

			/*********************** RESET ***********************/
			54: data = set(`REG4,`ZERO);
			55: data = jmp(`ZERO);
			/*****************************************************/
			
			default: data = 35'd0;

		endcase

	function [34:0] set;
		input [7:0] reg_num;
		input [7:0] value;
		set = {`MOV,`PUR,`NUM,value,`REG,reg_num,`N8};
	endfunction

	function [34:0] mov;
		input [7:0] src_reg;
		input [7:0] dst_reg;
		mov = {`MOV,`PUR,`REG,src_reg,`REG,dst_reg,`N8};
	endfunction

	function [34:0] jmp;
		input [7:0] addr;
		jmp = {`JMP,`UNC,`N10,`N10,addr};
	endfunction

	function [34:0] atc;
		input [2:0] pos;
		input [7:0] addr;
		atc = {`ATC,pos,`N10,`N10,addr};
	endfunction

	function [34:0] acc;
		input [2:0] op;
		input [7:0] reg_num;
		input [7:0] value;
		acc = {`ACC,op,`REG,reg_num,`NUM,value,`N8};
	endfunction

	function [34:0] set_bit;
		input [7:0] reg_num;
		input [2:0] pos;
		set_bit = {`ACC,`OR,`REG,reg_num,`NUM,8'b1<<pos,`N8};
	endfunction

	function [34:0] clr_bit;
		input [7:0] reg_num;
		input [2:0] pos;
		clr_bit = {`ACC,`AND,`REG,reg_num,`NUM,~(8'b1<<pos),`N8};
	endfunction
		
endmodule


