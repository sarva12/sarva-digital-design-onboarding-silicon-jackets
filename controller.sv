module controller import calculator_pkg::*;(
  	input  logic              clk_i,
    input  logic              rst_i,
  
  	// Memory Access
    input  logic [ADDR_W-1:0] read_start_addr,
    input  logic [ADDR_W-1:0] read_end_addr,
    input  logic [ADDR_W-1:0] write_start_addr,
    input  logic [ADDR_W-1:0] write_end_addr,
  
  	// Control
    output logic write,
    output logic [ADDR_W-1:0] w_addr,
    output logic [MEM_WORD_SIZE-1:0] w_data,

    output logic read,
    output logic [ADDR_W-1:0] r_addr,
    input  logic [MEM_WORD_SIZE-1:0] r_data,

  	// Buffer Control (1 = upper, 0, = lower)
    output logic              buffer_control,
  
  	// These go into adder
  	output logic [DATA_W-1:0]       op_a,
    output logic [DATA_W-1:0]       op_b,
  
    input  logic [MEM_WORD_SIZE-1:0]       buff_result
	
  
); 
	//TODO: Write your controller state machine as you see fit. 
	//HINT: See "6.2 Two Always BLock FSM coding style" from refmaterials/1_fsm_in_systemVerilog.pdf
	// This serves as a good starting point, but you might find it more intuitive to add more than two always blocks.

	//See calculator_pkg.sv for state_t enum definition
  	state_t state, next;
	logic half, half_n; 
  	logic [ADDR_W-1:0] w_ptr, w_ptr_n;     
	logic [ADDR_W-1:0] r_ptr, r_ptr_n;  
	logic [DATA_W-1:0] op_a_q, op_b_q;
	logic buffer_control_q;

	assign op_a = op_a_q;
	assign op_b = op_b_q;
	assign buffer_control = buffer_control_q;

	//State reg, other registers as needed
	always_ff @(posedge clk_i) begin
		if (rst_i) begin
			state <= S_IDLE;
			half  <= 1'b0;
			r_ptr <= read_start_addr;
			w_ptr <= write_start_addr;
			op_a_q <= '0;
			op_b_q <= '0;
			buffer_control_q <= 1'b0;

		end else begin
			state <= next;
			half  <= half_n;
			r_ptr <= r_ptr_n;
			w_ptr <= w_ptr_n;

			// load operands and which half to write ONLY in S_ADD
			if (state == S_RWAIT) begin
				op_a_q <= r_data[DATA_W-1:0];
				op_b_q <= r_data[2*DATA_W-1:DATA_W];
				buffer_control_q <= half; 
			end
		end
	end

	always_comb begin
		read = 1'b0; write = 1'b0; 
		r_addr = r_ptr;
		r_ptr_n = r_ptr;
		w_data = '0;
		w_addr = w_ptr;
		next = state; 
		half_n = half; 
		w_ptr_n = w_ptr; 

		case (state)
			S_IDLE: begin
				r_addr = read_start_addr; 
				w_addr = write_start_addr;
				half_n = 1'b0;                 
        		if ((read_start_addr <= read_end_addr) && (write_start_addr <= write_end_addr))
          			next = S_READ;
        		else
          			next = S_END;
			end
			S_READ:  begin
				read = 1'b1;
				r_addr = r_ptr;
				next = S_RWAIT;
			end
			S_RWAIT: begin
				next = S_ADD;
			end
			S_ADD: begin
				if (half == 1'b0) begin
					if (r_ptr < read_end_addr) begin
						r_ptr_n = r_ptr + 1;
						half_n  = 1'b1;
						next    = S_READ;
					end else begin
						next = S_END;
					end
				end else begin
					half_n = 1'b0;
					next   = S_WSET;
				end
			end
			S_WSET: begin
				w_addr = w_ptr;
				w_data = buff_result;
				next = S_WRITE;
			end
			S_WRITE: begin
				write  = 1'b1;
				w_addr = w_ptr;
				w_data = buff_result;
				if (w_ptr < write_end_addr)
					w_ptr_n = w_ptr + 1;
				if ((r_ptr + 1)<= read_end_addr) begin
					r_ptr_n = r_ptr + 1;
					next    = S_READ;    
				end else begin
					next    = S_END;
				end
			end

			S_END: begin
				next = S_END;
			end
			default: begin
    			next = S_IDLE;
			end
		endcase
	end

endmodule
