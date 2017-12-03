// Add more auxillary modules here...

// Display a Hexadecimal Digit, a Negative Sign, or a Blank, on a 7-segment Display
module SSeg(input [3:0] bin, input neg, input enable, output reg [6:0] segs);
	always @(*)
		if (enable) begin
			if (neg) segs = 7'b011_1111;
			else begin
				case (bin)
					0: segs = 7'b100_0000;
					1: segs = 7'b111_1001;
					2: segs = 7'b010_0100;
					3: segs = 7'b011_0000;
					4: segs = 7'b001_1001;
					5: segs = 7'b001_0010;
					6: segs = 7'b000_0010;
					7: segs = 7'b111_1000;
					8: segs = 7'b000_0000;
					9: segs = 7'b001_1000;
					10: segs = 7'b000_1000;
					11: segs = 7'b000_0011;
					12: segs = 7'b100_0110;
					13: segs = 7'b010_0001;
					14: segs = 7'b000_0110;
					15: segs = 7'b000_1110;
				endcase
			end
		end
		else segs = 7'b111_1111;
endmodule

/********************* Debounce MODULE *********************/

module Debounce( input clock, input signalIn, output reg signalDebounced = 0);
	
	wire syncSignal;
	reg [20:0] counter = 0;
	wire enable;

	assign enable = (counter == 21'd1_499_999);
	
	Synchroniser s(.clock(clock), .signalIn(signalIn), .syncSignal(syncSignal) );

	always@(posedge clock)
		begin
			if(enable)
			signalDebounced <= syncSignal;
		end

	always@(posedge clock) 
		begin
			if(signalDebounced == syncSignal)
				counter <= 21'd0;
			else
				begin
					counter <= counter + 21'd1;
				end
		end

endmodule
/***********************************************************/

/******************** Disp2cNum MODULE *********************/

module Disp2cNum( input signed [7:0] Number,
						input enable,
						output [6:0] hex0,
						output [6:0] hex1,
						output [6:0] hex2,
						output [6:0] hex3 );

	wire neg = ( Number < 0);
	wire [7:0] toDispDec1 = neg ? -Number:Number;

	wire [7:0] d1_to_d2,d2_to_d3, d3_to_d4, d4_to_out;
	wire en1, en2, en3,en4;

	DispDec d1(.Number(toDispDec1), .neg(neg), .enable(enable),.numOut(d1_to_d2), .enOut(en1),.segs(hex0));	
	DispDec d2(.Number(d1_to_d2), .neg(neg), .enable(en1),.numOut(d2_to_d3), .enOut(en2),.segs(hex1));	
	DispDec d3(.Number(d2_to_d3), .neg(neg), .enable(en2),.numOut(d3_to_d4), .enOut(en3),.segs(hex2));	
	DispDec d4(.Number(d3_to_d4), .neg(neg), .enable(en3),.numOut(d4_to_out), .enOut(en4),.segs(hex3));	

	

endmodule

module DispDec(input [7:0] Number, input neg, enable, output reg[7:0] numOut, output reg enOut, output [6:0] segs);
	
	wire [3:0] digit;
	wire n;

	SSeg s(.bin(digit),.neg(n),.enable(enable),.segs(segs));

	assign digit = ( Number % 10 );
	assign n = ( (neg == 1)  & (digit == 0) & (Number/10 == 0) );

	always@(*) begin
		numOut = Number/10;
		enOut = (numOut == 0 & (n == 1 | neg == 0) ) ? 0:1;
		if(!enable) enOut = enable;
	end

endmodule
/***********************************************************/

/********************** DispHex MODULE *********************/

module DispHex( input [7:0] ip,
				output [6:0] hex4,
				output [6:0] hex5 );

		reg neg = 0;
		reg enable = 1;
		
		SSeg seg1(.bin(ip[7:4]), .neg(neg), .enable(enable), .segs(hex5) );
		SSeg seg2(.bin(ip[3:0]), .neg(neg), .enable(enable), .segs(hex4) );


endmodule

/***********************************************************/

module Synchroniser(input clock, signalIn, output syncSignal);
	
	wire dff1_to_dff2;
	
	MyDFF dff1(.clock(clock), .data(signalIn), .q(dff1_to_dff2));
	MyDFF dff2(.clock(clock), .data(dff1_to_dff2), .q(syncSignal));

endmodule

/****************** Flip Flop MODULE ***********************/

module MyDFF(input clock, data, output reg q);
	
	always@(posedge clock)
				q <= data;
	
endmodule

/***********************************************************/

/************************ Step 2 ***************************/

module DetectFallingEdge(input clock, input pb_safe, output pb_activated);
	
	reg dff = 0;

	always@(posedge clock) begin
		dff <= pb_safe;
	end

	assign pb_activated = (dff && !pb_safe);

endmodule

/************************ Step 2 ***************************/





