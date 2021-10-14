module projectCPU2020(
  clk,
  rst,
  wrEn,
  data_fromRAM,
  addr_toRAM,
  data_toRAM,
  PC,
  W
);

parameter ADD_LEN =13;

input clk, rst;

input wire [15:0] data_fromRAM;
output reg [15:0] data_toRAM;
output reg wrEn;

// 12 can be made smaller so that it fits in the FPGA
output reg [ADD_LEN-1:0] addr_toRAM;
output reg [ADD_LEN-1:0] PC; // This has been added as an output for TB purposes
output reg [15:0] W; // This has been added as an output for TB purposes

// Your design goes in here
reg [2:0] opc, opcNxt;
reg [1:0] state, stateNxt;
reg [12:0] num, numNxt;
reg [12:0] PCNxt;
reg [15:0] WNxt;
reg [15:0] starNum, starNumNxt;

always @(posedge clk)begin
	state    <= #1 stateNxt;
	PC <= #1 PCNxt;
	opc   <= #1 opcNxt;
	num <= #1 numNxt;
	W <= #1 WNxt;
	starNum <= #1 starNumNxt;
end

always@(*) begin
	stateNxt = state;
	PCNxt = PC;
	opcNxt = opc;
	numNxt = num;
	WNxt = W;
	addr_toRAM = 0;
	wrEn = 0;
	data_toRAM = 0;
	starNumNxt = starNum;
	
	if(rst)begin
		stateNxt = 0;
		opcNxt = 0;
		numNxt = 0;
		WNxt = 0;
		starNumNxt = 0;
		data_toRAM = 0;
		PCNxt = 0;
		addr_toRAM=0;
		wrEn = 0;
		end
	else begin
		case(state) 
			0:begin
			opcNxt = data_fromRAM[15:13];
			numNxt = data_fromRAM[12:0];
			 if(numNxt ==0)
				addr_toRAM = 2;
				else
				addr_toRAM = numNxt;
				
			stateNxt = 1;	
			end
			1: begin
				starNumNxt = data_fromRAM;
				addr_toRAM = num;
				if(num == 0)
				addr_toRAM = starNumNxt;
				
				stateNxt = 2;
			end
			2:begin
				starNumNxt = data_fromRAM;
				if(opc != 3'b110)
					wrEn = 0;
				else
					wrEn = 1;
				if(num != 0)
					addr_toRAM = num;
				else
					addr_toRAM =starNum;
				
				PCNxt = PC+1;
					if(opc == 3'b000)
					WNxt = W + starNumNxt;
					if(opc == 3'b001)
					WNxt = ~(W | starNumNxt);
					if(opc == 3'b010) begin
					if( starNumNxt <= 16)
						WNxt = W >> starNumNxt;
					else if ((starNumNxt <= 31) && (starNumNxt >= 17))
						WNxt = W << starNumNxt[3:0];
					else if ((starNumNxt <= 47) && ( starNumNxt >= 32))
						WNxt = ((W >> starNumNxt[3:0]) | (W << (16 - starNumNxt[3:0])));
					else
						WNxt = ((W >> (16 - starNumNxt[3:0])) | (W << starNumNxt[3:0]));
					end
					
				if(opc == 3'b011)begin
					if(W > starNumNxt)
						WNxt = 1;
					else
						WNxt = 0;
				end
				if(opc == 3'b100)begin
					if(starNumNxt == 0)
						PCNxt = PC+2;
					else
						PCNxt = PC+1;
					end
				if(opc == 3'b101)
					WNxt = starNumNxt;
				if(opc == 3'b110)
					data_toRAM = W;
				if(opc == 3'b111)
					PCNxt = starNumNxt;
				
				stateNxt = 3;
		end
		3:begin 
		addr_toRAM = PC;
		stateNxt = 0;
		end
		 default: begin
          stateNxt = 0;
          opcNxt = 0;
          numNxt = 0;
          starNumNxt = 0;
          WNxt = 0;
          data_toRAM = 0;
          PCNxt = 0;
          addr_toRAM = 0;
          wrEn = 0;
          end
		
			endcase 
		end 
	end					
endmodule
