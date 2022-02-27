import std/strformat

import ata
import debug
import pci
import uefitypes

type
  # Generic Host Control Registers

  HbaCap {.packed.} = object
    np    {.bitsize:  4.} : uint8   # Number of Ports
    sxs   {.bitsize:  1.} : uint8   # Supports External SATA
    ems   {.bitsize:  1.} : uint8   # Enclosure Management Supported
    cccs  {.bitsize:  1.} : uint8   # Command Completion Coalescing Supported
    ncs   {.bitsize:  1.} : uint8   # Number of Command Slots
    psc   {.bitsize:  1.} : uint8   # Partial State Capable
    ssc   {.bitsize:  1.} : uint8   # Slumber State Capable
    pmd   {.bitsize:  1.} : uint8   # PIO Multiple DRQ Block
    fbss  {.bitsize:  1.} : uint8   # FIS-based Switching Supported
    spm   {.bitsize:  1.} : uint8   # Supports Port Multiplier
    sam   {.bitsize:  1.} : uint8   # Supports AHCI Mode only
    rsv   {.bitsize:  1.} : uint8   # Reserved
    iss   {.bitsize:  4.} : uint8   # Interface Speed Support
    sclo  {.bitsize:  1.} : uint8   # Supports Command List Override
    sal   {.bitsize:  1.} : uint8   # Supports Activity LED
    salp  {.bitsize:  1.} : uint8   # Supports Agressive Link Power Management
    sss   {.bitsize:  1.} : uint8   # Supports Staggered Spin-up
    smps  {.bitsize:  1.} : uint8   # Supports Mechanical Presence Switch
    ssntf {.bitsize:  1.} : uint8   # Supports SNotification Register
    sncq  {.bitsize:  1.} : uint8   # Supports Native Command Queuing
    s64a  {.bitsize:  1.} : uint8   # Supports 64-bit Addressing

  GlobalHbaControl {.packed.} = object
    hr    {.bitsize:  1.} : uint32  # HBA Reset
    ie    {.bitsize:  1.} : uint32  # Interrupt Enable
    mrsm  {.bitsize:  1.} : uint32  # MSI Revert to Single Message
    rsv   {.bitsize: 28.} : uint32  # Reserved
    ae    {.bitsize:  1.} : uint32  # AHCI Enable

  # Port Registers (one set per port, up to 32 ports)

  PortCLB {.packed.} = object
    clb: uint32                     # Command List Base Address (1K aligned)

  PortCLBU {.packed.} = object
    clbu: uint32                    # Command List Base Address Upper 32-bits

  PortFB {.packed.} = object
    fb: uint32                      # FIS Base Address (256B aligned)

  PortFBU {.packed.} = object
    fbu: uint32                     # FIS Base Address Upper 32-bits

  PortIS {.packed.} = object      # Port Interrupt Status
    dhrs  {.bitsize:  1.} : uint32  # Device to Host Register FIS Interrupt
    pss   {.bitsize:  1.} : uint32  # PIO Setup FIS Interrupt
    dss   {.bitsize:  1.} : uint32  # DMA Setup FIS Interrupt
    sdbs  {.bitsize:  1.} : uint32  # Set Device Bits Interrupt
    ufs   {.bitsize:  1.} : uint32  # Unknown FIS Interrupt
    dps   {.bitsize:  1.} : uint32  # Descriptor Processed
    pcs   {.bitsize:  1.} : uint32  # Port Connect Change Status
    dmps  {.bitsize:  1.} : uint32  # Device Mechanical Presence Status
    rsv   {.bitsize: 14.} : uint32  # Reserved
    prcs  {.bitsize:  1.} : uint32  # PhyRdy Change Status
    ipms  {.bitsize:  1.} : uint32  # Incorrect Port Multiplier Status
    ofs   {.bitsize:  1.} : uint32  # Overflow Status
    rsv2  {.bitsize:  1.} : uint32  # Reserved
    infs  {.bitsize:  1.} : uint32  # Interface Non-fatal Error Status
    ifs   {.bitsize:  1.} : uint32  # Interface Fatal Error Status
    hbds  {.bitsize:  1.} : uint32  # Host Bus Data Error Status
    hbfs  {.bitsize:  1.} : uint32  # Host Bus Fatal Error Status
    tfes  {.bitsize:  1.} : uint32  # Task File Error Status
    cpds  {.bitsize:  1.} : uint32  # Cold Port Detect Status

  PortIE {.packed.} = object      # Port Interrupt Enable
    dhre  {.bitsize:  1.} : uint32  # Device to Host Register FIS Interrupt Enable
    pse   {.bitsize:  1.} : uint32  # PIO Setup FIS Interrupt Enable
    dse   {.bitsize:  1.} : uint32  # DMA Setup FIS Interrupt Enable
    sdbe  {.bitsize:  1.} : uint32  # Set Device Bits Interrupt Enable
    ufe   {.bitsize:  1.} : uint32  # Unknown FIS Interrupt Enable
    dpe   {.bitsize:  1.} : uint32  # Descriptor Processed Interrupt Enable
    pce   {.bitsize:  1.} : uint32  # Port Change Interrupt Enable
    dmpe  {.bitsize:  1.} : uint32  # Device Mechanical Presence Enable
    rsv   {.bitsize: 14.} : uint32  # Reserved
    prce  {.bitsize:  1.} : uint32  # PhyRdy Change Interrupt Enable
    ipme  {.bitsize:  1.} : uint32  # Incorrect Port Multiplier Enable
    ofe   {.bitsize:  1.} : uint32  # Overflow Enable
    rsv2  {.bitsize:  1.} : uint32  # Reserved
    infe  {.bitsize:  1.} : uint32  # Interface Non-fatal Error Enable
    ife   {.bitsize:  1.} : uint32  # Interface Fatal Error Enable
    hbde  {.bitsize:  1.} : uint32  # Host Bus Data Error Enable
    hbfe  {.bitsize:  1.} : uint32  # Host Bus Fatal Error Enable
    tfee  {.bitsize:  1.} : uint32  # Task File Error Enable
    cpde  {.bitsize:  1.} : uint32  # Cold Port Detect Enable

  PortCMD {.packed.} = object
    st    {.bitsize:  1.} : uint8   # Start
    sud   {.bitsize:  1.} : uint8   # Spin-Up Device
    pod   {.bitsize:  1.} : uint8   # Power On Device
    clo   {.bitsize:  1.} : uint8   # Command List Override
    fre   {.bitsize:  1.} : uint8   # FIS Receive Enable
    ccs   {.bitsize:  5.} : uint8   # Current Command Slot
    mpss  {.bitsize:  1.} : uint8   # Mechanical Presence Switch State
    fr    {.bitsize:  1.} : uint8   # FIS Receive Running
    cr    {.bitsize:  1.} : uint8   # Command List Running
    cps   {.bitsize:  1.} : uint8   # Cold Presence State
    pma   {.bitsize:  1.} : uint8   # Port Multiplier Attached
    hpcp  {.bitsize:  1.} : uint8   # Hot Plug Capable Port
    mpsp  {.bitsize:  1.} : uint8   # Mechanical Presence Switch Attached to Port
    cpd   {.bitsize:  1.} : uint8   # Cold Presence Detection
    esp   {.bitsize:  1.} : uint8   # External SATA Port
    fbscp {.bitsize:  1.} : uint8   # FIS-based Switching Capable Port
    apste {.bitsize:  1.} : uint8   # Automatic Partial to Slumber Transitions Enabled
    atapi {.bitsize:  1.} : uint8   # Device is ATAPI
    dlae  {.bitsize:  1.} : uint8   # Drive LED on ATAPI Enable
    alpe  {.bitsize:  1.} : uint8   # Aggressive Link Power Management Enable
    asp   {.bitsize:  1.} : uint8   # Agressive Slumber / Partial
    icc   {.bitsize:  4.} : uint8   # Interface Communication Control

  PortTFD {.packed.} = object
    sts   {.bitsize:  8.} : uint32  # Status
    err   {.bitsize:  8.} : uint32  # Error
    rsv   {.bitsize: 16.} : uint32  # Reserved
  
  PortSIG {.packed.} = object
    sig   {.bitsize: 32.} : uint32  # Signature

  PortSSTS {.packed.} = object    # Port SATA Status (SCR0: SStatus)
    det   {.bitsize:  4.} : uint32  # Device Detection
    spd   {.bitsize:  4.} : uint32  # Current Interface Speed
    ipm   {.bitsize:  4.} : uint32  # Interface Power Management
    rsv   {.bitsize: 20.} : uint32  # Reserved

  PortSCTL {.packed.} = object    # Port SATA Control (SCR2: SControl)
    det   {.bitsize:  4.} : uint32  # Device Detection Initialization
    spd   {.bitsize:  4.} : uint32  # Speed Allowed
    ipm   {.bitsize:  4.} : uint32  # Interface Power Management Transitions Allowed
    spm   {.bitsize:  4.} : uint32  # Select Power Management (not used by AHCI)
    pmp   {.bitsize:  4.} : uint32  # Port Multiplier Port (not used by AHCI)
    rsv   {.bitsize: 12.} : uint32  # Reserved

  PortSERR {.packed.} = object    # Port SATA Error (SCR1: SError)
    err   {.bitsize: 16.} : uint32  # Error
    diag  {.bitsize: 16.} : uint32  # Diagnostics

  PortSACT {.packed.} = object    # Port SATA Active (SCR3: SActive)
    ds    {.bitsize: 32.} : uint32  # Device Status

  PortCI {.packed.} = object      # Port Command Issue
    ci    {.bitsize: 32.} : uint32  # Commands Issued

  PortSNTF {.packed.} = object    # Port SATA Notification (SCR4: SNotification)
    pmn   {.bitsize: 16.} : uint32  # PM Notify
    rsv   {.bitsize: 16.} : uint32  # Reserved

  PortFBS {.packed.} = object    # Port FIS-based Switching Control
    en    {.bitsize:  1.} : uint32  # Enable
    dec   {.bitsize:  1.} : uint32  # Device Error Clear
    sde   {.bitsize:  1.} : uint32  # Single Device Error
    rsv   {.bitsize:  5.} : uint32  # Reserved
    dev   {.bitsize:  4.} : uint32  # Device To Issue
    ado   {.bitsize:  4.} : uint32  # Active Device Optimization
    dwe   {.bitsize:  4.} : uint32  # Device With Error
    rsv2  {.bitsize: 12.} : uint32  # Reserved

  PortDEVSLP {.packed.} = object  # Port Device Sleep
    adse  {.bitsize:  1.} : uint32  # Aggressive Device Sleep Enable
    dsp   {.bitsize:  1.} : uint32  # Device Sleep Present
    deto  {.bitsize:  8.} : uint32  # Device Sleep Exit Timeout
    mdat  {.bitsize:  5.} : uint32  # Minimum Device Sleep Assertion Time
    dito  {.bitsize: 10.} : uint32  # Device Sleep Idle Timeout
    dm    {.bitsize:  4.} : uint32  # DITO Multiplier
    rsv   {.bitsize:  3.} : uint32  # Reserved

  PortRegisters = object
    clb    : PortCLB
    clbu   : PortCLBU
    fb     : PortFB
    fbu    : PortFBU
    `is`   : PortIS
    ie     : PortIE
    cmd    : PortCMD
    rsv    : uint32
    tfd    : PortTFD
    sig    : PortSIG
    ssts   : PortSSTS
    sctl   : PortSCTL
    serr   : PortSERR
    sact   : PortSACT
    ci     : PortCI
    sntf   : PortSNTF
    fbs    : PortFBS
    devslp : PortDEVSLP
    rsv2   : array[10, uint32]
    vs     : array[4, uint32]  # Vendor Specific

  # Command Header

  CommandHeader {.packed.} = object
    cfl   {.bitsize:  5.} : uint32  # Command FIS Length
    a     {.bitsize:  1.} : uint32  # ATAPI
    w     {.bitsize:  1.} : uint32  # Write
    p     {.bitsize:  1.} : uint32  # Prefetchable
    r     {.bitsize:  1.} : uint32  # Reset
    b     {.bitsize:  1.} : uint32  # BIST
    c     {.bitsize:  1.} : uint32  # Clear Busy upon R_OK
    rsv0  {.bitsize:  1.} : uint32  # Reserved
    pmp   {.bitsize:  4.} : uint32  # Port Multiplier Port
    prdtl {.bitsize: 16.} : uint32  # Physical Region Descriptor Table Length
    prdbc                 : uint32  # Physical Region Descriptor Byte Count
    ctba                  : uint32  # Command Table Descriptor Base Address
    ctbau                 : uint32  # Command Table Descriptor Base Address Upper 32-bits
    rsv1                  : array[4, uint32]

  CommandTable {.packed.} = object
    cfis: array[64, uint8]  # Command FIS (up to 64 bytes)
    acmd: array[16, uint8]  # ATAPI Command (12 or 16 bytes)
    rsvd: array[48, uint8]  # Reserved
    prdt: array[01, PRD]   # Physical Region Descriptor Table
  PRD {.packed.} = object
    dba   {.bitsize: 32.} : uint32  # Data Base Address
    dbau  {.bitsize: 32.} : uint32  # Data Base Address Upper 32-bits
    rsv1  {.bitsize: 32.} : uint32  # Reserved
    dbc   {.bitsize: 22.} : uint32  # Data Byte Count (max 4MB)
    rsv2  {.bitsize:  9.} : uint32  # Reserved
    i     {.bitsize:  1.} : uint32  # Interrupt on Completion

  FisRegisterH2D {.packed.} = object
    fisType                    : uint8  # FIS Type
    pmPort     {.bitsize:  4.} : uint8   # PM Port
    rsv0       {.bitsize:  3.} : uint8   # Reserved
    c          {.bitsize:  1.} : uint8   # 1 = Command, 0 = Device Control
    command                    : uint8   # Command
    features00                 : uint8   # Features(7:0)
    lba00                      : uint8   # LBA(07:00)
    lba08                      : uint8   # LBA(15:08)
    lba16                      : uint8   # LBA(23:16)
    device                     : uint8   # Device
    lba24                      : uint8   # LBA(31:24)
    lba32                      : uint8   # LBA(39:32)
    lba40                      : uint8   # LBA(47:40)
    features08                 : uint8   # Features(15:8)
    count00                    : uint8   # Count(07:00)
    count08                    : uint8   # Count(15:08)
    icc                        : uint8   # Isochronous Command Completion
    control                    : uint8   # Control
    rsv1                       : uint32  # Reserved

