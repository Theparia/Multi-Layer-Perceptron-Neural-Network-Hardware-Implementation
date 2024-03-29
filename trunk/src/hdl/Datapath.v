`timescale 1ns/1ns

module Datapath(input clk, rst, start_pu, input[3:0] ld_hidden_layer, input[1:0] ld_output_layer, input[62*8-1:0] pixels, output[3:0] mnist_class, output ready_8_pu);
  reg [8*8*62-1:0] weights_hidden[3:0];
  reg [8*8-1:0] bias_hidden[3:0];
  reg [8*8-1:0] bias_output[1:0];
  reg [30*8*8-1:0] weights_output[1:0];
  reg [62*8-1:0] weights_pu[7:0];
  reg [7:0] bias_pu[7:0];
  wire [7:0] result_pu[7:0];
  wire [7:0] ready;
  wire [62*8-1:0] inp_pu, inp_output_layer; 
  wire [7:0] hidden_reg[29:0];
  wire [8*10-1:0] output_layer_out;
  wire [7:0] output_reg[7:0];

  reg [7:0] b1_sm [0:31];
	reg [7:0] b2_sm [0:15];
	reg [7:0] w1_sm [0:1983];
	reg [7:0] w2_sm [0:479];
		
	integer i;
	integer r;
	
 	initial begin
    $readmemh("../sim/file/b1_sm.dat", b1_sm);
		$readmemh("../sim/file/b2_sm.dat", b2_sm);
		$readmemh("../sim/file/w1_sm.dat", w1_sm);
		$readmemh("../sim/file/w2_sm.dat", w2_sm);
		  
		for (r = 0 ; r < 4; r = r + 1) begin
		  for (i = 0; i < 62 * 8; i = i + 1) begin
			 weights_hidden[r][8 * i +: 8] = w1_sm[i + r * 62 * 8];
      end
    end

    for (r = 0; r < 2 ; r = r + 1) begin
		  for (i = 0; i < 30 * 8; i = i + 1) begin
			 weights_output[r][8 * i +: 8] = w2_sm[i + r * 30 * 8];
		  end
		end
		
		for (r = 0 ; r < 4; r = r + 1) begin
		  for (i = 0; i < 8; i = i + 1) begin
			 bias_hidden[r][8 * i +: 8] = b1_sm[i + r * 8];
      end
    end
    
    for (r = 0 ; r < 2; r = r + 1) begin
		  for (i = 0; i < 8; i = i + 1) begin
			 bias_output[r][8 * i +: 8] = b2_sm[i + r * 8];
      end
    end
	end
  
  
  assign inp_pu = (ld_output_layer[0] || ld_output_layer[1]) ? inp_output_layer : pixels;
  
  
  always@(*)begin
    for(i = 0; i < 8; i = i + 1) begin: w
      if (ld_hidden_layer[0])begin
        weights_pu[i] = weights_hidden[0][62*8*i +: 62*8];
        bias_pu[i] = bias_hidden[0][8*i +: 8];
      end
      else if (ld_hidden_layer[1])begin
        weights_pu[i] = weights_hidden[1][62*8*i +: 62*8];
        bias_pu[i] = bias_hidden[1][8*i +: 8];
      end
      else if (ld_hidden_layer[2])begin
        weights_pu[i] = weights_hidden[2][62*8*i +: 62*8];
        bias_pu[i] = bias_hidden[2][8*i +: 8];
      end
      else if (ld_hidden_layer[3])begin
        weights_pu[i] = weights_hidden[3][62*8*i +: 62*8];
        bias_pu[i] = bias_hidden[3][8*i +: 8];
      end
      else if(ld_output_layer[0])begin
        weights_pu[i] = {256'd0, weights_output[0][30*8*i +: 30*8]};
        bias_pu[i] = bias_output[0][8*i +: 8];
      end
      else if(ld_output_layer[1])begin
        weights_pu[i] = {256'd0, weights_output[1][30*8*i +: 30*8]};
        bias_pu[i] = bias_output[1][8*i +: 8];
      end
    end
  end
  
  genvar j;
  generate
    for(j = 0; j < 8; j = j + 1) begin: PUs
      PU pu(clk, rst, start_pu, inp_pu, weights_pu[j], bias_pu[j], result_pu[j], ready[j]);
    end
  endgenerate
  
  assign ready_8_pu = &ready;
  
  genvar k;
  generate
    for(k = 0; k < 30; k = k + 1) begin: hidden_regs
      Register register(clk, rst, ld_hidden_layer[k/8], result_pu[k%8], hidden_reg[k]);
    end
  endgenerate
  
  genvar l;
  generate
    for(l = 0; l < 8; l = l + 1) begin: output_regs
      Register register(clk, rst, ld_output_layer[0], result_pu[l], output_reg[l]);
    end
  endgenerate
  
  assign output_layer_out = {result_pu[1], result_pu[0], output_reg[7], output_reg[6], output_reg[5], output_reg[4], 
                              output_reg[3], output_reg[2], output_reg[1], output_reg[0]};
  
  assign inp_output_layer = {256'd0, hidden_reg[29], hidden_reg[28], hidden_reg[27], hidden_reg[26], hidden_reg[25],
                              hidden_reg[24], hidden_reg[23], hidden_reg[22], hidden_reg[21], hidden_reg[20],
                              hidden_reg[19], hidden_reg[18], hidden_reg[17], hidden_reg[16], hidden_reg[15],
                              hidden_reg[14], hidden_reg[13], hidden_reg[12], hidden_reg[11], hidden_reg[10],
                              hidden_reg[9], hidden_reg[8], hidden_reg[7], hidden_reg[6], hidden_reg[5],
                              hidden_reg[4], hidden_reg[3], hidden_reg[2], hidden_reg[1], hidden_reg[0]};
  
  Label label(output_layer_out, mnist_class);
endmodule


