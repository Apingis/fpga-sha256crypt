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

`ifndef SIMULATION

module ff32_bwe #(
	parameter N = 32
	)(
	input CLK,
	input [N/8-1 :0] en,
	input rst,
	input [N-1:0] i,
	output reg [N-1:0] o = 0
	);

endmodule

`else

// 'bwe' - byte-wide write enable
module ff32_bwe #(
	parameter N = 32
	)(
	input CLK,
	input [N/8-1 :0] en,
	input rst,
	input [N-1:0] i,
	output reg [N-1:0] o = 0
	);

	genvar j;
	generate
	for (j=0; j < N/8; j=j+1) begin:r

	always @(posedge CLK)
		if (rst)
			o [8*j +:8] <= 0;
		else if (en[j])
			o [8*j +:8] <= i [8*j +:8];

	end
	endgenerate

endmodule

`endif
