module debug_dm(
  input         RST_N,
  input         CLK,

  // DMI
  input         DMI_CS,
  input         DMI_WR,
  input         DMI_RD,
  input [6:0]   DMI_AD,
  input [31:0]  DMI_DI,
  output [31:0] DMI_DO,

  // Debug Module Status
  input         I_IMPEBREAK,
  input         I_HAVERESET,
  input         I_RESUMEACK,
  input         I_NONEXISTENT,
  input         I_UNAVAIL,
  input         I_RUNNING,
  input         I_HALTED,
  input         I_AUTHENTICATED,
  input         I_AUTHBUSY,
  input         I_HASRESETHALTREQ,
  input         I_CONFSTRPTRVALID,

  output        O_HALTREQ,
  output        O_RESUMEREQ,
  output        O_HARTRESET,
  output        O_ACKHAVERESET,
  output        O_SETRESETHALTREQ,
  output        O_CLRRESETHALTREQ,
  output        O_NDMRESET,

  output        AR_EN,
  output        AR_WR,
  output [15:0] AR_AD,
  input [31:0]  AR_DI,
  output [31:0] AR_DO,

  output        AM_EN,
  output        AM_WR,
  output [3:0]  AM_ST,
  output [31:0] AM_AD,
  input [31:0]  AM_DI,
  output [31:0] AM_DO,

  output        SYS_EN,
  output        SYS_WR,
  output [31:0] SYS_AD,
  input [31:0]  SYS_DI,
  output [31:0] SYS_DO,

  output [31:0] DEBUG
);

reg [31:0] data0, data1, data2, data3, data4, data5, data6, data7, data8, data9 ,data10, data11;
reg [31:0] data0_r, data1_r, data2_r, data3_r, data4_r, data5_r, data6_r, data7_r, data8_r, data9_r ,data10_r, data11_r;

// Debug Module Status
wire        impebreak;        // R
wire        allhavereset;     // R
wire        anyhavereset;     // R
wire        allresumeack;     // R
wire        anyresumeack;     // R
wire        allnonexistent;   // R
wire        anynonexistent;   // R
wire        allunavail;       // R
wire        anyunavail;       // R
wire        allrunning;       // R
wire        anyrunning;       // R
wire        allhalted;        // R
wire        anyhalted;        // R
wire        authencicated;    // R
wire        authbusy;         // R
wire        hasresethalreq;   // R
wire        confstrptrvalid;  // R
wire [3:0]  version;          // R

assign version[3:0] = 4'd2;
assign authencicated = 1'b1;

// Debug Module Control
reg         haltreq;          // W
reg         resumereq;        // W
reg         hartreset;        // R/W
reg         ackhavereset;     // W
reg         hasel;            // R/W
reg [9:0]   hasello;          // R/W
reg [9:0]   haselhi;          // R/W
reg         setresethaltreq;  // W
reg         clrresethaltreq;  // W
reg         ndmreset;         // R/W
reg         dmactive;         // R/W

// Halt Status
wire [3:0]  nscratch;         // R
wire        dataaccess;       // R
wire [3:0]  datasize;         // R
wire [11:0] dataaddr;         // R

assign nscratch = 4'd0;
assign dataaccess = 1'b0;
assign datasize = 4'd1;
assign dataaddr = 12'd0;

// Hart Window
reg [14:0]  hawindowsel;      // R/W
reg [31:0]  maskdata;

// Abstract Control & Status
wire [6:0]  progbufsize;      // R
wire        busy;             // R
reg [2:0]   cmderr;           // R/W
wire [3:0]  datacount;        // R

assign datacount = 4'd1;

// Abstract Command
wire [7:0]   cmdtype;          // W
reg [7:0]    old_cmdtype;
wire [23:0]  control;          // W
reg [15:0]   autoexecprogbuf;  // R/W
reg [11:0]   autiexecdata;     // R/W

reg [31:0]   confstrptr0, confstrptr1, confstrptr2, confstrptr3;
reg [31:0]   nextdm;

reg [31:0]   progbuf0, progbuf1, progbuf2, progbuf3, progbuf4, progbuf5, progbuf6, progbuf7;
reg [31:0]   progbuf8, progbuf9, progbuf10, progbuf11, progbuf12, progbuf13, progbuf14, progbuf15;

