`default_nettype none
`include "Router.svh"
`include "RouterPkg.pkg"

//////
////// Network on Chip (NoC) 18-341
////// Router module
//////
module Router #(parameter ROUTERID = 0) (
    input logic             clock, reset_n,

    input logic [3:0]       free_outbound,     // Node is free
    input logic [3:0]       put_inbound,       // Node is transferring to router
    input logic [3:0][7:0]  payload_inbound,   // Data sent from node to router

    output logic [3:0]      free_inbound,      // Router is free
    output logic [3:0]      put_outbound,      // Router is transferring to node
    output logic [3:0][7:0] payload_outbound); // Data sent from router to node

    //Begin input ports to intermediate regs
    pkt_t reg0, reg1, reg2, reg3;
    logic [3:0] regEmpty;
    pkt_t [3:0] pkt_out;
    logic [3:0] pkt_out_avail_reg;
    logic [3:0] allowRec;
    logic [3:0] read_done;
    logic [3:0] routerID;

    assign routerID = ROUTERID;

    //Get chopped inputs from input port and store them in pkt_t register
    // for (int n = 0; n < 4; n++) begin
    //   if(put_inbound[n] && free_inbound[n]) begin
    //     recv_routernew(n[3:0]);
    //   end

    always_ff @ (posedge clock, negedge reset_n) begin
      if(~reset_n) begin
        free_inbound[0] <= 1'b1;
        pkt_out_avail_reg[0] <= 1'b0;
      end
      else begin
        if(put_inbound[0] && free_inbound[0]) begin
          recv_router0();
        end
      end
    end

    always_ff @ (posedge clock, negedge reset_n) begin
      if(~reset_n) begin
        free_inbound[1] <= 1'b1;
        pkt_out_avail_reg[1] <= 1'b0;
      end
      else begin
        if(put_inbound[1] && free_inbound[1]) begin
          recv_router1();
        end
      end
    end

    always_ff @ (posedge clock, negedge reset_n) begin
      if(~reset_n) begin
        free_inbound[2] <= 1'b1;
        pkt_out_avail_reg[2] <= 1'b0;
      end
      else begin
        if(put_inbound[2] && free_inbound[2]) begin
          recv_router2();
        end
      end
    end

    always_ff @ (posedge clock, negedge reset_n) begin
      if(~reset_n) begin
        free_inbound[3] <= 1'b1;
        pkt_out_avail_reg[3] <= 1'b0;
      end
      else begin
        if(put_inbound[3] && free_inbound[3]) begin
          recv_router3();
        end
      end
    end
    //
    // choppingAssemble node0(.payload_inbound(payload_inbound[0]),
    //                        .read_done(read_done[0]),
    //                        .pkt_out_avail_reg(pkt_out_avail_reg[0]),
    //                        .pkt_out(pkt_out[0]), .allowRec(allowRec[0]),
    //                        .regEmpty(regEmpty[0]), .*);
    // choppingAssemble node1(.payload_inbound(payload_inbound[1]),
    //                       .read_done(read_done[1]),
    //                       .pkt_out_avail_reg(pkt_out_avail_reg[1]),
    //                       .pkt_out(pkt_out[1]), .allowRec(allowRec[1]),
    //                       .regEmpty(regEmpty[1]),.*);
    // choppingAssemble node2(.payload_inbound(payload_inbound[2]),
    //                        .read_done(read_done[2]),
    //                        .pkt_out_avail_reg(pkt_out_avail_reg[2]),
    //                        .pkt_out(pkt_out[2]), .allowRec(allowRec[2]),
    //                        .regEmpty(regEmpty[2]), .*);
    // choppingAssemble node3(.payload_inbound(payload_inbound[3]),
    //                       .read_done(read_done[3]),
    //                       .pkt_out_avail_reg(pkt_out_avail_reg[3]),
    //                       .pkt_out(pkt_out[3]), .allowRec(allowRec[3]),
    //                       .regEmpty(regEmpty[3]), .*);



  logic [3:0][3:0] output_Port;
  always_comb begin
    if(~reset_n) begin
      output_Port <= 'hffff;
    end
    else begin
      for (int l = 0; l < 4; l++) begin
        case({routerID,val[l].dest})
            8'b0000_0000: output_Port[l] = 0;
            8'b0000_0001: output_Port[l] = 2;
            8'b0000_0010: output_Port[l] = 3;
            8'b0000_0011: output_Port[l] = 1;
            8'b0000_0100: output_Port[l] = 1;
            8'b0000_0101: output_Port[l] = 1;
            8'b0000_1111: output_Port[l] = -1;

            8'b0001_0000: output_Port[l] = 3;
            8'b0001_0001: output_Port[l] = 3;
            8'b0001_0010: output_Port[l] = 3;
            8'b0001_0011: output_Port[l] = 0;
            8'b0001_0100: output_Port[l] = 1;
            8'b0001_0101: output_Port[l] = 2;
            8'b0001_1111: output_Port[l] = -1;
            default: output_Port = -1;
        endcase
      end
    end
  end
  //Check all input port for packets; Randomize similar destinations;


  logic [3:0] we;
  logic [3:0] re;
  logic [3:0] full;
  logic [3:0] empty;
  pkt_t [3:0] data_in;
  pkt_t [3:0] data_out;

  FIFO queue0(.data_in(data_in[0]), .we(we[0]), .re(re[0]), .data_out(data_out[0]),
              .full(full[0]), .empty(empty[0]), .*);
  FIFO queue1(.data_in(data_in[1]), .we(we[1]), .re(re[1]), .data_out(data_out[1]),
              .full(full[1]), .empty(empty[1]), .*);
  FIFO queue2(.data_in(data_in[2]), .we(we[2]), .re(re[2]), .data_out(data_out[2]),
              .full(full[2]), .empty(empty[2]), .*);
  FIFO queue3(.data_in(data_in[3]), .we(we[3]), .re(re[3]), .data_out(data_out[3]),
              .full(full[3]), .empty(empty[3]), .*);


  //assign free_inbound = regEmpty;
  //assign allowRec = put_inbound && regEmpty;
  logic [1:0] priorityNum;
  pkt_t [3:0] val;
  logic [3:0][3:0] destinations;
  logic pkt_avail;
  logic [3:0] op, whatval;



  function logic matcingDest(input logic [3:0][3:0] destinations,
    input logic [3:0] checkDest);
    if (checkDest == 4'b0) begin return 1'b0; end
    else begin
      for (int k = 0; k < checkDest; k++) begin
        if (destinations[checkDest] == destinations[k]) begin
          return 1'b1;
        end
      end
      return 1'b0;
    end
  endfunction

  always_ff @ (posedge clock, negedge reset_n) begin
    if(~reset_n) begin
      //read_done <= 4'b1111;
      priorityNum <= 2'd0;
      val <= 0;
      pkt_avail <= 0;
      we <= 4'b0000;
    end
    else begin
      we <= 4'b0000;
      if(pkt_out_avail_reg > 4'b0000) begin
        //read_done <= 4'b0000;
        pkt_avail <= 1;
        //genvar i;
        //generate
          for(int i = 0; i < 4; i++) begin
            if(pkt_out_avail_reg[i]) begin
              val[i] = pkt_out[i];
              destinations[i] = pkt_out[i].dest;
              end
            else begin
              val[i].dest = -1;
              //read_done[i] <= 1'b1;
              destinations[i] = -1;
            end
          end
        //endgenerate
      end

      else begin pkt_avail <= 0; end

      if (pkt_avail) begin
        priorityNum <= priorityNum + 1;
        //genvar j;
        //generate
          for(int j = 0; j < 4; j++) begin

            if (~(val[j].dest == -1) && ~(matcingDest(destinations, j[3:0]))
                    && ~full[output_Port[j]]) begin
              op <= output_Port[j];
              whatval <= j;
              data_in[output_Port[j]] <= val[j];
              we[output_Port[j]] <= 1'b1;
              //read_done[j] <= 1'b1;
            end
          end
        //endgenerate
      end
    end
  end



  //borrowed from NodeTB.sv


  // task send_router(input pkt_t pkt, input logic [3:0] whatQ);
  //   put_outbound[whatQ] <= 1;
  //   payload_outbound[whatQ] <= {pkt.src, pkt.dest};
  //   re[whatQ] <= 1;
  //   @(posedge clock);
  //   payload_outbound[whatQ] <= pkt.data[23:16];
  //   re[whatQ] <= 0;
  //   @(posedge clock);
  //   payload_outbound[whatQ] <= pkt.data[15:8];
  //   @(posedge clock);
  //   payload_outbound[whatQ] <= pkt.data[7:0];
  //   @(posedge clock);
  //   put_outbound[whatQ] <= 0;
  // endtask

  task send_router0(input pkt_t pkt, input logic [3:0] whatQ);
    put_outbound[whatQ] <= 1;
    payload_outbound[whatQ] <= {pkt.src, pkt.dest};
    re[whatQ] <= 1;
    @(posedge clock);
    payload_outbound[whatQ] <= pkt.data[23:16];
    re[whatQ] <= 0;
    @(posedge clock);
    payload_outbound[whatQ] <= pkt.data[15:8];
    @(posedge clock);
    payload_outbound[whatQ] <= pkt.data[7:0];
    @(posedge clock);
    put_outbound[whatQ] <= 0;
  endtask


  task send_router1(input pkt_t pkt, input logic [3:0] whatQ);
    put_outbound[whatQ] <= 1;
    payload_outbound[whatQ] <= {pkt.src, pkt.dest};
    re[whatQ] <= 1;
    @(posedge clock);
    payload_outbound[whatQ] <= pkt.data[23:16];
    re[whatQ] <= 0;
    @(posedge clock);
    payload_outbound[whatQ] <= pkt.data[15:8];
    @(posedge clock);
    payload_outbound[whatQ] <= pkt.data[7:0];
    @(posedge clock);
    put_outbound[whatQ] <= 0;
  endtask


  task send_router2(input pkt_t pkt, input logic [3:0] whatQ);
    put_outbound[whatQ] <= 1;
    payload_outbound[whatQ] <= {pkt.src, pkt.dest};
    re[whatQ] <= 1;
    @(posedge clock);
    payload_outbound[whatQ] <= pkt.data[23:16];
    re[whatQ] <= 0;
    @(posedge clock);
    payload_outbound[whatQ] <= pkt.data[15:8];
    @(posedge clock);
    payload_outbound[whatQ] <= pkt.data[7:0];
    @(posedge clock);
    put_outbound[whatQ] <= 0;
  endtask


  task send_router3(input pkt_t pkt, input logic [3:0] whatQ);
    put_outbound[whatQ] <= 1;
    payload_outbound[whatQ] <= {pkt.src, pkt.dest};
    re[whatQ] <= 1;
    @(posedge clock);
    payload_outbound[whatQ] <= pkt.data[23:16];
    re[whatQ] <= 0;
    @(posedge clock);
    payload_outbound[whatQ] <= pkt.data[15:8];
    @(posedge clock);
    payload_outbound[whatQ] <= pkt.data[7:0];
    @(posedge clock);
    put_outbound[whatQ] <= 0;
  endtask


  // task recv_routernew(input logic [3:0] n);
  //   free_inbound[n] <= 0;
  //   {pkt_out[n].src, pkt_out[n].dest} <= payload_inbound[n];
  //   @(posedge clock);
  //   pkt_out[n].data[23:16] <= payload_inbound[n];
  //   @(posedge clock);
  //   pkt_out[n].data[15:8] <= payload_inbound[n];
  //   @(posedge clock);
  //   pkt_out[n].data[7:0] <= payload_inbound[n];
  //
  //   @(posedge clock);
  //   free_inbound[n] <= 1;
  //   pkt_out_avail_reg[n] <= 1;
  //   @(posedge clock);
  //   pkt_out_avail_reg[n] <= 0;
  // endtask

  task recv_router0();
    free_inbound[0] <= 0;
    {pkt_out[0].src, pkt_out[0].dest} <= payload_inbound[0];
    @(posedge clock);
    pkt_out[0].data[23:16] <= payload_inbound[0];
    @(posedge clock);
    pkt_out[0].data[15:8] <= payload_inbound[0];
    @(posedge clock);
    pkt_out[0].data[7:0] <= payload_inbound[0];

    @(posedge clock);
    free_inbound[0] <= 1;
    pkt_out_avail_reg[0] <= 1;
    @(posedge clock);
    pkt_out_avail_reg[0] <= 0;
  endtask

  task recv_router1();
    free_inbound[1] <= 0;
    {pkt_out[1].src, pkt_out[1].dest} <= payload_inbound[1];
    @(posedge clock);
    pkt_out[1].data[23:16] <= payload_inbound[1];
    @(posedge clock);
    pkt_out[1].data[15:8] <= payload_inbound[1];
    @(posedge clock);
    pkt_out[1].data[7:0] <= payload_inbound[1];
    @(posedge clock);
    free_inbound[1] <= 1;
    pkt_out_avail_reg[1] <= 1;
    @(posedge clock);
    pkt_out_avail_reg[1] <= 0;
  endtask

  task recv_router2();
    free_inbound[2] <= 0;
    {pkt_out[2].src, pkt_out[2].dest} <= payload_inbound[2];
    @(posedge clock);
    pkt_out[2].data[23:16] <= payload_inbound[2];
    @(posedge clock);
    pkt_out[2].data[15:8] <= payload_inbound[2];
    @(posedge clock);
    pkt_out[2].data[7:0] <= payload_inbound[2];
    @(posedge clock);
    free_inbound[2] <= 1;
    pkt_out_avail_reg[2] <= 1;
    @(posedge clock);
    pkt_out_avail_reg[2] <= 0;
  endtask

  task recv_router3();
    free_inbound[3] <= 0;
    {pkt_out[3].src, pkt_out[3].dest} <= payload_inbound[3];
    @(posedge clock);
    pkt_out[3].data[23:16] <= payload_inbound[3];
    @(posedge clock);
    pkt_out[3].data[15:8] <= payload_inbound[3];
    @(posedge clock);
    pkt_out[3].data[7:0] <= payload_inbound[3];
    @(posedge clock);
    free_inbound[3] <= 1;
    pkt_out_avail_reg[3] <= 1;
    @(posedge clock);
    pkt_out_avail_reg[3] <= 0;
  endtask




//Get pkt from queue and send to the output port 8 bit at a time

  always_ff @ (posedge clock, negedge reset_n) begin
    if(~reset_n) begin
      re[0] <= 1'b0;
      put_outbound[0] <= 1'b0;
    end
    else begin
      if (free_outbound[0] == 1'b1 && ~(empty[0])) begin
        send_router0(data_out[0], 4'd0);
      end
    end
  end

  always_ff @ (posedge clock, negedge reset_n) begin
    if(~reset_n) begin
      re[1] <= 1'b0;
      put_outbound[1] <= 1'b0;
    end
    else begin
      if (free_outbound[1] == 1'b1 && ~(empty[1])) begin
        send_router1(data_out[1], 4'd1);
      end
    end
  end

  always_ff @ (posedge clock, negedge reset_n) begin
    if(~reset_n) begin
      re[2] <= 1'b0;
      put_outbound[2] <= 1'b0;
    end
    else begin
      if (free_outbound[2] == 1'b1 && ~(empty[2])) begin
        send_router2(data_out[2], 4'd2);
      end
    end
  end

  always_ff @ (posedge clock, negedge reset_n) begin
    if(~reset_n) begin
      re[3] <= 1'b0;
      put_outbound[3] <= 1'b0;
    end
    else begin
      if (free_outbound[3] == 1'b1 && ~(empty[3])) begin
        send_router3(data_out[3], 4'd3);
      end
    end
  end

  // always_ff @ (posedge clock, negedge reset_n) begin
  //   if(~reset_n) begin
  //     re <= 4'b0000;
  //     put_outbound <= 4'b0000;
  //   end
  //   else begin
  //     if (free_outbound[0] == 1'b1 && ~(empty[0])) begin
  //       send_router(data_out[0], 4'd0);
  //     end
  //     if (free_outbound[1] == 1'b1 && (~empty[1])) begin
  //       send_router(data_out[1], 4'd1);
  //     end
  //     if (free_outbound[2] == 1'b1 && ~(empty[2])) begin
  //       send_router(data_out[2], 4'd2);
  //     end
  //     if (free_outbound[3] == 1'b1 && ~(empty[3])) begin
  //       send_router(data_out[3], 4'd3);
  //     end
  //   end
  // end
endmodule: Router

// module choppingAssemble (
//   input logic clock, reset_n,
//   input logic [7:0] payload_inbound,
//   input logic allowRec,
//   input logic read_done,
//   output pkt_t pkt_out,
//   output logic regEmpty,
//   output logic pkt_out_avail_reg);
//
//   logic pl1_load, pl2_load, pl3_load, pl4_load;
//   logic [7:0] pl4_out, pl1_out, pl2_out, pl3_out;
//   logic [3:0] en_reg;
//   logic [1:0] select;
//   logic [7:0] r_in;
//
//   assign r_in = payload_inbound;
//
//   register pl1(.load(pl1_load), .in(r_in), .out(pl1_out), .*);
//   register pl2(.load(pl2_load), .in(r_in), .out(pl2_out), .*);
//   register pl3(.load(pl3_load), .in(r_in), .out(pl3_out), .*);
//   register pl4(.load(pl4_load), .in(r_in), .out(pl4_out), .*);
//
//   demux regEn(.in(1), .out(en_reg), .sel(select));
//   assign pkt_out = {pl1_out, pl2_out, pl3_out, pl4_out};
//
//   always_ff @ (posedge clock, negedge reset_n) begin //router to node transfer
//     if(~reset_n) begin
//       //free_inbound <= 1;
//       select <= 2'b0;
//       pkt_out_avail_reg <= 0;
//       pl1_load <= 1;
//       regEmpty <= 1;
//     end
//     else if(allowRec) begin
//       regEmpty <= 0;
//       pkt_out_avail_reg <= 0;
//       pl1_load <= 0;
//       pl2_load <= en_reg[0];
//       pl3_load <= en_reg[1];
//       pl4_load <= en_reg[2];
//       //free_inbound <= 0;
//       pkt_out_avail_reg <= 0;
//       select <= select + 1;
//       if(select == 3) begin
//         //free_inbound <= 1;
//         pl1_load <= 1;
//         pl4_load <= 0;
//         pkt_out_avail_reg <= 1;
//         select <= 2'b0;
//         regEmpty <= 0;
//       end
//     end
//     else if(read_done) begin
//       select <= 2'b0;
//       pkt_out_avail_reg <= 0;
//       regEmpty <= 1;
//     end
//   end
// endmodule: choppingAssemble
