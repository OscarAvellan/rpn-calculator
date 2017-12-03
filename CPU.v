`include "CPU.vh"

// CPU Module

`define REG 2'b01
`define IND 2'b10
`define SHFT 3'd5
`define OVFL 3'd4
`define SMPL 3'd3
`define DVAL 3'd7
`define DOUT 8'd30
`define DINP 8'd28

module CPU( 
	
	// Data In
	input [7:0] Din,
	
	// Buttons
	input [2:0] Btns,
	
	input Clock,
	input Reset,
	input Turbo,
	input Sample,
	
	// Data out
	output wire [7:0]Dout,
	
	// Data Valid
	output Dval,
	
	// General Purpose Output
	output wire [5:0] GPO,
	
	output [3:0] Debug,
	
	// Instruction Pointer
	output reg [7:0] IP = 8'b0
	
);
					
	wire turbo_safe;
	Synchroniser tbo(Clock,Turbo,turbo_safe);

	/**************** Step 1 ****************/
	wire [7:0] din_safe;

	Synchroniser din0(Clock,Din[0],din_safe[0]);
	Synchroniser din1(Clock,Din[1],din_safe[1]);
	Synchroniser din2(Clock,Din[2],din_safe[2]);
	Synchroniser din3(Clock,Din[3],din_safe[3]);
	Synchroniser din4(Clock,Din[4],din_safe[4]);
	Synchroniser din5(Clock,Din[5],din_safe[5]);
	Synchroniser din6(Clock,Din[6],din_safe[6]);
	Synchroniser din7(Clock,Din[7],din_safe[7]);

	wire [3:0] pb_safe;

	Synchroniser btn0(Clock,Btns[0],pb_safe[0]);
	Synchroniser btn1(Clock,Btns[1],pb_safe[1]);
	Synchroniser btn2(Clock,Btns[2],pb_safe[2]);
	Synchroniser smpl(Clock,Sample,pb_safe[3]);

	/****************************************/

	/**************** Step 3 ****************/
	genvar i;
	wire [3:0] pb_activated;
	generate
		for( i=0; i<=3; i=i+1) begin:pb
			DetectFallingEdge dfe(Clock,pb_safe[i],pb_activated[i]);
		end
	endgenerate
	/****************************************/


	reg [26:0] count = 27'd1;
	localparam countMax = 27'd1_499_999;

	always@(posedge Clock)
		count <= (count == countMax) ? 27'd0:count+27'd1;
		
	wire go = !Reset && ((count == 0) || turbo_safe);

	wire [34:0] instruction;
	AsyncROM Pmem(IP,instruction);

	//Registers
	reg [7:0] Reg[0:31];

	//Special Registers
	wire[7:0] Rgout = Reg[29];
	wire[7:0] Rdout = Reg[30];
	wire[7:0] Rflag = Reg[31];

	assign Dval = Rgout[`DVAL];

	assign Debug[3] = Rflag[`SHFT];
	assign Debug[2] = Rflag[`OVFL];
	assign Debug[1] = Rflag[`SMPL];
	assign Debug[0] = go;

	// Use these to write to the FLAGS and DIN registers
	`define RFLAG Reg[31]
	`define RDINP Reg[28]

	// Connect certain registers to the external world
	assign Dout = Rdout;
	assign GPO = Rgout[5:0];

	initial Reg[4] = 8'd0;

	// Instruction Cycle
	wire [3:0] cmd_grp = instruction[34:31];
	wire [2:0] cmd = instruction[30:28];
	wire [1:0] arg1_typ = instruction[27:26];
	wire [7:0] arg1 = instruction[25:18];
	wire [1:0] arg2_typ = instruction[17:16];
	wire [7:0] arg2 = instruction[15:8];
	wire [7:0] addr = instruction[7:0];

	reg [7:0] cnum,cloc;
	reg [16:0] word;
	reg signed [14:0] s_word;
	reg cond;
	reg [3:0] j;

	always@(posedge Clock) begin
		if(go) begin
			IP <= IP + 8'b1;
			case(cmd_grp)
				`MOV: begin
						cnum = get_number(arg1_typ,arg1);
						case(cmd)
							`SHL:begin
								`RFLAG[`SHFT] <= cnum[7];
								cnum = {cnum[6:0],1'b0};
							end
							`SHR:begin
								`RFLAG[`SHFT] <= cnum[0];
								cnum = {1'b0,cnum[7:1]};
							end
						endcase
						Reg[get_location(arg2_typ,arg2)] <= cnum;
				end

				`JMP: begin
					case(cmd)
						`UNC:	cond = 1;
						`EQ:	cond = (get_number(arg1_typ,arg1) == get_number(arg2_typ,arg2));
						`ULT:	cond = (get_number(arg1_typ,arg1) < get_number(arg2_typ,arg2));
						`SLT:	cond = ( $signed(get_number(arg1_typ,arg1)) < $signed(get_number(arg2_typ,arg2)) );
						`ULE:	cond = (get_number(arg1_typ,arg1) <= get_number(arg2_typ,arg2));
						`SLE:	cond = ( $signed(get_number(arg1_typ,arg1)) <= $signed(get_number(arg2_typ,arg2)) );
						default: cond = 0;
					endcase
					if(cond) IP <= addr;
				end

				`ACC: begin
					cnum = get_number(arg2_typ,arg2);
					cloc = get_location(arg1_typ,arg1);
					case(cmd)
						`UAD: word = Reg[cloc] + cnum;
						`SAD: s_word = $signed(Reg[cloc]) + $signed(cnum);
						`UMT: word = Reg[cloc] * cnum;
						`SMT: s_word = $signed(Reg[cloc]) * $signed(cnum);
						`AND: cnum = Reg[cloc] & cnum;
						`OR:  cnum = Reg[cloc] | cnum;
						`XOR: cnum = Reg[cloc] ^ cnum;
					endcase

					if(cmd[2] == 0)
						if(cmd[0] == 0) begin
							cnum = word[7:0];
							`RFLAG[`OFLW] <= (word > 255);
						end
						else begin
							cnum = s_word[7:0];
							`RFLAG[`OFLW] <= (s_word > 127 || s_word < -128);
						end
					Reg[cloc] <= cnum;

				end

				`ATC: begin
					if(`RFLAG[cmd]) IP <= addr;
					`RFLAG[cmd] <= 0;
				end
			endcase
		end

		/**************** Step 3 ****************/
		if(Reset) begin
			IP <= 8'b0;
			`RFLAG <= 0;
			Reg[29] <= 0;
			Reg[20] <= 0;
			
		end
		else begin
			for(j=4'd0 ; j<=4'd3 ; j=j+4'd1) begin
				if(pb_activated[j]) `RFLAG[j] <= 1;
			end
				

			if(pb_activated[3]) `RDINP <= din_safe;
		end

		/****************************************/

	end

	function [7:0]get_number;
		input [1:0] arg_type;
		input [7:0] arg;
		begin
			case(arg_type)
				`REG: get_number = Reg[arg[5:0]];
				`IND: get_number = Reg[ Reg[ arg[5:0] ] [5:0] ];
				default: get_number = arg;
			endcase
		end

	endfunction

	function [5:0]get_location;
		input [1:0] arg_type;
		input [7:0] arg;
		begin
			case(arg_type)
				`REG: get_location = arg[5:0];
				`IND: get_location = Reg[arg[5:0]][5:0];
				default: get_location = 0;
			endcase
		end

	endfunction

endmodule