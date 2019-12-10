module debug_top(
    input TRST_N,
    input TCK,
    input TMS,
    input TDI,
    output TDO,

    output test_logic_reset_o,
    output run_test_idle_o,
    output shift_dr_o,
    output pause_dr_o,
    output update_dr_o,
    output capture_dr_o,

    output extest_select_o,
    output sample_preload_select_o,
    output mbist_select_o,
    output debug_select_o,
    output dtmcs_select_o,
    output dmi_select_o,

    output dmi_wr,
    output dmi_rd,

    output tdi_o,

    input debug_tdo_i,
    input bs_chain_tdo_i,
    input mbist_tdo_i,

    input CLK100MHZ,

    output [3:0] LED
);

wire tdo_o, tdo_oe;

assign TDO = (tdo_oe)?tdo_o:1'bz;

wire [3:0] dmuuy;

wire dmi_select_o;
wire dmi_wr, dmi_rd;
wire [6:0] dmi_ad;
wire [31:0] dmi_di, dmi_do;

wire ar_en;
wire ar_wr;
wire [15:0] ar_ad;
wire [31:0] ar_di, ar_do;

wire core_haltreq, core_resumereq;
reg core_halt, core_resume;

debug_dtm u_debug_dtm(
    // JTAG pads
    .tms_pad_i      (TMS),
    .tck_pad_i      (TCK),
    .trstn_pad_i    (TRST_N),
    .tdi_pad_i      (TDI),
    .tdo_pad_o      (tdo_o),
    .tdo_padoe_o    (tdo_oe),

    // TAP states
    .test_logic_reset_o (test_logic_reset_o),
    .run_test_idle_o    (run_test_idle_o),
    .shift_dr_o         (shift_dr_o),
    .pause_dr_o         (pause_dr_o),
    .update_dr_o        (update_dr_o),
    .capture_dr_o       (capture_dr_o),

    // Select signals for boundary scan or mbist
    .extest_select_o        (extest_select_o),
    .sample_preload_select_o(sample_preload_select_o),
    .mbist_select_o         (mbist_select_o),
    .debug_select_o         (debug_select_o),
    .dtmcs_select_o         (dtmcs_select_o),
    .dmi_select_o           (dmi_select_o),

    // TDO signal that is connected to TDI of sub-modules.
    .tdi_o                  (tdi_o),

    .dmi_wr                 (dmi_wr),
    .dmi_rd                 (dmi_rd),
    .dmi_ad                 (dmi_ad),
    .dmi_di                 (dmi_di),
    .dmi_do                 (dmi_do),

    // TDI signals from sub-modules
    .debug_tdo_i    (debug_tdo_i),    // from debug module
    .bs_chain_tdo_i (bs_chain_tdo_i), // from Boundary Scan Chain
    .mbist_tdo_i    (mbist_tdo_i)     // from Mbist Chain
);

debug_dm u_debug_dm(
  .RST_N(TRST_N),
  .CLK(TCK),

  // DMI
  .DMI_CS(dmi_select_o),
  .DMI_WR(dmi_wr),
  .DMI_RD(dmi_rd),
  .DMI_AD(dmi_ad),
  .DMI_DI(dmi_do),
  .DMI_DO(dmi_di),

  // Debug Module Status
  .I_IMPEBREAK(),
  .I_HAVERESET(),
  .I_RESUMEACK(core_resume),
  .I_NONEXISTENT(),
  .I_UNAVAIL(),
  .I_RUNNING(),
  .I_HALTED(core_halt),
  .I_AUTHENTICATED(),
  .I_AUTHBUSY(),
  .I_HASRESETHALTREQ(),
  .I_CONFSTRPTRVALID(),

  .O_HALTREQ(core_haltreq),
  .O_RESUMEREQ(core_resumereq),
  .O_HARTRESE(),
  .O_ACKHAVERESE(),
  .O_SERESEHALTREQ(),
  .O_CLRRESETHALTREQ(),
  .O_NDMRESE(),

  .AR_EN(ar_en),
  .AR_WR(ar_wr),
  .AR_AD(ar_ad),
  .AR_DI(ar_di),
  .AR_DO(ar_do),

  .DEBUG()
);

assign LED[0] = 4'd0;

ila_0 u_ila_0(
    .clk(CLK100MHZ),
    .probe0(dmi_select_o),
    .probe1(dmi_wr),
    .probe2(dmi_rd),
    .probe3(dmi_ad),
    .probe4(dmi_di),
    .probe5(dmi_do),
    .probe6(TCK)
);

reg [31:0] data;
always @(*) begin
    case(ar_ad)
    16'h0301: data <= 32'h4000_1105;
    default: data <= 32'd0;
    endcase
end

assign ar_di = data;

always @(posedge CLK100MHZ or negedge TRST_N) begin
    if(!TRST_N) begin
        core_halt <= 1'b0;
        core_resume <= 1'b0;
    end else begin
        if(core_haltreq) begin
            core_halt <= 1'b1;
            core_resume <= 1'b0;
        end else if(core_resumereq) begin
            core_halt <= 1'b0;
            core_resume <= 1'b1;
        end else if(!core_resumereq) begin
            core_halt <= 1'b0;
            core_resume <= 1'b0;
        end
    end
end

endmodule
