`default_nettype none

module gamepad_pmod(
    input  wire [7:0] ui_in,
    output wire btn_left,
    output wire btn_right,
    output wire btn_up,
    output wire btn_down,
    output wire btn_start
);
    // Maps raw Tiny Tapeout input pins to standard gamepad controls
    assign btn_left  = ui_in[0];
    assign btn_right = ui_in[1];
    assign btn_up    = ui_in[2];
    assign btn_down  = ui_in[3];
    assign btn_start = ui_in[4];
endmodule
