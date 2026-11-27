class apb_master_monitor extends uvm_monitor;
  `uvm_component_utils(apb_master_monitor)
  
  uvm_analysis_port#(apb_seq_item) analysis_port_tx; // analyis port for tx
  
  
  virtual apb_interface  apb_master_vif;
  
  apb_seq_item mon_item;
  
  
  function new(string name = "apb_master_driver", uvm_component parent);
    super.new(name, parent);
    analysis_port_tx = new("analysis_port_tx",this);
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
    drive();
 
  endtask
  ///////
 task drive();  
  forever begin
    @(negedge apb_master_vif.pclk);
   //`uvm_info(get_name, $sformatf(" MASTER MONITOR rx SATRT psel=%0b penable=%0b pwrite=%0b paddr=0x%0h pwdata=0x%0h pstrb=%04b | pready=%0b prdata=0x%0h pslverr=%0b",apb_master_rx.psel, apb_master_rx.penable, apb_master_rx.pwrite, apb_master_rx.paddr, apb_master_rx.pwdata, apb_master_rx.pstrb, apb_master_rx.pready, apb_master_rx.prdata, apb_master_rx.pslverr), UVM_MEDIUM)

    // 2) phase detection prints
    if (apb_master_vif.psel && !apb_master_vif.penable) begin
    // `uvm_info(get_name, $sformatf("SETUP  seen @%0t paddr=0x%0h", $time, apb_master_tx.paddr), UVM_MEDIUM)
   //// 
    end
    if (apb_master_vif.psel && apb_master_vif.penable && !apb_master_vif.pready) begin
      //`uvm_info(get_name, $sformatf("WAIT   seen @%0t (pready=0)", $time), UVM_MEDIUM)
    end
    // 3) collect only in access phase with pready=1
    if (apb_master_vif.psel && apb_master_vif.penable && apb_master_vif.pready) begin
      mon_item = apb_seq_item::type_id::create("mon_item");   // new item every transfer

      mon_item.paddr   = apb_master_vif.paddr;
      mon_item.pwrite  = apb_master_vif.pwrite;
      mon_item.pslverr = apb_master_vif.pslverr;
      mon_item.pprot   = apb_master_vif.pprot;


      if (apb_master_vif.pwrite) begin
       mon_item.pwdata = apb_master_vif.pwdata;
       mon_item.pstrb  = apb_master_vif.pstrb;
      end
      else begin
        mon_item.prdata = apb_master_vif.prdata;
      end

     `uvm_info(get_name, $sformatf( " MASTER COLLECTED  siganl : pwrite=%0b paddr=0x%0h pwdata=0x%0h pstrb=%04b prdata=0x%0h pslverr=%0b, pprot = %0d", mon_item.pwrite, mon_item.paddr, mon_item.pwdata, mon_item.pstrb, mon_item.prdata, mon_item.pslverr, mon_item.pprot), UVM_LOW)

     analysis_port_tx.write(mon_item); //  analysis port rx signal 
    end
  end //
  endtask
  
endclass