reg [31:0]   authdata;

reg [31:0]   haltsum0, haltsum1, haltsum2, haltsum3;

wire [2:0]   sbversion;        // R
wire         sbbusyerror;      // R/W
wire         sbbusy;           // R
reg          sbreadonaddr;     // R/W
reg [2:0]    sbaccess;         // R/W
reg          sbautoincrement;  // R/W
reg          sbreadondata;     // R/W
wire [2:0]   sberror;          // R/W
wire [6:0]   sbsize;           // R
wire         sbaccess128, sbaccess64, sbaccess32, sbaccess16, sbaccess8; // R

assign sbversion = 3'd1;
//assign sbaccess = 3'd2;
assign sbaccess32 = 1'b1;

reg [31:0]  sbaddress0, sbaddress1, sbaddress2, sbaddress3; // R/W
reg [31:0]  sbdata0, sbdata1, sbdata2, sbdata3;             // R/W
reg [31:0]  sbdata0_r, sbdata1_r, sbdata2_r, sbdata3_r;     // R/W

localparam A_DATA0        = 7'h04;
localparam A_DATA1        = 7'h05;
localparam A_DATA2        = 7'h06;
localparam A_DATA3        = 7'h07;
localparam A_DATA4        = 7'h08;
localparam A_DATA5        = 7'h09;
localparam A_DATA6        = 7'h0A;
localparam A_DATA7        = 7'h0B;
localparam A_DATA8        = 7'h0C;
localparam A_DATA9        = 7'h0D;
localparam A_DATA10       = 7'h0E;
localparam A_DATA11       = 7'h0F;
localparam A_DMCONTROL    = 7'h10;
localparam A_DMSTATUS     = 7'h11;
localparam A_HALTSUM1     = 7'h12;
localparam A_HARTINFO     = 7'h13;
localparam A_HAWINDOWSEL  = 7'h14;
localparam A_HAWINDOW     = 7'h15;
localparam A_ABSTRACTCS   = 7'h16;
localparam A_COMMAND      = 7'h17;
localparam A_ABSTRACTAUTO = 7'h18;
localparam A_CONFSTRPTR0  = 7'h19;
localparam A_CONFSTRPTR1  = 7'h1A;
localparam A_CONFSTRPTR2  = 7'h1B;
localparam A_CONFSTRPTR3  = 7'h1C;
localparam A_NEXTDM       = 7'h1D;
localparam A_PROGBUF0     = 7'h20;
localparam A_PROGBUF1     = 7'h21;
localparam A_PROGBUF2     = 7'h22;
localparam A_PROGBUF3     = 7'h23;
localparam A_PROGBUF4     = 7'h24;
localparam A_PROGBUF5     = 7'h25;
localparam A_PROGBUF6     = 7'h26;
localparam A_PROGBUF7     = 7'h27;
localparam A_PROGBUF8     = 7'h28;
localparam A_PROGBUF9     = 7'h29;
localparam A_PROGBUF10    = 7'h2A;
localparam A_PROGBUF11    = 7'h2B;
localparam A_PROGBUF12    = 7'h2C;
localparam A_PROGBUF13    = 7'h2D;
localparam A_PROGBUF14    = 7'h2E;
localparam A_PROGBUF15    = 7'h2F;
localparam A_AUTODATA     = 7'h30;
localparam A_HALTSUM2     = 7'h34;
localparam A_HALTSUM3     = 7'h35;
localparam A_SBADDRESS3   = 7'h37;
localparam A_SBCS         = 7'h38;
localparam A_SBADDRESS0   = 7'h39;
localparam A_SBADDRESS1   = 7'h3A;
localparam A_SBADDRESS2   = 7'h3B;
localparam A_SBDATA0      = 7'h3C;
localparam A_SBDATA1      = 7'h3D;
localparam A_SBDATA2      = 7'h3E;
localparam A_SBDATA3      = 7'h3F;
localparam A_HALTSUM0     = 7'h40;

wire [31:0] dmcontrol, dmstatus;
wire [31:0] hartinfo;
wire [31:0] hawindow;
wire [31:0] abstractcs, command, abstractauto;
wire [31:0] sbcs;

