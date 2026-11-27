class apb_master_agent extends uvm_agent;
  `uvm_component_utils(apb_master_agent)
  apb_master_driver mst_driver;
  apb_master_sequencer mst_seqr;
  apb_master_monitor mst_monitor;

  function new(string name = "apb_master_agent", uvm_component parent);
	  super.new(name, parent);
  endfunction
  
    function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(uvm_active_passive_enum)::get(this, "", "is_active", is_active))
      `uvm_info(get_name(), "is_active not found, using default UVM_ACTIVE", UVM_LOW)

      if (get_is_active() == UVM_ACTIVE) begin
      `uvm_info(get_name(), "This is Active agent", UVM_LOW)
      mst_seqr   = apb_master_sequencer::type_id::create("mst_seqr", this);
      mst_driver = apb_master_driver::type_id::create("mst_driver", this);
    end
    else begin
      `uvm_info(get_name(), "This is Passive agent", UVM_LOW)
    end
    mst_monitor = apb_master_monitor::type_id::create("mst_monitor", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (get_is_active() == UVM_ACTIVE) begin
        mst_driver.seq_item_port.connect(mst_seqr.seq_item_export);
        `uvm_info(get_full_name(), "Master driver and sequencer connected", UVM_LOW)
    end
  endfunction  
endclass
  
  
