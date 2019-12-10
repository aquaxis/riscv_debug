module debug_top(
    input  TRST_N,
    input  TCK,
    input  TMS,
    input  TDI,
    output TDO,

    input  CLK100MHZ,

    output [3:0] LED
);

  wire tdo_o, tdo_oe;

  assign TDO = (tdo_oe)?tdo_o:1'bz;

  wire        dmi_en;
  wire        dmi_wr, dmi_rd;
  wire [6:0]  dmi_ad;
  wire [31:0] dmi_di, dmi_do;

  wire        ar_en;
  wire        ar_wr;
  wire [15:0] ar_ad;
  wire [31:0] ar_di, ar_do;

  wire        am_en;
  wire        am_wr;
  wire [3:0]  am_st;
  wire [31:0] am_ad;
  wire [31:0] am_di, am_do;

  wire        sys_en, sys_wr;
  wire [31:0] sys_ad, sys_di, sys_do;

  wire        core_reset;
  wire        core_haltreq, core_resumereq;
  reg         core_halt, core_resume;

  wire        ndmreset;

  debug_dtm u_debug_dtm(
    // JTAG pads
    .TMS      ( TMS    ),
    .TCK      ( TCK    ),
    .TRSTN    ( TRST_N ),
    .TDI      ( TDI    ),
    .TDO      ( tdo_o  ),
    .TDO_OE   ( tdo_oe ),

    .TDI_O    ( tdi_o  ),

    .DMI_EN   ( dmi_en ),
    .DMI_WR   ( dmi_wr ),
    .DMI_RD   ( dmi_rd ),
    .DMI_AD   ( dmi_ad ),
    .DMI_DI   ( dmi_di ),
    .DMI_DO   ( dmi_do )
  );

  debug_dm u_debug_dm(
    .RST_N    ( TRST_N ),
    .CLK      ( TCK    ),

    // DMI
    .DMI_CS   ( dmi_en ),
    .DMI_WR   ( dmi_wr ),
    .DMI_RD   ( dmi_rd ),
    .DMI_AD   ( dmi_ad ),
    .DMI_DI   ( dmi_do ),
    .DMI_DO   ( dmi_di ),

    // Debug Module Status
    .I_IMPEBREAK        (),
    .I_HAVERESET        ( core_reset     ),
    .I_RESUMEACK        ( core_resume    ),
    .I_NONEXISTENT      (),
    .I_UNAVAIL          (),
    .I_RUNNING          (),
    .I_HALTED           ( core_halt      ),
    .I_AUTHENTICATED    (),
    .I_AUTHBUSY         (),
    .I_HASRESETHALTREQ  (),
    .I_CONFSTRPTRVALID  (),

    .O_HALTREQ          ( core_haltreq   ),
    .O_RESUMEREQ        ( core_resumereq ),
    .O_HARTRESET        ( core_reset     ),
    .O_ACKHAVERESET     (),
    .O_SETRESETHALTREQ  (),
    .O_CLRRESETHALTREQ  (),
    .O_NDMRESET         ( ndmreset       ),

    .AR_EN  ( ar_en),
    .AR_WR  ( ar_wr),
    .AR_AD  ( ar_ad),
    .AR_DI  ( ar_di),
    .AR_DO  ( ar_do),

    .AM_EN  ( am_en),
    .AM_WR  ( am_wr),
    .AM_ST  ( am_st),
    .AM_AD  ( am_ad),
    .AM_DI  ( am_di),
    .AM_DO  ( am_do),

    .SYS_EN ( sys_en),
    .SYS_WR ( sys_wr),
    .SYS_AD ( sys_ad),
    .SYS_DI ( sys_di),
    .SYS_DO ( sys_do),

    .DEBUG  ()
  );

reg [31:0] data;
always @(*) begin
    case(ar_ad)
    16'h0301: data <= 32'h4000_1105;    // 
    default:  data <= 32'd0;
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
        end else if(core_resumereq & core_halt) begin
            core_halt <= 1'b0;
            core_resume <= 1'b1;
        end else if(!core_resumereq & core_resume) begin
            core_halt <= 1'b0;
            core_resume <= 1'b0;
        end
    end
end

assign LED[0] = core_resume;
assign LED[1] = core_halt;
assign LED[2] = 1'b0;
assign LED[3] = 1'b0;

endmodule
