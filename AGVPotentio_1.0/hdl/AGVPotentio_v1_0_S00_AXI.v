`timescale 1 ns / 1 ps

	module AGVPotentio_v1_0_S00_AXI #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line

		// Width of S_AXI data bus
		parameter integer C_S_AXI_DATA_WIDTH	= 32,
		// Width of S_AXI address bus
		parameter integer C_S_AXI_ADDR_WIDTH	= 4
	)
	(
		// Users to add ports here
        input wire potentio_v_n,
        input wire potentio_v_p,
        output wire interrupt,
		// User ports ends
		// Do not modify the ports beyond this line

		// Global Clock Signal
		input wire  S_AXI_ACLK,
		// Global Reset Signal. This Signal is Active LOW
		input wire  S_AXI_ARESETN,
		// Write address (issued by master, acceped by Slave)
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
		// Write channel Protection type. This signal indicates the
    		// privilege and security level of the transaction, and whether
    		// the transaction is a data access or an instruction access.
		input wire [2 : 0] S_AXI_AWPROT,
		// Write address valid. This signal indicates that the master signaling
    		// valid write address and control information.
		input wire  S_AXI_AWVALID,
		// Write address ready. This signal indicates that the slave is ready
    		// to accept an address and associated control signals.
		output wire  S_AXI_AWREADY,
		// Write data (issued by master, acceped by Slave) 
		input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
		// Write strobes. This signal indicates which byte lanes hold
    		// valid data. There is one write strobe bit for each eight
    		// bits of the write data bus.    
		input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
		// Write valid. This signal indicates that valid write
    		// data and strobes are available.
		input wire  S_AXI_WVALID,
		// Write ready. This signal indicates that the slave
    		// can accept the write data.
		output wire  S_AXI_WREADY,
		// Write response. This signal indicates the status
    		// of the write transaction.
		output wire [1 : 0] S_AXI_BRESP,
		// Write response valid. This signal indicates that the channel
    		// is signaling a valid write response.
		output wire  S_AXI_BVALID,
		// Response ready. This signal indicates that the master
    		// can accept a write response.
		input wire  S_AXI_BREADY,
		// Read address (issued by master, acceped by Slave)
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
		// Protection type. This signal indicates the privilege
    		// and security level of the transaction, and whether the
    		// transaction is a data access or an instruction access.
		input wire [2 : 0] S_AXI_ARPROT,
		// Read address valid. This signal indicates that the channel
    		// is signaling valid read address and control information.
		input wire  S_AXI_ARVALID,
		// Read address ready. This signal indicates that the slave is
    		// ready to accept an address and associated control signals.
		output wire  S_AXI_ARREADY,
		// Read data (issued by slave)
		output wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
		// Read response. This signal indicates the status of the
    		// read transfer.
		output wire [1 : 0] S_AXI_RRESP,
		// Read valid. This signal indicates that the channel is
    		// signaling the required read data.
		output wire  S_AXI_RVALID,
		// Read ready. This signal indicates that the master can
    		// accept the read data and response information.
		input wire  S_AXI_RREADY
	);

	// AXI4LITE signals
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_awaddr;
	reg  	axi_awready;
	reg  	axi_wready;
	reg [1 : 0] 	axi_bresp;
	reg  	axi_bvalid;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_araddr;
	reg  	axi_arready;
	reg [C_S_AXI_DATA_WIDTH-1 : 0] 	axi_rdata;
	reg [1 : 0] 	axi_rresp;
	reg  	axi_rvalid;

	// Example-specific design signals
	// local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
	// ADDR_LSB is used for addressing 32/64 bit registers/memories
	// ADDR_LSB = 2 for 32 bits (n downto 2)
	// ADDR_LSB = 3 for 64 bits (n downto 3)
	localparam integer ADDR_LSB = (C_S_AXI_DATA_WIDTH/32) + 1;
	localparam integer OPT_MEM_ADDR_BITS = 1;
	//----------------------------------------------
	//-- Signals for user logic register space example
	//------------------------------------------------
	//-- Number of Slave Registers 4
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg0;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg1;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg2;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg3;
	wire	 slv_reg_rden;
	wire	 slv_reg_wren;
	reg [C_S_AXI_DATA_WIDTH-1:0]	 reg_data_out;
	integer	 byte_index;
	reg	 aw_en;

	// I/O Connections assignments

	assign S_AXI_AWREADY	= axi_awready;
	assign S_AXI_WREADY	= axi_wready;
	assign S_AXI_BRESP	= axi_bresp;
	assign S_AXI_BVALID	= axi_bvalid;
	assign S_AXI_ARREADY	= axi_arready;
	assign S_AXI_RDATA	= axi_rdata;
	assign S_AXI_RRESP	= axi_rresp;
	assign S_AXI_RVALID	= axi_rvalid;
	// Implement axi_awready generation
	// axi_awready is asserted for one S_AXI_ACLK clock cycle when both
	// S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_awready is
	// de-asserted when reset is low.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_awready <= 1'b0;
	      aw_en <= 1'b1;
	    end 
	  else
	    begin    
	      if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
	        begin
	          // slave is ready to accept write address when 
	          // there is a valid write address and write data
	          // on the write address and data bus. This design 
	          // expects no outstanding transactions. 
	          axi_awready <= 1'b1;
	          aw_en <= 1'b0;
	        end
	        else if (S_AXI_BREADY && axi_bvalid)
	            begin
	              aw_en <= 1'b1;
	              axi_awready <= 1'b0;
	            end
	      else           
	        begin
	          axi_awready <= 1'b0;
	        end
	    end 
	end       

	// Implement axi_awaddr latching
	// This process is used to latch the address when both 
	// S_AXI_AWVALID and S_AXI_WVALID are valid. 

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_awaddr <= 0;
	    end 
	  else
	    begin    
	      if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
	        begin
	          // Write Address latching 
	          axi_awaddr <= S_AXI_AWADDR;
	        end
	    end 
	end       

	// Implement axi_wready generation
	// axi_wready is asserted for one S_AXI_ACLK clock cycle when both
	// S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_wready is 
	// de-asserted when reset is low. 

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_wready <= 1'b0;
	    end 
	  else
	    begin    
	      if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID && aw_en )
	        begin
	          // slave is ready to accept write data when 
	          // there is a valid write address and write data
	          // on the write address and data bus. This design 
	          // expects no outstanding transactions. 
	          axi_wready <= 1'b1;
	        end
	      else
	        begin
	          axi_wready <= 1'b0;
	        end
	    end 
	end       

	// Implement memory mapped register select and write logic generation
	// The write data is accepted and written to memory mapped registers when
	// axi_awready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted. Write strobes are used to
	// select byte enables of slave registers while writing.
	// These registers are cleared when reset (active low) is applied.
	// Slave register write enable is asserted when valid address and data are available
	// and the slave is ready to accept the write address and write data.
	assign slv_reg_wren = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      slv_reg0[31:16] <= 0;
	      slv_reg1 <= 0;
	      slv_reg2 <= 0;
	      slv_reg3 <= 0;
	    end 
	  else begin
	    if (slv_reg_wren)
	      begin
	        case ( axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
	          2'h0:
	            for ( byte_index = 2; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 0
	                slv_reg0[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          2'h1:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 1
	                slv_reg1[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          2'h2:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 2
	                slv_reg2[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          2'h3:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 3
	                slv_reg3[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          default : begin
	                      slv_reg0[31:16] <= slv_reg0[31:16];
	                      slv_reg1 <= slv_reg1;
	                      slv_reg2 <= slv_reg2;
	                      slv_reg3 <= slv_reg3;
	                    end
	        endcase
	      end
	  end
	end    

	// Implement write response logic generation
	// The write response and response valid signals are asserted by the slave 
	// when axi_wready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted.  
	// This marks the acceptance of address and indicates the status of 
	// write transaction.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_bvalid  <= 0;
	      axi_bresp   <= 2'b0;
	    end 
	  else
	    begin    
	      if (axi_awready && S_AXI_AWVALID && ~axi_bvalid && axi_wready && S_AXI_WVALID)
	        begin
	          // indicates a valid write response is available
	          axi_bvalid <= 1'b1;
	          axi_bresp  <= 2'b0; // 'OKAY' response 
	        end                   // work error responses in future
	      else
	        begin
	          if (S_AXI_BREADY && axi_bvalid) 
	            //check if bready is asserted while bvalid is high) 
	            //(there is a possibility that bready is always asserted high)   
	            begin
	              axi_bvalid <= 1'b0; 
	            end  
	        end
	    end
	end   

	// Implement axi_arready generation
	// axi_arready is asserted for one S_AXI_ACLK clock cycle when
	// S_AXI_ARVALID is asserted. axi_awready is 
	// de-asserted when reset (active low) is asserted. 
	// The read address is also latched when S_AXI_ARVALID is 
	// asserted. axi_araddr is reset to zero on reset assertion.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_arready <= 1'b0;
	      axi_araddr  <= 32'b0;
	    end 
	  else
	    begin    
	      if (~axi_arready && S_AXI_ARVALID)
	        begin
	          // indicates that the slave has acceped the valid read address
	          axi_arready <= 1'b1;
	          // Read address latching
	          axi_araddr  <= S_AXI_ARADDR;
	        end
	      else
	        begin
	          axi_arready <= 1'b0;
	        end
	    end 
	end       

	// Implement axi_arvalid generation
	// axi_rvalid is asserted for one S_AXI_ACLK clock cycle when both 
	// S_AXI_ARVALID and axi_arready are asserted. The slave registers 
	// data are available on the axi_rdata bus at this instance. The 
	// assertion of axi_rvalid marks the validity of read data on the 
	// bus and axi_rresp indicates the status of read transaction.axi_rvalid 
	// is deasserted on reset (active low). axi_rresp and axi_rdata are 
	// cleared to zero on reset (active low).  
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_rvalid <= 0;
	      axi_rresp  <= 0;
	    end 
	  else
	    begin    
	      if (axi_arready && S_AXI_ARVALID && ~axi_rvalid)
	        begin
	          // Valid read data is available at the read data bus
	          axi_rvalid <= 1'b1;
	          axi_rresp  <= 2'b0; // 'OKAY' response
	        end   
	      else if (axi_rvalid && S_AXI_RREADY)
	        begin
	          // Read data is accepted by the master
	          axi_rvalid <= 1'b0;
	        end                
	    end
	end    

	// Implement memory mapped register select and read logic generation
	// Slave register read enable is asserted when valid address is available
	// and the slave is ready to accept the read address.
	assign slv_reg_rden = axi_arready & S_AXI_ARVALID & ~axi_rvalid;
	always @(*)
	begin
	      // Address decoding for reading registers
	      case ( axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
	        2'h0   : reg_data_out <= slv_reg0;
	        2'h1   : reg_data_out <= slv_reg1;
	        2'h2   : reg_data_out <= slv_reg2;
	        2'h3   : reg_data_out <= slv_reg3;
	        default : reg_data_out <= 0;
	      endcase
	end

	// Output register or memory read data
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_rdata  <= 0;
	    end 
	  else
	    begin    
	      // When there is a valid read address (S_AXI_ARVALID) with 
	      // acceptance of read address by the slave (axi_arready), 
	      // output the read dada 
	      if (slv_reg_rden)
	        begin
	          axi_rdata <= reg_data_out;     // register read data
	        end   
	    end
	end    

	// Add user logic here
	wire eos_out;
    reg [10:0] s00_axi_awaddr;
    reg [2 : 0] s00_axi_awprot;
    reg s00_axi_awvalid;
    wire s00_axi_awready;
    reg [C_S_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata;
    reg [(C_S_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb;
    reg s00_axi_wvalid;
    wire s00_axi_wready;
    wire [1 : 0] s00_axi_bresp;
    wire s00_axi_bvalid;
    reg s00_axi_bready;
    reg [10:0] s00_axi_araddr;
    reg [2 : 0] s00_axi_arprot;
    reg s00_axi_arvalid;
    wire  s00_axi_arready;
    wire [C_S_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata;
    wire [1 : 0] s00_axi_rresp;
    wire  s00_axi_rvalid;
    reg s00_axi_rready;
	
    xadc_design_xadc_wiz_0_0 xadc_wiz_0
         (.eos_out(eos_out),
          .s_axi_aclk(S_AXI_ACLK),
          .s_axi_araddr(s00_axi_araddr),
          .s_axi_aresetn(S_AXI_ARESETN),
          .s_axi_arready(s00_axi_arready),
          .s_axi_arvalid(s00_axi_arvalid),
          .s_axi_awaddr(s00_axi_awaddr),
          .s_axi_awready(s00_axi_awready),
          .s_axi_awvalid(s00_axi_awvalid),
          .s_axi_bready(s00_axi_bready),
          .s_axi_bresp(s00_axi_bresp),
          .s_axi_bvalid(s00_axi_bvalid),
          .s_axi_rdata(s00_axi_rdata),
          .s_axi_rready(s00_axi_rready),
          .s_axi_rresp(s00_axi_rresp),
          .s_axi_rvalid(s00_axi_rvalid),
          .s_axi_wdata(s00_axi_wdata),
          .s_axi_wready(s00_axi_wready),
          .s_axi_wstrb(s00_axi_wstrb),
          .s_axi_wvalid(s00_axi_wvalid),
          .vauxn12(1'b0),
          .vauxn4(potentio_v_n),
          .vauxp12(1'b0),
          .vauxp4(potentio_v_p),
          .vn_in(1'b0),
          .vp_in(1'b0));
	
    reg [1:0] eos_reg;
    
    always @(posedge S_AXI_ACLK)
    begin
        if (S_AXI_ARESETN == 1'b0)
        begin
            eos_reg <= 1'b0;
            s00_axi_arprot <= 0;
        end
        else
        begin
            eos_reg <= {eos_reg[0],eos_out};
        end
    end
    
    reg [11:0] counter;
    reg [11:0] downsampling_reg;
    
    always @(posedge S_AXI_ACLK)
    begin
        if (S_AXI_ARESETN == 1'b0)
        begin
            counter <= 10'd0;
            downsampling_reg <= 12'd1878;   // one second interval
        end
        else
        begin
            downsampling_reg <= (slv_reg0[27:16] >0)?slv_reg0[27:16]:12'd1878;
            if (eos_reg == 2'b01)
            begin
                if (counter < downsampling_reg-1)
                begin
                    counter <= counter + 10'd1;
                end
                else
                begin
                    counter <= 10'd0;
                end
            end
        end
    end
    
    // Writting bus
    reg [1:0] write_state;
    reg write_trigger;
    always @(posedge S_AXI_ACLK)
    begin
        if (S_AXI_ARESETN == 1'b0)
        begin
            s00_axi_awvalid <= 1'b0;
            s00_axi_wvalid <= 1'b0;
            s00_axi_bready <= 1'b0;
            s00_axi_awprot <= 0;
            s00_axi_wstrb <= 4'b1111;
            write_state <= 0;
        end
        else
        begin
            if (write_state == 0)
            begin
                if (write_trigger)
                begin
                    s00_axi_awvalid <= 1'b1;
                    s00_axi_wvalid <= 1'b1;
                    write_state <= 1;
                end
            end
            else if (write_state == 1)
            begin
                if (s00_axi_awready && s00_axi_wready)
                begin
                    s00_axi_bready <= 1'b1;
                    write_state <= 2;
                end
            end
            else if (write_state == 2)
            begin
                if (s00_axi_bvalid)
                begin
                    s00_axi_awvalid <= 1'b0;
                    s00_axi_wvalid <= 1'b0;
                    write_state <= 3;
                end
            end
            else if (write_state == 3)
            begin
                if (!s00_axi_bvalid)
                begin
                    s00_axi_bready <= 1'b0;
                    write_state <= 0;
                end
            end
        end
    end
    
    // Accessing bus
    reg [1:0] access_state;
    reg [3:0] access_counter;
    reg access_trigger;
    reg [10:0] awaddr;
    reg [31:0] awdata;
    always @(posedge S_AXI_ACLK)
    begin
        if (S_AXI_ARESETN == 1'b0)
        begin
            write_trigger <= 1'b0;
            access_state <= 0;
            access_counter <= 0;
            s00_axi_awaddr <= 0;
            s00_axi_wdata <= 0;
        end
        else if (access_state == 0)
        begin
            if (access_trigger)
            begin
                access_counter <= 0;
                access_state <= 1;
            end
        end
        else if (access_state == 1)
        begin
            if (access_counter == 3 && write_state == 3)
            begin
                access_counter <= 0;
                access_state <= 2;
            end
            else if (access_counter < 3)
            begin
                access_counter <= access_counter + 1;
                if (access_counter == 0)
                begin
                    s00_axi_awaddr = awaddr;
                    s00_axi_wdata = awdata;
                end
                else if (access_counter == 1)
                begin
                    write_trigger <= 1'b1;
                end
                else if (access_counter == 2)
                begin
                    write_trigger <= 1'b0;
                end
            end
        end
        else if (access_state == 2) // Wait for 16 clocks cycle
        begin
            if (access_counter == 15)
            begin
                access_counter <= 0;
                access_state <= 3;
            end
            else if (access_counter < 15)
            begin
                access_counter <= access_counter + 1;
            end
        end
        else if (access_state == 3)
        begin
            access_state <= 0;
        end
    end
    
    // Read bus
    reg [1:0] read_state;
    reg read_trigger;
    reg [10:0] araddr;
    reg [31:0] ardata;
    reg read_ok;
    always @(posedge S_AXI_ACLK)
    begin
        if (S_AXI_ARESETN == 1'b0)
        begin
            read_state <= 0;
            ardata <= 0;
            read_ok <= 1'b0;
            s00_axi_araddr <= 0;
        end
        else if (read_state == 0)
        begin
            read_ok <= 1'b0;
            if (read_trigger)
            begin
                s00_axi_araddr <= araddr;
                read_state <= 1;
            end
        end
        else if (read_state == 1)
        begin
            s00_axi_arvalid <= 1'b1;
            s00_axi_rready <= 1'b1;
            read_state <= 2;
        end
        else if (read_state == 2)
        begin
            if (s00_axi_arready)
            begin
                read_state <= 3;
            end
        end
        else if (read_state == 3)
        begin
            if (s00_axi_rvalid)
            begin
                read_ok <= 1'b1;
                s00_axi_arvalid <= 1'b0;
                s00_axi_rready <= 1'b0;
                read_state <= 0;
                ardata <= s00_axi_rdata;
            end
        end
    end
    
    // XADC Activation system
    reg [2:0] management_state;
    reg [1:0] management_counter;
    reg [1:0] reading_counter;
    reg reading;
    always @(posedge S_AXI_ACLK)
    begin
        if (S_AXI_ARESETN == 1'b0)
        begin
            management_state <= 0;
            management_counter <= 0;
            access_trigger <= 0;
            awaddr <= 0;
            awdata <= 0;
            reading_counter <= 0;
            araddr <= 0;
            reading <= 0;
            read_trigger <= 0;
            slv_reg0[15:0] <= 0;
        end
        else
        begin
            if (management_state == 0)          // Software Reset Register
            begin
                if (management_counter == 3 && access_state == 3)
                begin
                    management_state <= management_state + 1;
                    management_counter <= 0;
                end
                else if (management_counter < 3)
                begin
                    management_counter <= management_counter + 1;
                    if (management_counter == 0)
                    begin
                        awaddr <= 11'h0;
                        awdata <= 32'ha;        // Reset XADC IP core
                    end
                end
            end
            else if (management_state == 1)     // Channel selection 0
            begin
                if (management_counter == 3 && access_state == 3)
                begin
                    management_state <= management_state + 1;
                    management_counter <= 0;
                end
                else if (management_counter < 3)
                begin
                    management_counter <= management_counter + 1;
                    if (management_counter == 0)
                    begin
                        awaddr <= 11'h320;
                        awdata <= 32'h0;
                    end
                end
            end
            else if (management_state == 2)     // Channel selection 1
            begin
                if (management_counter == 3 && access_state == 3)
                begin
                    management_state <= management_state + 1;
                    management_counter <= 0;
                end
                else if (management_counter < 3)
                begin
                    management_counter <= management_counter + 1;
                    if (management_counter == 0)
                    begin
                        awaddr <= 11'h324;
                        awdata <= 32'h10;       // AUX 4 enable
                    end
                end
            end
            else if (management_state == 3)     // Channel selection 2
            begin
                if (management_counter == 3 && access_state == 3)
                begin
                    management_state <= management_state + 1;
                    management_counter <= 0;
                end
                else if (management_counter < 3)
                begin
                    management_counter <= management_counter + 1;
                    if (management_counter == 0)
                    begin
                        awaddr <= 11'h318;
                        awdata <= 32'h0;
                    end
                end
            end
            else if (management_state == 4)     // Sequencer mode
            begin
                if (!reading)
                begin
                    if (reading_counter == 0)
                    begin
                        araddr <= 11'h304;
                        reading_counter <= reading_counter + 1;
                    end
                    else if (reading_counter == 1)
                    begin
                        read_trigger <= 1'b1;
                        reading_counter <= reading_counter + 1;
                    end
                    else if (reading_counter == 2)
                    begin
                        read_trigger <= 1'b0;
                        reading_counter <= reading_counter + 1;
                    end
                    else if (read_ok)
                    begin
                        reading <= 1;
                    end
                end
                else if (management_counter == 3 && access_state == 3)
                begin
                    management_state <= management_state + 1;
                    management_counter <= 0;
                    reading_counter <= 0;
                    reading <= 0;
                end
                else if (management_counter < 3)
                begin
                    management_counter <= management_counter + 1;
                    if (management_counter == 0)
                    begin
                        awaddr <= 11'h304;
                        awdata <= {ardata[31:16], 4'h4 ,ardata[11:0]};        // Mode simultaneous
                    end
                end
            end
            else if (management_state == 5)
            begin
                if (eos_reg == 2'b01)
                begin
                    reading <= 1;
                end
                else if (reading)
                begin
                    if (reading_counter == 0)
                    begin
                        araddr <= 11'h250;
                        reading_counter <= reading_counter + 1;
                    end
                    else if (reading_counter == 1)
                    begin
                        read_trigger <= 1'b1;
                        reading_counter <= reading_counter + 1;
                    end
                    else if (reading_counter == 2)
                    begin
                        read_trigger <= 1'b0;
                        reading_counter <= reading_counter + 1;
                    end
                    else if (read_ok)
                    begin
                        slv_reg0[15:0] <= ardata[15:0];
                        reading <= 0;
                        reading_counter <= 0;
                    end
                end
            end
            if (management_counter == 1)
            begin
                access_trigger <= 1'b1;
            end
            else if (management_counter == 2)
            begin
                access_trigger <= 1'b0;
            end
        end
    end
        
    assign interrupt = eos_reg[1] && (counter == 10'd0);    
	// User logic ends

	endmodule
