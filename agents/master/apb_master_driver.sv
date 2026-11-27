class apb_master_driver extends uvm_driver#(apb_seq_item);
  `uvm_component_utils(apb_master_driver)
  
  virtual apb_interface  apb_master_vif;
  
  apb_seq_item seq;
  
  function new(string name = "apb_master_driver", uvm_component parent);
    super.new(name, parent);
  endfunction
  ///////////////////////////////////////
  ///////// build_phase//////////////////
  function void build_phase (uvm_phase phase);
    super.build_phase(phase);
    // transaction signal configuration to interface   
    if (!uvm_config_db#(virtual apb_interface)::get(this, "", "apb_master", apb_master_vif))
      `uvm_fatal(get_type_name(), "connection not set at top level for vif")
    
  endfunction
  //////////////////////////////////
  //////// run_phase //////////////////
  
task run_phase(uvm_phase phase);
  super.run_phase(phase);
  apb_master_vif.psel    <= 0;
  apb_master_vif.penable <= 0;
  apb_master_vif.pwrite  <= 0;
  apb_master_vif.paddr   <= 0;
  apb_master_vif.pwdata  <= 0;
  apb_master_vif.pstrb   <= 0;
  apb_master_vif.pprot   <= 0;

  // wait for reset release (once)
 
  if (apb_master_vif.preset !== 1'b1)begin
     @(posedge apb_master_vif.clk);
      apb_master_vif.psel    <= 0;
      apb_master_vif.penable <= 0;
      apb_master_vif.pwrite  <= 0;
      apb_master_vif.paddr   <= 0;
      apb_master_vif.pwdata  <= 0;
      apb_master_vif.pstrb   <= 0;
      apb_master_vif.pprot   <= 0;
   end
@(posedge apb_master_vif.pclk);
  forever begin
    seq_item_port.try_next_item(seq);

    if (seq == null) begin 
      apb_master_vif.psel    <= 0;
      apb_master_vif.penable <= 0;
      apb_master_vif.pwrite  <= 0;
      apb_master_vif.paddr   <= 0;
      apb_master_vif.pwdata  <= 0;
      apb_master_vif.pstrb   <= 0;
      apb_master_vif.pprot   <= 0;
        @(posedge apb_master_vif.pclk);
      // without this the loop spins at time 0
   
    end
    else begin
      `uvm_info("APB_mst_DRV", $sformatf("GOT ITEM: pwrite=%0b paddr=%0h pwdata=%0h pstrb=%04b pprot=%0b", seq.pwrite, seq.paddr, seq.pwdata, seq.pstrb, seq.pprot), UVM_LOW)
      drive(seq);
      seq_item_port.item_done();
      `uvm_info("APB_mst_DRV", "item_done sent", UVM_LOW)
    end
  end
endtask

task drive(apb_seq_item seq);
  ///// SETUP (we are already just after a clock edge)
 // @(posedge apb_master_vif.pclk);
  apb_master_vif.psel    <= 1;
  apb_master_vif.penable <= 0;
  apb_master_vif.paddr   <= seq.paddr;
  apb_master_vif.pwrite  <= seq.pwrite;
  apb_master_vif.pprot   <= seq.pprot;

  if (seq.pwrite == 1'b1) begin
    apb_master_vif.pwdata <= seq.pwdata;
    apb_master_vif.pstrb  <= seq.pstrb;
  end
  else begin
    apb_master_vif.pstrb  <= 4'b0000;
  end

  ///// ACCESS
  @(posedge apb_master_vif.pclk);
  apb_master_vif.penable <= 1;

  // wait states: sample each edge until pready is exactly 1
  do begin
    @(posedge apb_master_vif.pclk);
  end
  while (apb_master_vif.pready == 1'b0);

  ///// response
  seq.prdata  = apb_master_vif.prdata;
  seq.pslverr = apb_master_vif.pslverr;
  if (seq.pslverr)
    `uvm_warning(get_name(), $sformatf("PSLVERR asserted for addr 0x%0h", seq.paddr))
  // no idle here: the next loop iteration drives SETUP (next item) or IDLE (no item)
endtask

endclass
