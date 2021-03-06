
//=======================================================
//  This code is generated by Terasic System Builder
//=======================================================

module MyComputer(

	//////////// CLOCK //////////
	input 		          		CLOCK_50,
//	input 		          		CLOCK2_50,
//	input 		          		CLOCK3_50,
//	input 		          		CLOCK4_50,

	//////////// SEG7 //////////
	output		     [6:0]		HEX0,
	output		     [6:0]		HEX1,
	output		     [6:0]		HEX2,
	output		     [6:0]		HEX3,
	output		     [6:0]		HEX4,
	output		     [6:0]		HEX5,

	//////////// KEY //////////
	input 		     [3:0]		KEY,

	//////////// LED //////////
	output		     [9:0]		LEDR,

	//////////// SW //////////
	input 		     [9:0]		SW
);

	wire debouncer_to_cpu;
	wire [7:0] cpu_to_Disp2cNum_data;
	wire cpu_to_Disp2cNum_dVal;
	wire [7:0] cpu_to_DispHex;
	
	
	/////////////// DEBOUNCER MODULE ///////////////
	Debounce debouncer(.clock(CLOCK_50), 
							 .signalDebounced(debouncer_to_cpu),
							 .signalIn(SW[9]));

	/////////////// CPU MODULE	///////////////					 
	CPU cpu(.Clock(CLOCK_50),						// #1
			  .GPO(LEDR[5:0]),						// #2
			  .Debug(LEDR[9:6]), 					// #3
			  .Din(SW[7:0]),							// #4
			  .Turbo(SW[8]),							// #5
			  .Sample(~KEY[3]),						// #6
			  .Btns(~KEY[2:0]),						// #7
			  .Reset(debouncer_to_cpu),				// #8
			  .Dout(cpu_to_Disp2cNum_data),		// #9
			  .Dval(cpu_to_Disp2cNum_dVal),		// #10
			  .IP(cpu_to_DispHex) );					// #11
			  
	Disp2cNum dnum(.Number(cpu_to_Disp2cNum_data),
						.enable(cpu_to_Disp2cNum_dVal),
						.hex0(HEX0),
						.hex1(HEX1),
						.hex2(HEX2),
						.hex3(HEX3));
				
	DispHex dhex(.ip(cpu_to_DispHex), .hex4(HEX4), .hex5(HEX5));

endmodule