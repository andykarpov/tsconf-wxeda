
module lut (
    input wire mode,
    input wire [4:0] in,
    output wire [7:0] out
);

    wire [7:0] sig;
    assign out = mode ? {in, 3'b0} : sig;

    always @*
	begin
        case (in)
            5'd0:    sig = 8'd0;
            5'd1:    sig = 8'd10;
            5'd2:    sig = 8'd21;
            5'd3:    sig = 8'd31;
            5'd4:    sig = 8'd42;
            5'd5:    sig = 8'd53;
            5'd6:    sig = 8'd63;
            5'd7:    sig = 8'd74;
            5'd8:    sig = 8'd85;
            5'd9:    sig = 8'd95;
            5'd10:   sig = 8'd106;
            5'd11:   sig = 8'd117;
            5'd12:   sig = 8'd127;
            5'd13:   sig = 8'd138;
            5'd14:   sig = 8'd149;
            5'd15:   sig = 8'd159;
            5'd16:   sig = 8'd170;
            5'd17:   sig = 8'd181;
            5'd18:   sig = 8'd191;
            5'd19:   sig = 8'd202;
            5'd20:   sig = 8'd213;
            5'd21:   sig = 8'd223;
            5'd22:   sig = 8'd234;
            5'd23:   sig = 8'd245;
            5'd24:   sig = 8'd255;
            default: sig = 8'd255;
        endcase
	end
endmodule
