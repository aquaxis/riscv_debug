`define IDCODE_VALUE  32'h10e31913

`define DTMCS_ABITS   6'b000111
`define DTMCS_VERSION 4'b0001
`define DTMCS_VALUE   32'h00000101

`define  IR_LENGTH    5

// Instructions
`define EXTEST        5'b00000
`define IDCODE        5'b00001
`define BYPASS        5'b11111
`define DTMCS         5'b10000
`define DMI           5'b10001

module debug_dtm(
  input         TMS,
  input         TCK,
  input         TRSTN,
  input         TDI,
  output reg    TDO,
  output reg    TDO_OE,

  output        TDI_O,

  output        DMI_EN,
  output        DMI_WR,
  output        DMI_RD,
  output [7:0]  DMI_AD,
  input [31:0]  DMI_DI,
  output [31:0] DMI_DO
);

wire    test_logic_reset;
wire    run_test_idle;
wire    select_dr_scan;
wire    capture_dr;
wire    shift_dr;
wire    exit1_dr;
wire    pause_dr;
wire    exit2_dr;
wire    update_dr;
wire    select_ir_scan;
wire    capture_ir;
wire    shift_ir;
wire    exit1_ir;
wire    pause_ir;
wire    exit2_ir;
wire    update_ir;

wire    extest_select;
wire    idcode_select;
wire    bypass_select;
wire    dtmcs_select;
wire    dmi_select;

assign TDI_O = TDI;

assign DTMCS_ENA = dtmcs_select;
assign DMI_EN    = dmi_select;

`define S_TEST_LOGIC_RESET 4'hF
`define S_RUN_TEST_IDLE    4'hC
`define S_SELECT_DR_SCAN   4'h7
`define S_CAPTURE_DR       4'h6
`define S_SHIFT_DR         4'h2
`define S_EXIT1_DR         4'h1
`define S_PAUSE_DR         4'h3
`define S_EXIT2_DR         4'h0
`define S_UPDATE_DR        4'h5
`define S_SELECT_IR_SCAN   4'h4
`define S_CAPTURE_IR       4'hE
`define S_SHIFT_IR         4'hA
`define S_EXIT1_IR         4'h9
`define S_PAUSE_IR         4'hB
`define S_EXIT2_IR         4'h8
`define S_UPDATE_IR        4'hD

reg [3:0] state = `S_TEST_LOGIC_RESET;
reg [3:0] next_state;

always @(posedge TCK or negedge TRSTN)
begin
  if(TRSTN == 0)
    state = `S_TEST_LOGIC_RESET;
  else
    state = next_state;
end

