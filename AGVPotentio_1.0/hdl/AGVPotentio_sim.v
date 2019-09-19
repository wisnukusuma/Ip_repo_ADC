`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: BPPT
// Engineer: Fadjar Rahino Triputra
// 
// Create Date: 11/18/2018 02:09:35 AM
// Design Name: AGVPotentio
// Module Name: AGVPotentio_sim
// Project Name: AGV Guiding System
// Target Devices: Cmod-A7
// Tool Versions: Vivado 2018.2
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module AGVRFID_sim#
(
    parameter integer AGVENCODER_S00_AXI_SLV_REG0_OFFSET = 0,
    parameter integer AGVENCODER_S00_AXI_SLV_REG1_OFFSET = 4,
    parameter integer AGVENCODER_S00_AXI_SLV_REG2_OFFSET = 8,
    parameter integer AGVENCODER_S00_AXI_SLV_REG3_OFFSET = 12,
    // Parameters of Axi Slave Bus Interface S00_AXI
    parameter integer C_S00_AXI_DATA_WIDTH    = 32,
    parameter integer C_S00_AXI_ADDR_WIDTH    = 4
);

wire interrupt;
reg s00_axi_aclk;
reg s00_axi_aresetn;
reg [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr;
reg [2 : 0] s00_axi_awprot;
reg s00_axi_awvalid;
wire s00_axi_awready;
reg [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata;
reg [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb;
reg s00_axi_wvalid;
wire s00_axi_wready;
wire [1 : 0] s00_axi_bresp;
wire s00_axi_bvalid;
reg s00_axi_bready;
reg [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr;
reg [2 : 0] s00_axi_arprot;
reg s00_axi_arvalid;
wire  s00_axi_arready;
wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata;
wire [1 : 0] s00_axi_rresp;
wire  s00_axi_rvalid;
reg s00_axi_rready;

AGVPotentio_v1_0 #
	(
		.C_S00_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
        .C_S00_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
	) potentio (
        .interrupt(interrupt),
		.s00_axi_aclk(s00_axi_aclk),
        .s00_axi_aresetn(s00_axi_aresetn),
        .s00_axi_awaddr(s00_axi_awaddr),
        .s00_axi_awprot(s00_axi_awprot),
        .s00_axi_awvalid(s00_axi_awvalid),
        .s00_axi_awready(s00_axi_awready),
        .s00_axi_wdata(s00_axi_wdata),
        .s00_axi_wstrb(s00_axi_wstrb),
        .s00_axi_wvalid(s00_axi_wvalid),
        .s00_axi_wready(s00_axi_wready),
        .s00_axi_bresp(s00_axi_bresp),
        .s00_axi_bvalid(s00_axi_bvalid),
        .s00_axi_bready(s00_axi_bready),
        .s00_axi_araddr(s00_axi_araddr),
        .s00_axi_arprot(s00_axi_arprot),
        .s00_axi_arvalid(s00_axi_arvalid),
        .s00_axi_arready(s00_axi_arready),
        .s00_axi_rdata(s00_axi_rdata),
        .s00_axi_rresp(s00_axi_rresp),
        .s00_axi_rvalid(s00_axi_rvalid),
        .s00_axi_rready(s00_axi_rready)
	);
		
    initial $timeformat(-3, 5, " ms", 11);
    
    initial begin
        AGVPotentio_init;

        #10000;
        $display("%t: Perintah untuk setting waktu terjadinya interrupt", $time);
        AGVPotentio_write(AGVENCODER_S00_AXI_SLV_REG0_OFFSET, 1878 << 16);
        
        #5000;
        AGVPotentio_read(AGVENCODER_S00_AXI_SLV_REG0_OFFSET);
        AGVPotentio_print;
        
        #5000;
        $finish;
    end
    
    task AGVPotentio_print;
        begin
            $display("%t: Pembacaan Microblaze, data %0d",
                       $time,
                       s00_axi_rdata[15:0]);
        end
    endtask
    
    task AGVPotentio_init;
        begin
            s00_axi_aresetn = 1'b0;
            s00_axi_awaddr = 32'd0;
            s00_axi_awprot = 3'd0;
            s00_axi_awvalid = 1'b0;
            s00_axi_wdata = 32'd0;
            s00_axi_wstrb = 4'd0;
            s00_axi_wvalid = 1'b0;
            s00_axi_bready = 1'b0;
            s00_axi_araddr = 32'd0;
            s00_axi_arprot = 3'd0;
            s00_axi_arvalid = 1'b0;
            s00_axi_rready = 1'b0;
            
            #40;
            s00_axi_aresetn = 1'b1;
        end
    endtask
    
    task AGVPotentio_write;
        input [31:0] address;
        input [31:0] data;
        begin
            s00_axi_awaddr = address;
            s00_axi_wdata = data;
            s00_axi_awvalid = 1'b1;
            s00_axi_wvalid = 1'b1;
            s00_axi_wstrb = 4'b1111;
        
            wait (s00_axi_awready && s00_axi_wready);
            s00_axi_bready = 1'b1;
        
            wait (s00_axi_bvalid == 1'b1);
            s00_axi_awvalid = 1'b0;
            s00_axi_wvalid = 1'b0;
        
            wait (s00_axi_bvalid == 1'b0);
            s00_axi_bready = 1'b0;
        end
    endtask
    
    task AGVPotentio_read;
        input [31:0] address;
        begin
            s00_axi_araddr = address;
            s00_axi_arvalid = 1'b1;
            s00_axi_rready = 1'b1;
        
            wait (s00_axi_arready);
            wait (s00_axi_rvalid);
            s00_axi_arvalid = 1'b0;
            s00_axi_rready = 1'b0;
        end
    endtask
    
    always begin
        s00_axi_aclk = 1; #5; s00_axi_aclk = 0; #5;
    end

endmodule
