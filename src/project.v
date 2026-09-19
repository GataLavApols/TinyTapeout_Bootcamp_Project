`default_nettype none

module tt_um_vga_racing (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path
    input  wire       ena,
    input  wire       clk,      // 25.175 MHz expected for 640x480 VGA
    input  wire       rst_n
);
    // Sink unused inputs
    wire _unused = &{ena, ui_in[7:2], uio_in, 1'b0};
    assign uio_out = 8'b0;
    assign uio_oe  = 8'b0;

    // --- VGA Sync Generator (640x480 @ 60Hz) ---
    reg [9:0] h_count;
    reg [9:0] v_count;

    wire h_max = (h_count == 799);
    wire v_max = (v_count == 524);

    always @(posedge clk) begin
        if (!rst_n) begin
            h_count <= 0;
            v_count <= 0;
        end else begin
            if (h_max) begin
                h_count <= 0;
                v_count <= v_max ? 0 : v_count + 1;
            end else begin
                h_count <= h_count + 1;
            end
        end
    end

    wire h_sync = ~(h_count >= (640 + 16) && h_count < (640 + 16 + 96));
    wire v_sync = ~(v_count >= (480 + 10) && v_count < (480 + 10 + 2));
    wire active = (h_count < 640) && (v_count < 480);

    // --- Game Logic ---
    wire btn_left  = ui_in[0];
    wire btn_right = ui_in[1];

    reg [9:0] player_x;
    reg [9:0] enemy_x;
    reg [9:0] enemy_y;
    reg crashed;
    reg [5:0] frame_counter; // Used to slow down movement

    // Update game state once per frame (on the falling edge of vsync)
    reg last_vsync;
    wire frame_tick = (last_vsync && !v_sync);

    always @(posedge clk) begin
        if (!rst_n) begin
            player_x <= 300; // Center of 640 screen
            enemy_x  <= 300;
            enemy_y  <= 0;
            crashed  <= 0;
            last_vsync <= 1;
            frame_counter <= 0;
        end else begin
            last_vsync <= v_sync;

            if (frame_tick) begin
                frame_counter <= frame_counter + 1;

                if (!crashed) begin
                    // Player Movement (slowed down slightly)
                    if (frame_counter[0]) begin 
                        if (btn_left && player_x > 180) player_x <= player_x - 3;
                        if (btn_right && player_x < 420) player_x <= player_x + 3;
                    end

                    // Enemy Movement (Traffic falling down)
                    enemy_y <= enemy_y + 4;
                    if (enemy_y > 480) begin
                        enemy_y <= 0;
                        // Simple pseudo-random enemy placement based on frame_counter
                        enemy_x <= 200 + {2'b0, frame_counter} + player_x[4:0];
                        if (enemy_x > 400) enemy_x <= 300; // Keep on road
                    end

                    // Collision Detection (Bounding boxes)
                    // Player: Y=400 to 440, X=player_x to player_x+40
                    // Enemy:  Y=enemy_y to enemy_y+40, X=enemy_x to enemy_x+40
                    if ((enemy_y + 40 > 400) && (enemy_y < 440)) begin
                        if ((enemy_x + 40 > player_x) && (enemy_x < player_x + 40)) begin
                            crashed <= 1; // Overlap detected!
                        end
                    end
                end else if (btn_left && btn_right) begin
                    // Press both buttons to restart
                    crashed <= 0;
                    enemy_y <= 0;
                end
            end
        end
    end

    // --- Rendering Logic ---
    wire is_road = (h_count >= 160 && h_count <= 480);
    wire is_shoulder = (h_count >= 150 && h_count < 160) || (h_count > 480 && h_count <= 490);
    wire is_center_line = (h_count >= 315 && h_count <= 325) && (v_count[5] == 1); // Dashed line
    
    wire draw_player = (h_count >= player_x && h_count < player_x + 40) && 
                       (v_count >= 400 && v_count < 440);
                       
    wire draw_enemy  = (h_count >= enemy_x && h_count < enemy_x + 40) && 
                       (v_count >= enemy_y && v_count < enemy_y + 40);

    // RGB Outputs (2 bits per channel)
    reg [1:0] r, g, b;

    always @(*) begin
        if (!active) begin
            {r, g, b} = 6'b000000;
        end else if (crashed) begin
            // Red screen of death
            {r, g, b} = 6'b110000;
        end else if (draw_player) begin
            // Blue Player Car
            {r, g, b} = 6'b000011;
        end else if (draw_enemy) begin
            // Red Enemy Car
            {r, g, b} = 6'b110000;
        end else if (is_center_line && is_road) begin
            // Yellow Center Lines
            {r, g, b} = 6'b111100;
        end else if (is_shoulder) begin
            // White Shoulders
            {r, g, b} = 6'b111111;
        end else if (is_road) begin
            // Gray Road
            {r, g, b} = 6'b010101;
        end else begin
            // Green Grass
            {r, g, b} = 6'b001100;
        end
    end

    // Map to VGA PMOD pins
    assign uo_out = {h_sync, v_sync, b[1], b[0], g[1], g[0], r[1], r[0]};

endmodule
