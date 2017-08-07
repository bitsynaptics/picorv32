/*
 *  PicoSoC - A simple example SoC using PicoRV32
 *
 *  Copyright (C) 2017  Clifford Wolf <clifford@clifford.at>
 *
 *  Permission to use, copy, modify, and/or distribute this software for any
 *  purpose with or without fee is hereby granted, provided that the above
 *  copyright notice and this permission notice appear in all copies.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 *  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 *  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 *  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 *  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 *  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 *  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 */

module spimemio (
	input clk, resetn,

	input valid,
	output reg ready,
	input [23:0] addr,
	output reg [31:0] rdata,

	output reg flash_csb,
	output reg flash_clk,

	output reg flash_io0_oe,
	output reg flash_io1_oe,
	output reg flash_io2_oe,
	output reg flash_io3_oe,

	output reg flash_io0_do,
	output reg flash_io1_do,
	output reg flash_io2_do,
	output reg flash_io3_do,

	input      flash_io0_di,
	input      flash_io1_di,
	input      flash_io2_di,
	input      flash_io3_di
);
	parameter ENABLE_PREFETCH = 1;

	reg [23:0] addr_q;
	reg addr_q_vld;

	reg [31:0] buffer;
	reg [6:0] xfer_cnt;
	reg pulse_csb_8;
	reg xfer_wait;
	reg prefetch;

	always @(posedge clk) begin
		ready <= 0;
		if (!resetn) begin
			addr_q_vld <= 0;
			xfer_wait <= 0;
			prefetch <= 0;

			xfer_cnt <= 16;
			pulse_csb_8 <= 1;
			buffer <= {8'h FF, 8'h AB, 16'h 0000};

			flash_csb <= 1;
			flash_clk <= 1;

			flash_io0_oe <= 0;
			flash_io1_oe <= 0;
			flash_io2_oe <= 0;
			flash_io3_oe <= 0;

			flash_io0_do <= 0;
			flash_io1_do <= 0;
			flash_io2_do <= 0;
			flash_io3_do <= 0;
		end else
		if (xfer_cnt) begin
			if (xfer_cnt == 8 && pulse_csb_8) begin
				pulse_csb_8 <= 0;
				flash_csb <= 1;
			end else
			if (flash_csb) begin
				flash_csb <= 0;
			end else
			if (flash_clk) begin
				flash_clk <= 0;
				flash_io0_oe <= 1;
				flash_io0_do <= buffer[31];
			end else begin
				flash_clk <= 1;
				buffer <= {buffer, flash_io1_di};
				xfer_cnt <= xfer_cnt - 1;
			end
		end else
		if (xfer_wait) begin
			ready <= 1;
			rdata <= {buffer[7:0], buffer[15:8], buffer[23:16], buffer[31:24]};
			xfer_wait <= 0;
		end else
		if (valid && !ready) begin
			if (addr_q_vld && addr_q == addr) begin
				addr_q <= addr + 4;
				addr_q_vld <= 1;
				if (!prefetch)
					xfer_cnt <= 32;
				xfer_wait <= 1;
				prefetch <= 0;
			end else begin
				flash_csb <= 1;
				buffer <= {8'h 03, addr};
				addr_q <= addr + 4;
				addr_q_vld <= 1;
				xfer_cnt <= 64;
				xfer_wait <= 1;
				prefetch <= 0;
			end
		end else if (ENABLE_PREFETCH && !prefetch) begin
			prefetch <= 1;
			xfer_cnt <= 32;
		end

		if (ENABLE_PREFETCH && resetn && prefetch && valid && !ready && addr_q != addr) begin
			prefetch <= 0;
			xfer_cnt <= 0;
			xfer_wait <= 0;
			flash_clk <= 1;
		end
	end
endmodule