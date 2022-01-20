import std/strformat

import debug
import pci

type
  # Generic Host Control Registers

  HbaCap {.packed.} = object
    np    {.bitsize:  4.} : uint32  # Number of Ports
    sxs   {.bitsize:  1.} : uint32  # Supports External SATA
    ems   {.bitsize:  1.} : uint32  # Enclosure Management Supported
    cccs  {.bitsize:  1.} : uint32  # Command Completion Coalescing Supported
    ncs   {.bitsize:  1.} : uint32  # Number of Command Slots
    psc   {.bitsize:  1.} : uint32  # Partial State Capable
    ssc   {.bitsize:  1.} : uint32  # Slumber State Capable
    pmd   {.bitsize:  1.} : uint32  # PIO Multiple DRQ Block
    fbss  {.bitsize:  1.} : uint32  # FIS-based Switching Supported
    spm   {.bitsize:  1.} : uint32  # Supports Port Multiplier
    sam   {.bitsize:  1.} : uint32  # Supports AHCI Mode only
    rsv   {.bitsize:  1.} : uint32  # Reserved
    iss   {.bitsize:  4.} : uint32  # Interface Speed Support
    sclo  {.bitsize:  1.} : uint32  # Supports Command List Override
    sal   {.bitsize:  1.} : uint32  # Supports Activity LED
    salp  {.bitsize:  1.} : uint32  # Supports Agressive Link Power Management
    sss   {.bitsize:  1.} : uint32  # Supports Staggered Spin-up
    smps  {.bitsize:  1.} : uint32  # Supports Mechanical Presence Switch
    ssntf {.bitsize:  1.} : uint32  # Supports SNotification Register
    sncq  {.bitsize:  1.} : uint32  # Supports Native Command Queuing
    s64a  {.bitsize:  1.} : uint32  # Supports 64-bit Addressing

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
    st    {.bitsize:  1.} : uint32  # Start
    sud   {.bitsize:  1.} : uint32  # Spin-Up Device
    pod   {.bitsize:  1.} : uint32  # Power On Device
    clo   {.bitsize:  1.} : uint32  # Command List Override
    fre   {.bitsize:  1.} : uint32  # FIS Receive Enable
    ccs   {.bitsize:  1.} : uint32  # Current Command Slot
    mpss  {.bitsize:  1.} : uint32  # Mechanical Presence Switch State
    fr    {.bitsize:  1.} : uint32  # FIS Receive Running
    cr    {.bitsize:  1.} : uint32  # Command List Running
    cps   {.bitsize:  1.} : uint32  # Cold Presence State
    pma   {.bitsize:  1.} : uint32  # Port Multiplier Attached
    hpcp  {.bitsize:  1.} : uint32  # Hot Plug Capable Port
    mpsp  {.bitsize:  1.} : uint32  # Mechanical Presence Switch Attached to Port
    cpd   {.bitsize:  1.} : uint32  # Cold Presence Detection
    esp   {.bitsize:  1.} : uint32  # External SATA Port
    fbscp {.bitsize:  1.} : uint32  # FIS-based Switching Capable Port
    apste {.bitsize:  1.} : uint32  # Automatic Partial to Slumber Transitions Enabled
    atapi {.bitsize:  1.} : uint32  # Device is ATAPI
    dlae  {.bitsize:  1.} : uint32  # Drive LED on ATAPI Enable
    alpe  {.bitsize:  1.} : uint32  # Aggressive Link Power Management Enable
    asp   {.bitsize:  1.} : uint32  # Agressive Slumber / Partial
    icc   {.bitsize:  4.} : uint32  # Interface Communication Control

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

  PortSACT {.packed.} = object    # Port SATA Error (SCR3: SActive)
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


proc dumpAhci*(bus, dev, fn: uint8) =
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

  var portOffset = 0x100'u32
  let portRegs = cast[ptr PortRegisters](abar + portOffset)
  println(&"  Port 0 Registers")
  println(&"    CLB    = {portRegs.clb.clb:0>8x}h")
  println(&"    CLBU   = {portRegs.clbu.clbu:0>8x}h")
  println(&"    FB     = {portRegs.fb.fb:0>8x}h")
  println(&"    FBU    = {portRegs.fbu.fbu:0>8x}h")
  println(&"    IS     = {portRegs.is}")
  println(&"    IE     = {portRegs.ie}")
  println(&"    CMD    = {portRegs.cmd}")
  println(&"    TFD    = {portRegs.tfd}")
  println(&"    SIG    = {portRegs.sig.sig:0>8x}h")
  println(&"    SSTS   = {portRegs.ssts}")
  println(&"    SCTL   = {portRegs.sctl}")
  println(&"    SERR   = {portRegs.serr}")
  println(&"    SACT   = {portRegs.sact}")
  println(&"    CI     = {portRegs.ci}")
  println(&"    SNTF   = {portRegs.sntf}")
  println(&"    FBS    = {portRegs.fbs}")
  println(&"    DEVSLP = {portRegs.devslp}")