always @(state or TMS)
begin
  case(state)
    `S_TEST_LOGIC_RESET:
      begin
      if(TMS) next_state = `S_TEST_LOGIC_RESET;
      else    next_state = `S_RUN_TEST_IDLE;
      end
    `S_RUN_TEST_IDLE:
      begin
      if(TMS) next_state = `S_SELECT_DR_SCAN;
      else    next_state = `S_RUN_TEST_IDLE;
      end
    `S_SELECT_DR_SCAN:
      begin
      if(TMS) next_state = `S_SELECT_IR_SCAN;
      else    next_state = `S_CAPTURE_DR;
      end
    `S_CAPTURE_DR:
      begin
      if(TMS) next_state = `S_EXIT1_DR;
      else    next_state = `S_SHIFT_DR;
      end
    `S_SHIFT_DR:
      begin
      if(TMS) next_state = `S_EXIT1_DR;
      else    next_state = `S_SHIFT_DR;
      end
    `S_EXIT1_DR:
      begin
      if(TMS) next_state = `S_UPDATE_DR;
      else    next_state = `S_PAUSE_DR;
      end
    `S_PAUSE_DR:
      begin
      if(TMS) next_state = `S_EXIT2_DR;
      else    next_state = `S_PAUSE_DR;
      end
    `S_EXIT2_DR:
      begin
      if(TMS) next_state = `S_UPDATE_DR;
      else    next_state = `S_SHIFT_DR;
      end
    `S_UPDATE_DR:
      begin
      if(TMS) next_state = `S_SELECT_DR_SCAN;
      else    next_state = `S_RUN_TEST_IDLE;
      end
    `S_SELECT_IR_SCAN:
      begin
      if(TMS) next_state = `S_TEST_LOGIC_RESET;
      else    next_state = `S_CAPTURE_IR;
      end
    `S_CAPTURE_IR:
      begin
      if(TMS) next_state = `S_EXIT1_IR;
      else    next_state = `S_SHIFT_IR;
      end
    `S_SHIFT_IR:
      begin
      if(TMS) next_state = `S_EXIT1_IR;
      else    next_state = `S_SHIFT_IR;
      end
    `S_EXIT1_IR:
      begin
      if(TMS) next_state = `S_UPDATE_IR;
      else    next_state = `S_PAUSE_IR;
      end
    `S_PAUSE_IR:
      begin
      if(TMS) next_state = `S_EXIT2_IR;
      else    next_state = `S_PAUSE_IR;
      end
    `S_EXIT2_IR:
      begin
      if(TMS) next_state = `S_UPDATE_IR;
      else    next_state = `S_SHIFT_IR;
      end
    `S_UPDATE_IR:
      begin
      if(TMS) next_state = `S_SELECT_DR_SCAN;
      else    next_state = `S_RUN_TEST_IDLE;
      end
    default:  next_state = `S_TEST_LOGIC_RESET;
  endcase
end

assign test_logic_reset = (state == `S_TEST_LOGIC_RESET)?1'b1:1'b0;;
assign run_test_idle    = (state == `S_RUN_TEST_IDLE   )?1'b1:1'b0;;
assign select_dr_scan   = (state == `S_SELECT_DR_SCAN  )?1'b1:1'b0;;
assign capture_dr       = (state == `S_CAPTURE_DR      )?1'b1:1'b0;;
assign shift_dr         = (state == `S_SHIFT_DR        )?1'b1:1'b0;;
assign exit1_dr         = (state == `S_EXIT1_DR        )?1'b1:1'b0;;
assign pause_dr         = (state == `S_PAUSE_DR        )?1'b1:1'b0;;
assign exit2_dr         = (state == `S_EXIT2_DR        )?1'b1:1'b0;;
assign update_dr        = (state == `S_UPDATE_DR       )?1'b1:1'b0;;
assign select_ir_scan   = (state == `S_SELECT_IR_SCAN  )?1'b1:1'b0;;
assign capture_ir       = (state == `S_CAPTURE_IR      )?1'b1:1'b0;;
assign shift_ir         = (state == `S_SHIFT_IR        )?1'b1:1'b0;;
assign exit1_ir         = (state == `S_EXIT1_IR        )?1'b1:1'b0;;
assign pause_ir         = (state == `S_PAUSE_IR        )?1'b1:1'b0;;
assign exit2_ir         = (state == `S_EXIT2_IR        )?1'b1:1'b0;;
assign update_ir        = (state == `S_UPDATE_IR       )?1'b1:1'b0;;

// JTAG_IR
reg [`IR_LENGTH-1:0]  jtag_ir;
reg [`IR_LENGTH-1:0]  latched_jtag_ir;
wire                  instruction_tdo;

always @(posedge TCK or negedge TRSTN)
begin
  if(TRSTN == 0)                 jtag_ir[`IR_LENGTH-1:0] <= #1 `IR_LENGTH'b0;
  else if(test_logic_reset == 1) jtag_ir[`IR_LENGTH-1:0] <= #1 `IR_LENGTH'b0;
  else if(capture_ir)            jtag_ir                 <= #1 5'b00101;
  else if(shift_ir)              jtag_ir[`IR_LENGTH-1:0] <= #1 {TDI, jtag_ir[`IR_LENGTH-1:1]};
end

assign instruction_tdo = jtag_ir[0];

always @(negedge TCK or negedge TRSTN)
begin
  if(TRSTN == 0)            latched_jtag_ir <= #1 `IDCODE;
  else if(test_logic_reset) latched_jtag_ir <= #1 `IDCODE;
  else if(update_ir)        latched_jtag_ir <= #1 jtag_ir;
end

// ICODE
reg [31:0] idcode_reg;
wire       idcode_tdo;