proc dumpAhci*(bus, dev, fn: uint8, bs: ptr EfiBootServices) =
  println("")
  println("AHCI")
  println("")

  var
    capOffset = pciConfigRead16(bus, dev, fn, 0x34).uint8
    capValue: uint8
    nextCapOffset: uint8

  if capOffset != 0:
    while capOffset != 0:
      (capValue, nextCapOffset) = pciNextCapability(bus, dev, fn, capOffset)
      if capValue == 0x12: # SATA Index-Data Pair (IDP) Configuration
        print("  IDP capability:")
        let revision = pciConfigRead16(bus, dev, fn, capOffset + 2)
        print(&" revision={(revision shr 4) and 0xf}.{revision and 0xf}")
        let satacr1 = pciConfigRead16(bus, dev, fn, capOffset + 4)
        print(&", barloc={satacr1 and 0xf:0>4b}b, barofst={(satacr1 shr 4) and 0xfffff:0>5x}h")
      capOffset = nextCapOffset
    println("")

  println("")

  let abar = pciConfigRead32(bus, dev, fn, 0x24) # BAR5
  println(&"  ABAR = {abar:0>8x}h")

  let hbaCap = cast[ptr HbaCap](abar)  # HBA Capabilities
  println(&"  CAP = {hbaCap[]}")

  let globalHbaControl = cast[ptr GlobalHbaControl](abar + 0x04)  # Globla HBA Control
  println(&"  GHC = {globalHbaControl[]}")

  let ips = cast[ptr uint32](abar + 0x08)  # Interrupt Pending Status
  println(&"  IPS = {ips[]:0>32b}b")

  let pi = cast[ptr uint32](abar + 0x0c)  # Ports Implemented
  println(&"  PI  = {pi[]:0>32b}b")

  let vs = cast[ptr uint32](abar + 0x10)  # AHCI Version
  println(&"  VS  = {vs[]:0>8x}h")

  # Ports

  let startingPortOffset = 0x100'u32
  for i in [0, 2]:
    var portOffset = startingPortOffset + (i.uint32 * 0x80)
    let portRegs = cast[ptr PortRegisters](abar + portOffset)

    # portRegs.sctl.det = 1
    # var x = 0
    # for i in 0 .. 10000:
    #   inc(x)
    # portRegs.sctl.det = 0

    println("")
    println(&"  Port {i} Registers")
    println(&"    CLB    = {portRegs.clb.clb:0>8x}h")
    println(&"    CLBU   = {portRegs.clbu.clbu:0>8x}h")
    println(&"    FB     = {portRegs.fb.fb:0>8x}h")
    println(&"    FBU    = {portRegs.fbu.fbu:0>8x}h")
    println(&"    IS     = {portRegs.is}")
    println(&"    IE     = {portRegs.ie}")
    println(&"    CMD    = {portRegs.cmd}")
    println(&"    TFD    = sts:{portRegs.tfd.sts:0>8b}b, err:{portRegs.tfd.err:0>8b}b")
    println(&"    SIG    = {portRegs.sig.sig:0>8x}h")
    println(&"    SSTS   = {portRegs.ssts}")
    println(&"    SCTL   = {portRegs.sctl}")
    println(&"    SERR   = {portRegs.serr}")
    println(&"    SACT   = {portRegs.sact.ds:0>32b}b")
    println(&"    CI     = {portRegs.ci.ci:0>32b}b")
    println(&"    SNTF   = {portRegs.sntf.pmn:0>16b}b")
    println(&"    FBS    = {portRegs.fbs}")
    println(&"    DEVSLP = {portRegs.devslp}")


    if portRegs.ssts.det == 3:  # port has a device attached
      # identify device

      var ident: array[256, uint16]

      var cmdCode: uint8 =  0xEC  # IDENTIFY DEVICE
      if portRegs.sig.sig == 0xeb140101'u32:
        cmdCode = 0xA1            # IDENTIFY PACKET DEVICE

      var fis = FisRegisterH2D(
        fisType: 0x27,  # RegisterH2D
        c: 1,           # Command
        command: cmdCode,
      )

      var cmdTable = CommandTable(
        cfis: cast[array[64, byte]](fis),
        prdt: [PRD(
          dba: cast[uint32](addr ident),
          dbc: sizeof(ident) - 1,
          i: 1,
        )]
      )

      let clb64: uint64 = portRegs.clb.clb or (portRegs.clbu.clbu.uint64 shl 32)
      let cmdHeaderPtr = cast[ptr CommandHeader](clb64)
      cmdHeaderPtr[] = CommandHeader(
        cfl: 5,
        prdtl: 1,
        ctba: cast[uint32](addr cmdTable),
      )

      portRegs.is = cast[PortIS](0xffffffff'u32)
      println(&"  IS      = {portRegs.is}")

      portRegs.cmd.st = 1
      portRegs.cmd.fre = 1
      println(&"  CMD     = {portRegs.cmd}")

      println(&"  TFD.sts = {portRegs.tfd.sts:0>8b}b")

      portRegs.serr = cast[PortSERR](0xffffffff'u32)
      println(&"  SERR    = {portRegs.serr}")

      portRegs.ci.ci = 1

      println(&"  IS      = {portRegs.is}")
      println(&"  CMD     = {portRegs.cmd}")
      println(&"  TFD.sts = {portRegs.tfd.sts:0>8b}b")
      println(&"  CI      = {portRegs.ci.ci:0>32b}b")
      println(&"  SERR    = {portRegs.serr}")

      # for i in 0 .. 81:
      #   println(&"  IDENTIFY[{i:0>2}] = {ident[i]:0>4x}h")

      let idData = cast[IdentifyDeviceData](ident)
      println(&"  Model number:          {idData.modelNo}")
      println(&"  Serial number:         {idData.serialNo}")
      println(&"  FW revision:           {idData.firmwareRevision}")
      println(&"  Multiple Count:        {idData.multipleCount}")
      println(&"  Cap DMA:               {idData.capDma}")
      println(&"  Cap LBA:               {idData.capLba}")
      println(&"  Total Sectors:         {idData.totalSectors}")
      println(&"  Multiword DMA0:        {idData.multiwordDma0Support}")
      println(&"  Multiword DMA1:        {idData.multiwordDma1Support}")
      println(&"  Multiword DMA2:        {idData.multiwordDma2Support}")
      println(&"  PIO Mode 3/4:          {idData.pioMode34Support:0>2b}b")
      println(&"  ATA/ATAPI-5:           {idData.ata5}")
      println(&"  ATA/ATAPI-6:           {idData.ata6}")
      println(&"  ATA/ATAPI-7:           {idData.ata7}")
      println(&"  ATA8-ACS:              {idData.ata8acs}")
      println(&"  ACS-2:                 {idData.acs2}")
      println(&"  ACS-3:                 {idData.acs3}")
      println(&"  ACS-4:                 {idData.acs4}")
      println(&"  Minor Version:         {idData.minorVersion:0>4x}h")
      println(&"  Max Queue Depth:       {idData.maxQueueDepth}")
      println(&"  SATA Gen1 Speed:       {idData.sataGen1}")
      println(&"  SATA Gen2 Speed:       {idData.sataGen2}")
      println(&"  SATA Gen3 Speed:       {idData.sataGen3}")
      println(&"  SATA NCQ:              {idData.sataNcq}")
      println(&"  SATA Host IPM:         {idData.sataHostIpm}")
      println(&"  SATA Phy Evt Counters: {idData.sataPhyEventCounters}")
      println(&"  SATA NCQ Unload:       {idData.sataNcqUnload}")
      println(&"  SATA NCQ Pri:          {idData.sataNcqPriority}")
      println(&"  SATA Host Auto P2S:    {idData.sataHostAutoP2S}")
      println(&"  SATA Dev Auto P2S:     {idData.sataDeviceAutoP2S}")
      