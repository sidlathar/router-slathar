`default_nettype none
`include "Router.svh"
`include "RouterPkg.pkg"

//////
////// Network on Chip (NoC) 18-341
////// Node module
//////
module Node #(parameter NODEID = 0) (
  input logic clock, reset_n,

  //Interface to testbench: the blue arrows
  input  pkt_t pkt_in,        // Data packet from the TB
  input  logic pkt_in_avail,  // The packet from TB is available
  output logic cQ_full,       // The queue is full

  output pkt_t pkt_out,       // Outbound packet from node to TB
  output logic pkt_out_avail, // The outbound packet is available

  //Interface with the router: black arrows
  input  logic       free_outbound,    // Router is free
  output logic       put_outbound,     // Node is transferring to router
  output logic [7:0] payload_outbound, // Data sent from node to router

  output logic       free_inbound,     // Node is free
  input  logic       put_inbound,      // Router is transferring to node
  input  logic [7:0] payload_inbound); // Data sent from router to node

  pkt_t data_in, data_out, reg_out, reg_in, chopReg, go_out;
  logic re, we, full, empty, regEmpty, en_reg_n;
  logic [3:0] n2rcount, r2ncount;
  logic [3:0] count, count1;
  //assign cQ_full = full;

  FIFO queue(.*);
  // register choppingReg(.clock(clock), .reset_L(reset_n), .load_L(en_reg_n),
  //                     .in(reg_in), .out(reg_out));


  pkt_t [3:0] Qu;
  assign cQ_full = (count==4'd4);

  assign Qu = queue.Q;
  assign count1 = queue.count;


  always_ff @ (posedge clock, negedge reset_n) begin //Q read
    if(~reset_n) begin
      count <= 0;
      re <= 0;
      we <= 0;
      regEmpty <= 1;
      n2rcount <= 0;
      put_outbound <= 0;
    end

    else begin
      if(~cQ_full && pkt_in_avail) begin //value in chopping reg already so put in Queue
          data_in <= pkt_in;
          we <= 1;
          count <= count + 1;
      end
      else begin
        we <= 0;
      end

      if(regEmpty && (~empty) && (data_out !== 32'b0)) begin //value was read into Router send next val
        re <= 1;
        chopReg <= data_out;
        regEmpty <= 0;
        count <= (count == 0)? count :count - 1;
      end
      else if (regEmpty && (~empty) && (data_out == 32'b0)) begin
        re <= 1;
        regEmpty <= 1;
      end
      // else if (regEmpty && (~empty)) begin
      //   re <= 1;
      //   regEmpty <= 1;
      // end
      else begin
        re <= 0;
      end


      // send packet to router when value is in chopping reg
      if((~regEmpty && free_outbound) || put_outbound) begin
        unique case(n2rcount)
          4'd0: begin
            payload_outbound <= chopReg[31:24];
            n2rcount <= n2rcount + 1;
            put_outbound <= 1;
          end
          4'd1: begin
            payload_outbound <= chopReg[23:16];
            n2rcount <= n2rcount + 1;
            put_outbound <= 1;
          end
          4'd2: begin
            payload_outbound <= chopReg[15:8];
            n2rcount <= n2rcount + 1;
            put_outbound <= 1;
          end
          4'd3: begin
            payload_outbound <= chopReg[7:0];
            n2rcount <= n2rcount + 1;
            put_outbound <= 1;

          end
          4'd4: begin     // reset n2rcount, put_outbound
            n2rcount <= 0;
            chopReg <= 32'bx;
            put_outbound <= 0;
            //count <= count - 1;
            regEmpty <= 1;
          end
        endcase
      end
    end
  end

  logic pl1_load, pl2_load, pl3_load, pl4_load;
  logic [7:0] pl4_out, pl1_out, pl2_out, pl3_out;
  logic [3:0] en_reg;
  logic [1:0] select;
  logic [7:0] r_in;

  assign r_in = payload_inbound;
  register pl1(.load(pl1_load), .in(r_in), .out(pl1_out), .*);
  register pl2(.load(pl2_load), .in(r_in), .out(pl2_out), .*);
  register pl3(.load(pl3_load), .in(r_in), .out(pl3_out), .*);
  register pl4(.load(pl4_load), .in(r_in), .out(pl4_out), .*);

  // task jumpAvail();
  //   @(posedge clock);
  //   pkt_out_avail = 1;
  //   @(posedge clock);
  //   pkt_out_avail = 0;
  // endtask



  demux regEn(.in(1), .out(en_reg), .sel(select));
  logic assignVal;
  assign pkt_out = {pl1_out, pl2_out, pl3_out, pl4_out};

  always_ff @ (posedge clock, negedge reset_n) begin //router to node transfer
    if(~reset_n) begin
      free_inbound <= 1;
      select <= 2'b0;
      pkt_out_avail <= 0;
      pl1_load <= 1;
      assignVal <= 0;
    end
    else if(put_inbound) begin
      pl1_load <= 0;
      pl2_load <= en_reg[0];
      pl3_load <= en_reg[1];
      pl4_load <= en_reg[2];
      free_inbound <= 0;
      pkt_out_avail <= 0;
      select <= select + 1;
      if(select == 3) begin
        free_inbound <= 1;
        pl1_load <= 0;
        pl4_load <= 0;
        pkt_out_avail <= 0;
        assignVal <= 1;
        //jumpAvail();

      end
    end
    else if(assignVal) begin
      pl1_load <= 1;
      select <= 2'b0;
      pkt_out_avail <= 1;
      assignVal <= 0;
    end
    else begin
      pkt_out_avail <= 0;
      select <= 2'b0;
    end
  end
endmodule: Node

/*
 *  Create a FIFO (First In First Out) buffer with depth 4 using the given
 *  interface and constraints
 *    - The buffer is initally empty
 *    - Reads are combinational, so data_out is valid unless empty is asserted
 *    - Removal from the queue is processed on the clock edge.
 *    - Writes are processed on the clock edge
 *    - If a write is pending while the buffer is full, do nothing
 *    - If a read is pending while the buffer is empty, do nothing
 */

 module FIFO (
   input logic              clock, reset_n,
   input pkt_t              data_in,
   input logic              we, re,
   output pkt_t             data_out,
   output logic             full, empty);

   pkt_t [3:0] Q;
   logic [2:0] putPtr, getPtr; // pointers wrap automatically
   logic [3:0] count;

   assign empty = (count == 0);
   assign full  = (count == 4'd4);

   assign data_out = (~empty)? Q[0] : 32'bz; // combinatinally assign data_out

   always_ff @(posedge clock, negedge reset_n) begin
     if (~reset_n) begin
       count  <= 0;
       getPtr <= 0;
       putPtr <= 0;
     end
     else begin
      if (we && (!full)) begin //not full so put in queue
          Q[putPtr] = data_in;
          putPtr = putPtr + 1;
          count = count + 1;
      end
      if(re && !empty) begin //remove from queue when re is asserted
           putPtr = putPtr - 1;
           Q = Q[3:1];
           count = count - 1;
      end
     end
   end
 endmodule: FIFO
/*
 * module: register
 *
 * A positive-edge clocked parameterized register with (active low) load enable
 * and asynchronous reset. The parameter is the bit-width of the register.
 */
module register #(parameter WIDTH = 8)(
   output logic [WIDTH - 1:0]   out,
   input  logic [WIDTH - 1:0]   in,
   input                  load,
   input                  clock,
   input                  reset_n);

   always_ff @ (posedge clock, negedge reset_n) begin
      if(~reset_n)
         out <= 'b0000;
      else if (load)
         out <= in;
   end

endmodule


module demux #(parameter OUT_WIDTH = 4, IN_WIDTH = 2, DEFAULT = 0)(
   input logic                    in,
   input  logic [IN_WIDTH-1:0]       sel,
   output logic [OUT_WIDTH-1:0] out);

   always_comb begin
      out = (DEFAULT==0)?'b0:(~('b0));
      out[sel] = in;
   end

endmodule