always @(posedge TCK or negedge TRSTN)
begin
  if(TRSTN == 0)                      idcode_reg <= #1 `IDCODE_VALUE;
  else if(test_logic_reset)           idcode_reg <= #1 `IDCODE_VALUE;
  else if(idcode_select & capture_dr) idcode_reg <= #1 `IDCODE_VALUE;
  else if(idcode_select & shift_dr)   idcode_reg <= #1 {TDI, idcode_reg[31:1]};
end

assign idcode_tdo = idcode_reg[0];

// DTMCS
reg [31:0] dtmcs_reg;
wire       dtmcs_tdo;

always @(posedge TCK or negedge TRSTN)
begin
  if(TRSTN == 0)                     dtmcs_reg <= #1 {22'd0, `DTMCS_ABITS, `DTMCS_VERSION};
  else if(test_logic_reset)          dtmcs_reg <= #1 {22'd0, `DTMCS_ABITS, `DTMCS_VERSION};
  else if(dtmcs_select & capture_dr) dtmcs_reg <= #1 {dtmcs_reg[31:10], `DTMCS_ABITS, `DTMCS_VERSION} ;
  else if(dtmcs_select & shift_dr)   dtmcs_reg <= #1 {TDI, dtmcs_reg[31:1]};
end

assign dtmcs_tdo = dtmcs_reg[0];

// DMI
reg [33+`DTMCS_ABITS:0] dmi_reg;
wire                    dmi_tdo;

always @(posedge TCK or negedge TRSTN)
begin
  if(TRSTN == 0)                   dmi_reg <= #1 0;
  else if(test_logic_reset)        dmi_reg <= #1 0;
  else if(dmi_select & capture_dr) dmi_reg <= #1 {dmi_reg[33+`DTMCS_ABITS:34], DMI_DI[31:0], 2'b00};
  else if(dmi_select & shift_dr)   dmi_reg <= #1 {TDI, dmi_reg[33+`DTMCS_ABITS:1]};
end

assign dmi_tdo = dmi_reg[0];

assign DMI_QC = update_dr & (dmi_reg[1:0] == 2'b00);
assign DMI_WR = update_dr & (dmi_reg[1:0] == 2'b10);
assign DMI_RD = update_dr & (dmi_reg[1:0] == 2'b01);
assign DMI_AD = dmi_reg[33+`DTMCS_ABITS:34];
assign DMI_DO = dmi_reg[33:2];

// BYPASS
wire  bypassed_tdo;
reg   bypass_reg;

always @(posedge TCK or negedge TRSTN)
begin
  if(TRSTN == 0)                      bypass_reg <= #1 1'b0;
  else if(test_logic_reset == 1)      bypass_reg <= #1 1'b0;
  else if(bypass_select & capture_dr) bypass_reg <= #1 1'b0;
  else if(bypass_select & shift_dr)   bypass_reg <= #1 TDI;
end

assign bypassed_tdo = bypass_reg;

assign extest_select = (latched_jtag_ir == `EXTEST)?1'b1:1'b0; // External test
assign idcode_select = (latched_jtag_ir == `IDCODE)?1'b1:1'b0; // ID Code
assign dtmcs_select  = (latched_jtag_ir == `DTMCS )?1'b1:1'b0; // DTM Control and Status
assign dmi_select    = (latched_jtag_ir == `DMI   )?1'b1:1'b0; // DMI
assign bypass_select = ((latched_jtag_ir == `BYPASS) || (latched_jtag_ir == 0))?1'b1:1'b0; // BYPASS

reg tdo_mux_out;

always @(shift_ir or instruction_tdo or latched_jtag_ir or idcode_tdo or bypassed_tdo)
begin
  if(shift_ir)
    tdo_mux_out = instruction_tdo;
  else
    begin
      case(latched_jtag_ir)
        `IDCODE:  tdo_mux_out = idcode_tdo;    // Reading ID code
        `DTMCS:   tdo_mux_out = dtmcs_tdo;     // DTM Control and Status
        `DMI:     tdo_mux_out = dmi_tdo;       // DMI
        default:  tdo_mux_out = bypassed_tdo;  // BYPASS instruction
      endcase
    end
end

always @(negedge TCK)
begin
  TDO    <= tdo_mux_out;
  TDO_OE <= #1 shift_ir | shift_dr;
end

endmodule
