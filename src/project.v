/*
 * Copyright (c) 2024 Hans Sese
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_GataLavApols_tcg_companion (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);
    // Unused bidirectional pins must be grounded
    assign uio_out = 8'b0;
    assign uio_oe  = 8'b0;

    // Input mapping
    wire btn_add   = ui_in[0];
    wire btn_sub   = ui_in[1];
    wire btn_coin  = ui_in[2];
    wire btn_reset = ui_in[3];

    // Edge detection so holding the button doesn't add infinite damage
    reg btn_add_prev, btn_sub_prev;
    wire add_edge = btn_add && !btn_add_prev;
    wire sub_edge = btn_sub && !btn_sub_prev;

    // Registers to hold state
    reg [3:0] damage_counters; // Counts 0-9
    reg [7:0] lfsr;            // Linear Feedback Shift Register (Hardware RNG)
    reg coin_result;

    always @(posedge clk) begin
        if (!rst_n) begin
            // Reset state
            damage_counters <= 0;
            lfsr <= 8'hAC; // Non-zero starting seed for RNG
            coin_result <= 0;
            btn_add_prev <= 0;
            btn_sub_prev <= 0;
        end else begin
            // Shift register logic (XOR taps for pseudo-randomness)
            lfsr <= {lfsr[6:0], lfsr[7] ^ lfsr[5] ^ lfsr[4] ^ lfsr[3]};

            // Track previous button states for edge detection
            btn_add_prev <= btn_add;
            btn_sub_prev <= btn_sub;

            // Damage Counter Logic
            if (btn_reset) begin
                damage_counters <= 0;
            end else if (add_edge && damage_counters < 9) begin
                damage_counters <= damage_counters + 1;
            end else if (sub_edge && damage_counters > 0) begin
                damage_counters <= damage_counters - 1;
            end

            // Coin Flip Logic: rapidly sample RNG while switch is held
            if (btn_coin) begin
                coin_result <= lfsr[0];
            end
        end
    end

    // 7-segment display decoder (Active High)
    reg [6:0] seg;
    always @(*) begin
        case (damage_counters)
            4'd0: seg = 7'b0111111;
            4'd1: seg = 7'b0000110;
            4'd2: seg = 7'b1011011;
            4'd3: seg = 7'b1001111;
            4'd4: seg = 7'b1100110;
            4'd5: seg = 7'b1101101;
            4'd6: seg = 7'b1111101;
            4'd7: seg = 7'b0000111;
            4'd8: seg = 7'b1111111;
            4'd9: seg = 7'b1101111;
            default: seg = 7'b0000000;
        endcase
    end

    // Map logic to physical output pins
    assign uo_out[6:0] = seg;
    assign uo_out[7]   = coin_result; 

endmodule
