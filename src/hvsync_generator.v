`default_nettype none

module hvsync_generator(
    input  wire clk,
    input  wire reset,
    output reg  hsync,
    output reg  vsync,
    output wire display_on,
    output reg  [9:0] hpos,
    output reg  [9:0] vpos
);
    wire h_max = (hpos == 799);
    wire v_max = (vpos == 524);

    always @(posedge clk) begin
        if (reset) begin
            hpos <= 0;
            vpos <= 0;
            hsync <= 0;
            vsync <= 0;
        end else begin
            if (h_max) begin
                hpos <= 0;
                vpos <= v_max ? 0 : vpos + 1;
            end else begin
                hpos <= hpos + 1;
            end
            
            // Generate active-low sync pulses
            hsync <= ~(hpos >= 656 && hpos < 752);
            vsync <= ~(vpos >= 490 && vpos < 492);
        end
    end

    assign display_on = (hpos < 640) && (vpos < 480);
endmodule
