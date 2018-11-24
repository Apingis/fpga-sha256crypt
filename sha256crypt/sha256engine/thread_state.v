`timescale 1ns / 1ps
/*
 * This software is Copyright (c) 2018 Denis Burykin
 * [denis_burykin yahoo com], [denis-burykin2014 yandex ru]
 * and it is hereby released to the general public under the following terms:
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted.
 *
 */
`include "../sha256.vh"

//
//
module thread_state #(
	parameter N_THREADS = 6,
	parameter N_THREADS_MSB = `MSB(N_THREADS-1)
	)(
	input CLK,
	
	input [N_THREADS_MSB :0] wr_num1, rd_num1,
	input wr_en1,
	input [`THREAD_STATE_MSB :0] wr_state1,
	//output reg [`THREAD_STATE_MSB :0] rd_state1 = 0,
	output [`THREAD_STATE_MSB :0] rd_state1, // #1 - asynchronous read

	input [N_THREADS_MSB :0] wr_num2, rd_num2,
	input wr_en2,
	input [`THREAD_STATE_MSB :0] wr_state2,
	output reg [`THREAD_STATE_MSB :0] rd_state2 = 0,

	input [N_THREADS_MSB :0] wr_num3, rd_num3,
	input wr_en3,
	input [`THREAD_STATE_MSB :0] wr_state3,
	output reg [`THREAD_STATE_MSB :0] rd_state3 = 0,

	input [N_THREADS_MSB :0] wr_num4, rd_num4,
	input wr_en4,
	input [`THREAD_STATE_MSB :0] wr_state4,
	output reg [`THREAD_STATE_MSB :0] rd_state4 = 0,
	
	output reg err = 0
	);

	//
	// Note.
	// With more than 3 read channels, it doesn't infer memory but FFs.
	// Split the memory into 2 parts.
	//
	(* RAM_STYLE="DISTRIBUTED" *)
	reg [`THREAD_STATE_MSB :0] mem [0:N_THREADS-1], mem2 [0:N_THREADS-1];
		//mem3 [0:N_THREADS-1], mem4 [0:N_THREADS-1];

	reg [N_THREADS_MSB :0] wr_num1_r = 0, wr_num2_r = 0,
		wr_num3_r = 0, wr_num4_r = 0;
	
	reg [`THREAD_STATE_MSB :0] wr_state1_r = 0,
		wr_state2_r = 0, wr_state3_r = 0, wr_state4_r = 0;

	reg wr_en1_r = 0, wr_en2_r = 0, wr_en3_r = 0, wr_en4_r = 0;
	
	//reg init_done = 0;
	
	always @(posedge CLK) begin
		if (wr_en1 & wr_en1_r & (wr_en2_r & wr_en2 | wr_en3_r & wr_en3)
			| wr_en2 & wr_en2_r & (wr_en1_r & wr_en1 | wr_en3_r & wr_en3)
			| wr_en3 & wr_en3_r & (wr_en1_r & wr_en1 | wr_en2_r & wr_en2)
		)
		// TODO: wr_en4
			err <= 1;
		
		if (wr_en1) begin
			wr_en1_r <= 1;
			wr_state1_r <= wr_state1;
			wr_num1_r <= wr_num1;
		end

		if (wr_en2) begin
			wr_en2_r <= 1;
			wr_state2_r <= wr_state2;
			wr_num2_r <= wr_num2;
		end

		if (wr_en3) begin
			wr_en3_r <= 1;
			wr_state3_r <= wr_state3;
			wr_num3_r <= wr_num3;
		end

		if (wr_en4) begin
			wr_en4_r <= 1;
			wr_state4_r <= wr_state4;
			wr_num4_r <= wr_num4;
		end
		
		if (wr_en1_r & ~wr_en1)
			wr_en1_r <= 0;
		if (~wr_en1_r & wr_en2_r & ~wr_en2)
			wr_en2_r <= 0;
		if (~wr_en1_r & ~wr_en2_r & wr_en3_r & ~wr_en3)
			wr_en3_r <= 0;
		if (~wr_en1_r & ~wr_en2_r & ~wr_en3_r & wr_en4_r & ~wr_en4)
			wr_en4_r <= 0;
		/*
		if (~init_done) begin
			thread_num3_r <= thread_num3_r + 1'b1;
			if (thread_num3_r == N_THREADS - 1)
				init_done <= 1;
		end
		*/
		// 1 write channel
		/*
		// Infers FFs
		if (wr_en1_r | wr_en2_r | wr_en3_r | wr_en4_r)// | ~init_done)
			mem [
				wr_en1_r ? wr_num1_r :
				wr_en2_r ? wr_num2_r :
				wr_en3_r ? wr_num3_r : wr_num4_r
			] <=
				wr_en1_r ? wr_state1_r :
				wr_en2_r ? wr_state2_r :
				wr_en3_r ? wr_state3_r : wr_state4_r;
		*/

		// Infers RAM64M (36 LUT)
		if (wr_en1_r | wr_en2_r | wr_en3_r | wr_en4_r) begin
			mem [
				wr_en1_r ? wr_num1_r :
				wr_en2_r ? wr_num2_r :
				wr_en3_r ? wr_num3_r : wr_num4_r
			] <=
				wr_en1_r ? wr_state1_r :
				wr_en2_r ? wr_state2_r :
				wr_en3_r ? wr_state3_r : wr_state4_r;

			mem2 [
				wr_en1_r ? wr_num1_r :
				wr_en2_r ? wr_num2_r :
				wr_en3_r ? wr_num3_r : wr_num4_r
			] <=
				wr_en1_r ? wr_state1_r :
				wr_en2_r ? wr_state2_r :
				wr_en3_r ? wr_state3_r : wr_state4_r;
		end
		
		// 4 read channels (1 of them is async)
		//rd_state1 <= mem [rd_num1];
		rd_state2 <= mem [rd_num2];
		rd_state3 <= mem2 [rd_num3];
		rd_state4 <= mem2 [rd_num4];
	end

	assign rd_state1 = mem [rd_num1];


/*
`ifdef SIMULATION
	integer k;
	
	wire [N_THREADS-1:0] state_wr_rdy, state_rd_rdy;
	wire [`MSB(N_THREADS-1):0] wr_rdy_cnt;
	
	genvar i;
	generate
	for (i=0; i < N_THREADS; i=i+1) begin: state_gen
		assign state_wr_rdy[i] = mem[i] == `THREAD_STATE_WR_RDY;
		assign state_rd_rdy[i] = mem[i] == `THREAD_STATE_RD_RDY;
	end
	endgenerate

	assign wr_rdy_cnt = 
		state_wr_rdy[0] + state_wr_rdy[1] + state_wr_rdy[2] + state_wr_rdy[3] +
		state_wr_rdy[4] + state_wr_rdy[5] + state_wr_rdy[6] + state_wr_rdy[7] +
		state_wr_rdy[8] + state_wr_rdy[9] + state_wr_rdy[10] + state_wr_rdy[11] +
		state_wr_rdy[12] + state_wr_rdy[13] + state_wr_rdy[14] + state_wr_rdy[15];

	reg [31:0] X_CYCLES_TOTAL = 0;
	reg [31:0] X_CYCLES_WR_RDY = 0;
	reg [31:0] X_CYCLES_RD_RDY = 0;
	
	reg [23:0] X_WR_RDY_CNT [0: N_THREADS-1];
	initial
		for (k=0; k < N_THREADS; k=k+1)
			X_WR_RDY_CNT[k] = 0;

	always @(posedge CLK) begin
		X_CYCLES_TOTAL <= X_CYCLES_TOTAL + 1'b1;
		if (|state_wr_rdy)
			X_CYCLES_WR_RDY <= X_CYCLES_WR_RDY + 1'b1;
		if (|state_rd_rdy)
			X_CYCLES_RD_RDY <= X_CYCLES_RD_RDY + 1'b1;
		
		X_WR_RDY_CNT[wr_rdy_cnt] <= X_WR_RDY_CNT[wr_rdy_cnt] + 1'b1;
	end
`endif
*/

endmodule