//assign hasresethalreq = haltreq;
assign allhalted = I_HALTED;
assign anyhalted = I_HALTED;

assign allresumeack = I_RESUMEACK;
assign anyresumeack = I_RESUMEACK;

assign allrunning = I_RUNNING;
assign anyrunning = I_RUNNING;

assign dmstatus     = {
                    8'd0,
                    1'b0, impebreak, 2'd0, allhavereset, anyhavereset, allresumeack, anyresumeack,
                    allnonexistent, anynonexistent, allunavail, anyunavail,
                    allrunning, anyrunning, allhalted, anyhalted,
                    authencicated, authbusy, hasresethalreq, confstrptrvalid,
                    version
                    };
assign dmcontrol    = {
                    haltreq, resumereq, hartreset, ackhavereset, 1'd0, hasel, hasello,
                    haselhi, 2'd0, setresethaltreq, clrresethaltreq, ndmreset, dmactive
                    };
assign hartinfo     = {
                    8'd0, nscratch, 3'd0, dataaccess, datasize, dataaddr
                    };
//assign hawindowsel  = {17'd0, hawindowsel};
assign hawindow     = {maskdata};
assign abstractcs   = {3'd0, progbufsize, 11'd0, busy, 1'd0, cmderr,4'd0, datacount};
assign command      = {cmdtype, control};
assign abstractauto = {autoexecprogbuf, 4'd0, autiexecdata};
assign sbcs         = {
                    sbversion, 6'd0,
                    sbbusyerror, sbbusy, sbreadonaddr, sbaccess, sbautoincrement,
                    sbreadondata, sberror, sbsize,
                    sbaccess128, sbaccess64, sbaccess32, sbaccess16, sbaccess8
                    };

wire [127:0] sbaddress;
wire [127:0] sbdata;

assign sbaddress[127:0] = {sbaddress3[31:0], sbaddress2[31:0], sbaddress1[31:0], sbaddress0[31:0]};
assign sbdata[127:0]    = {sbdata3[31:0], sbdata2[31:0], sbdata1[31:0], sbdata0[31:0]};

reg [31:0] rdata;

assign cmdtype = DMI_DI[31:24];
assign control = DMI_DI[23:0];

always @(posedge CLK or negedge RST_N) begin
  if(!RST_N) begin
    sbreadonaddr <= 0;
    sbaccess <= 2;
    sbautoincrement <= 0;
    sbreadondata <= 0;
    old_cmdtype <= 0;
    haltreq <= 0;
    resumereq <= 0;
    ackhavereset <= 0;
    setresethaltreq <=0;
    clrresethaltreq <= 0;
    ndmreset <= 0;
    dmactive <= 0;
    hartreset <= 0;
  end else begin
    if(DMI_CS & DMI_WR) begin
      case(DMI_AD)
        A_DATA0:  data0  <= DMI_DI;
        A_DATA1:  data1  <= DMI_DI;
        A_DATA2:  data2  <= DMI_DI;
        A_DATA3:  data3  <= DMI_DI;
        A_DATA4:  data4  <= DMI_DI;
        A_DATA5:  data5  <= DMI_DI;
        A_DATA6:  data6  <= DMI_DI;
        A_DATA7:  data7  <= DMI_DI;
        A_DATA8:  data8  <= DMI_DI;
        A_DATA9:  data9  <= DMI_DI;
        A_DATA1:  data10 <= DMI_DI;
        A_DATA11: data11 <= DMI_DI;
        A_DMCONTROL: begin
          haltreq         <= DMI_DI[31];
          resumereq       <= DMI_DI[30];
          hartreset       <= DMI_DI[29];
          ackhavereset    <= DMI_DI[28];
//          hasel           <= DMI_DI[26];
//          hasello         <= DMI_DI[25:16];
//          haselhi         <= DMI_DI[15:6];
          setresethaltreq <= DMI_DI[3];
          clrresethaltreq <= DMI_DI[2];
          ndmreset        <= DMI_DI[1];
          dmactive        <= DMI_DI[0];
        end
        A_DMSTATUS: begin
        end
        A_HALTSUM1: haltsum1  <= DMI_DI;
        A_HARTINFO: begin
        end
        A_HAWINDOWSEL: begin
          hawindowsel         <= DMI_DI[14:0];
        end
        A_HAWINDOW: maskdata  <= DMI_DI;
        A_ABSTRACTCS: begin
        cmderr                <= (~DMI_DI[10:8]) & cmderr;
        end
        A_COMMAND: begin
          old_cmdtype         <= DMI_DI[31:24];
          cmderr <= ((cmdtype[7:0]==8'd0)&&(control[22:20]!=3'd2))?2:0;
          if(control[19]) begin
            if(control[22:20] == 1) begin
              data1 <= data1 + 2;
            end else begin
              data1 <= data1 + 4;
            end
          end
        end
        A_ABSTRACTAUTO: begin
          autoexecprogbuf     <= DMI_DI[31:16];
          autiexecdata        <= DMI_DI[11:0];
        end
        A_CONFSTRPTR0: confstrptr0  <= DMI_DI;
        A_CONFSTRPTR1: confstrptr1  <= DMI_DI;
        A_CONFSTRPTR2: confstrptr2  <= DMI_DI;
        A_CONFSTRPTR3: confstrptr3  <= DMI_DI;
        A_NEXTDM: nextdm            <= DMI_DI;
        A_PROGBUF0: progbuf0        <= DMI_DI;
        A_PROGBUF1: progbuf1        <= DMI_DI;
        A_AUTODATA: authdata        <= DMI_DI;
        A_HALTSUM2: haltsum2        <= DMI_DI;
        A_HALTSUM3: haltsum3        <= DMI_DI;
        A_SBADDRESS3: sbaddress3    <= DMI_DI;
        A_SBCS: begin
          sbreadonaddr    <= DMI_DI[20];
          sbaccess        <= DMI_DI[19:17];
          sbautoincrement <= DMI_DI[16];
          sbreadondata    <= DMI_DI[15];
        end
        A_SBADDRESS0: sbaddress0    <= DMI_DI;
        A_SBADDRESS1: sbaddress1    <= DMI_DI;
        A_SBADDRESS2: sbaddress2    <= DMI_DI;
        A_SBDATA0: begin
          sbdata0          <= DMI_DI;
          if(sbautoincrement) begin
            sbaddress0 <= sbaddress0 + 4;
          end
        end
        A_SBDATA1: sbdata1          <= DMI_DI;
        A_SBDATA2: sbdata2          <= DMI_DI;
        A_SBDATA3: sbdata3          <= DMI_DI;
        A_HALTSUM0: haltsum0        <= DMI_DI;
      endcase
    end else begin
      if((DMI_AD == A_COMMAND) && (DMI_WR | DMI_RD)) begin
          if(control[19]) begin
            if(control[22:20] == 1) begin
              data1 <= data1 + 2;
            end else begin
              data1 <= data1 + 4;
            end
          end
      end
      if((DMI_AD == A_SBDATA0) && (DMI_WR | DMI_RD)) begin
          if(sbautoincrement) begin
            sbaddress0 <= sbaddress0 + 4;
          end
      end

    end
  end
end

always @(posedge CLK or negedge RST_N) begin
  if(!RST_N) begin
    rdata <= 32'd0;
  end else begin
    case(DMI_AD)
      A_DATA0:        rdata <= data0_r;
      A_DATA1:        rdata <= data1_r;
      A_DATA2:        rdata <= data2_r;
      A_DATA3:        rdata <= data3_r;
      A_DATA4:        rdata <= data4_r;
      A_DATA5:        rdata <= data5_r;
      A_DATA6:        rdata <= data6_r;
      A_DATA7:        rdata <= data7_r;
      A_DATA8:        rdata <= data8_r;
      A_DATA9:        rdata <= data9_r;
      A_DATA10:       rdata <= data10_r;
      A_DATA11:       rdata <= data11_r;
      A_DMCONTROL:    rdata <= dmcontrol;
      A_DMSTATUS:     rdata <= dmstatus;
      A_HALTSUM1:     rdata <= haltsum1;
      A_HARTINFO:     rdata <= hartinfo;
      A_HAWINDOWSEL:  rdata <= hawindowsel;
      A_HAWINDOW:     rdata <= {17'd0, hawindow};
      A_ABSTRACTCS:   rdata <= abstractcs;
      A_COMMAND:      rdata <= command;
      A_ABSTRACTAUTO: rdata <= abstractauto;
      A_CONFSTRPTR0:  rdata <= confstrptr0;
      A_CONFSTRPTR1:  rdata <= confstrptr1;
      A_CONFSTRPTR2:  rdata <= confstrptr2;
      A_CONFSTRPTR3:  rdata <= confstrptr3;
      A_NEXTDM:       rdata <= nextdm;
      A_PROGBUF0:     rdata <= progbuf0;
      A_PROGBUF1:     rdata <= progbuf1;
      A_AUTODATA:     rdata <= authdata;
      A_HALTSUM2:     rdata <= haltsum2;
      A_HALTSUM3:     rdata <= haltsum3;
      A_SBADDRESS3:   rdata <= sbaddress3;
      A_SBCS:         rdata <= sbcs;
      A_SBADDRESS0:   rdata <= sbaddress0;
      A_SBADDRESS1:   rdata <= sbaddress1;
      A_SBADDRESS2:   rdata <= sbaddress2;
      A_SBDATA0:      rdata <= sbdata0_r;
      A_SBDATA1:      rdata <= sbdata1_r;
      A_SBDATA2:      rdata <= sbdata2_r;
      A_SBDATA3:      rdata <= sbdata3_r;
      A_HALTSUM0:     rdata <= haltsum0;
      default:        rdata <= 32'd0;
    endcase
    if((DMI_AD == A_COMMAND) && (DMI_WR | DMI_RD)) begin
      if((cmdtype == 8'd0) || ((cmdtype == 8'd1) && (old_cmdtype == 8'd0))) begin
        data0_r <= AR_DI;
      end else if((cmdtype == 8'd2) || ((cmdtype == 8'd1) && (old_cmdtype == 8'd2))) begin
        if(control[19] && (data1[1:0] == 2)) begin
          data0_r <= {16'd0, AM_DI[31:16]};
        end else begin
          data0_r <= AM_DI;
        end
      end
    end
    if((DMI_AD == A_SBDATA0) && (DMI_WR | DMI_RD)) begin
        sbdata0_r <= SYS_DI;
    end
  end
end

//assign DMI_DO = (DMI_RD)?rdata:32'd0;
assign DMI_DO = rdata;

assign AR_EN = ((DMI_AD == A_COMMAND) && (DMI_WR | DMI_RD) && (cmdtype == 8'd0))?1'b1:1'b0;
assign AR_WR = (cmdtype == 8'd0)?control[16]:1'b0;
assign AR_AD = (cmdtype == 8'd0)?control[15:0]:16'd0;
assign AR_DO = data0;

assign AM_EN = ((DMI_AD == A_COMMAND) && (DMI_WR | DMI_RD) && (cmdtype == 8'd2))?1'b1:1'b0;
assign AM_ST = (cmdtype == 8'd2)?(control[22:20]==2)?4'b1111:4'b0011<<data1[1:0]:4'd0;
assign AM_WR = (cmdtype == 8'd2)?control[16]:1'b0;
assign AM_AD = data1;
assign AM_DO = (cmdtype == 8'd2)?(control[22:20]==2)?data0:((data1[1:0]==2)?{data0[15:0],16'd0}:data0):32'd0;
/*
assign data0_r = ((cmdtype == 8'd0)?AR_DI:32'd0) |
                 ((cmdtype == 8'd1)?((old_cmdtype == 8'd0)?AR_DI:AM_DI):32'd0) |
                 ((cmdtype == 8'd2)?AM_DI:32'd0) |
                  32'd0;
*/
assign SYS_EN = ((DMI_AD == A_SBDATA0) && (DMI_WR | DMI_RD))?1'b1:1'b0;
assign SYS_WR = DMI_WR;
assign SYS_AD = sbaddress0;
assign SYS_DO = DMI_DI;
//assign sbdata0_r = SYS_DI;

assign O_HALTREQ   = haltreq;
assign O_RESUMEREQ = resumereq;
assign O_HARTRESET = hartreset;
assign O_NDMRESET  = ndmreset;

endmodule
