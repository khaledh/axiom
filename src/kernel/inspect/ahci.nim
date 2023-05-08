import std/importutils
import std/strformat

import ../devices/ahci {.all.}
import ../devices/ata
import ../devices/console
import ../devices/pci
import ../../boot/uefitypes

privateAccess(PortRegisters)
privateAccess(PortCLB)
privateAccess(PortCLBU)
privateAccess(PortFB)
privateAccess(PortFBU)
privateAccess(PortTFD)
privateAccess(PortSIG)
privateAccess(PortSACT)
privateAccess(PortCI)
privateAccess(PortSNTF)
privateAccess(PortSSTS)
privateAccess(FisRegisterH2D)
privateAccess(CommandTable)
privateAccess(PRD)
privateAccess(CommandHeader)
privateAccess(PortCMD)

proc showAhci*(bus, dev, fn: uint8, bs: ptr EfiBootServices) =
  writeln("")
  writeln("AHCI")
  writeln("")

  var
    capOffset = pciConfigRead16(bus, dev, fn, 0x34).uint8
    capValue: uint8
    nextCapOffset: uint8

  if capOffset != 0:
    while capOffset != 0:
      (capValue, nextCapOffset) = pciNextCapability(bus, dev, fn, capOffset)
      if capValue == 0x12: # SATA Index-Data Pair (IDP) Configuration
        write("  IDP capability:")
        let revision = pciConfigRead16(bus, dev, fn, capOffset + 2)
        write(&" revision={(revision shr 4) and 0xf}.{revision and 0xf}")
        let satacr1 = pciConfigRead16(bus, dev, fn, capOffset + 4)
        write(&", barloc={satacr1 and 0xf:0>4b}b, barofst={(satacr1 shr 4) and 0xfffff:0>5x}h")
      capOffset = nextCapOffset
    writeln("")

  writeln("")

  let abar = pciConfigRead32(bus, dev, fn, 0x24) # BAR5
  writeln(&"  ABAR = {abar:0>8x}h")

  let hbaCap = cast[ptr HbaCap](abar.uint64) # HBA Capabilities
  writeln(&"  CAP = {hbaCap[]}")

  let globalHbaControl = cast[ptr GlobalHbaControl](abar.uint64 + 0x04) # Globla HBA Control
  writeln(&"  GHC = {globalHbaControl[]}")

  let ips = cast[ptr uint32](abar.uint64 + 0x08) # Interrupt Pending Status
  writeln(&"  IPS = {ips[]:0>32b}b")

  let pi = cast[ptr uint32](abar.uint64 + 0x0c) # Ports Implemented
  writeln(&"  PI  = {pi[]:0>32b}b")

  let vs = cast[ptr uint32](abar.uint64 + 0x10) # AHCI Version
  writeln(&"  VS  = {vs[]:0>8x}h")

  # Ports

  let startingPortOffset = 0x100'u32
  for i in [0, 2]:
    var portOffset = startingPortOffset + (i.uint32 * 0x80)
    let portRegs = cast[ptr PortRegisters](abar.uint64 + portOffset)

    # portRegs.sctl.det = 1
    # var x = 0
    # for i in 0 .. 10000:
    #   inc(x)
    # portRegs.sctl.det = 0

    writeln("")
    writeln(&"  Port {i} Registers")
    writeln(&"    CLB    = {portRegs.clb.clb:0>8x}h")
    writeln(&"    CLBU   = {portRegs.clbu.clbu:0>8x}h")
    writeln(&"    FB     = {portRegs.fb.fb:0>8x}h")
    writeln(&"    FBU    = {portRegs.fbu.fbu:0>8x}h")
    writeln(&"    IS     = {portRegs.is}")
    writeln(&"    IE     = {portRegs.ie}")
    writeln(&"    CMD    = {portRegs.cmd}")
    writeln(&"    TFD    = sts:{portRegs.tfd.sts:0>8b}b, err:{portRegs.tfd.err:0>8b}b")
    writeln(&"    SIG    = {portRegs.sig.sig:0>8x}h")
    writeln(&"    SSTS   = {portRegs.ssts}")
    writeln(&"    SCTL   = {portRegs.sctl}")
    writeln(&"    SERR   = {portRegs.serr}")
    writeln(&"    SACT   = {portRegs.sact.ds:0>32b}b")
    writeln(&"    CI     = {portRegs.ci.ci:0>32b}b")
    writeln(&"    SNTF   = {portRegs.sntf.pmn:0>16b}b")
    writeln(&"    FBS    = {portRegs.fbs}")
    writeln(&"    DEVSLP = {portRegs.devslp}")


    if portRegs.ssts.det == 3: # port has a device attached
      # identify device

      var ident: array[256, uint16]

      var cmdCode: uint8 = 0xEC # IDENTIFY DEVICE
      if portRegs.sig.sig == 0xeb140101'u32:
        cmdCode = 0xA1 # IDENTIFY PACKET DEVICE

      var fis = FisRegisterH2D(
        fisType: 0x27, # RegisterH2D
        c: 1,          # Command
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
      writeln(&"  IS      = {portRegs.is}")

      portRegs.cmd.st = 1
      portRegs.cmd.fre = 1
      writeln(&"  CMD     = {portRegs.cmd}")

      writeln(&"  TFD.sts = {portRegs.tfd.sts:0>8b}b")

      portRegs.serr = cast[PortSERR](0xffffffff'u32)
      writeln(&"  SERR    = {portRegs.serr}")

      portRegs.ci.ci = 1

      writeln(&"  IS      = {portRegs.is}")
      writeln(&"  CMD     = {portRegs.cmd}")
      writeln(&"  TFD.sts = {portRegs.tfd.sts:0>8b}b")
      writeln(&"  CI      = {portRegs.ci.ci:0>32b}b")
      writeln(&"  SERR    = {portRegs.serr}")

      # for i in 0 .. 81:
      #   writeln(&"  IDENTIFY[{i:0>2}] = {ident[i]:0>4x}h")

      let idData = cast[IdentifyDeviceData](ident)
      writeln(&"  Model number:          {idData.modelNo}")
      writeln(&"  Serial number:         {idData.serialNo}")
      writeln(&"  FW revision:           {idData.firmwareRevision}")
      writeln(&"  Multiple Count:        {idData.multipleCount}")
      writeln(&"  Cap DMA:               {idData.capDma}")
      writeln(&"  Cap LBA:               {idData.capLba}")
      writeln(&"  Total Sectors:         {idData.totalSectors}")
      writeln(&"  Multiword DMA0:        {idData.multiwordDma0Support}")
      writeln(&"  Multiword DMA1:        {idData.multiwordDma1Support}")
      writeln(&"  Multiword DMA2:        {idData.multiwordDma2Support}")
      writeln(&"  PIO Mode 3/4:          {idData.pioMode34Support:0>2b}b")
      writeln(&"  ATA/ATAPI-5:           {idData.ata5}")
      writeln(&"  ATA/ATAPI-6:           {idData.ata6}")
      writeln(&"  ATA/ATAPI-7:           {idData.ata7}")
      writeln(&"  ATA8-ACS:              {idData.ata8acs}")
      writeln(&"  ACS-2:                 {idData.acs2}")
      writeln(&"  ACS-3:                 {idData.acs3}")
      writeln(&"  ACS-4:                 {idData.acs4}")
      writeln(&"  Minor Version:         {idData.minorVersion:0>4x}h")
      writeln(&"  Max Queue Depth:       {idData.maxQueueDepth}")
      writeln(&"  SATA Gen1 Speed:       {idData.sataGen1}")
      writeln(&"  SATA Gen2 Speed:       {idData.sataGen2}")
      writeln(&"  SATA Gen3 Speed:       {idData.sataGen3}")
      writeln(&"  SATA NCQ:              {idData.sataNcq}")
      writeln(&"  SATA Host IPM:         {idData.sataHostIpm}")
      writeln(&"  SATA Phy Evt Counters: {idData.sataPhyEventCounters}")
      writeln(&"  SATA NCQ Unload:       {idData.sataNcqUnload}")
      writeln(&"  SATA NCQ Pri:          {idData.sataNcqPriority}")
      writeln(&"  SATA Host Auto P2S:    {idData.sataHostAutoP2S}")
      writeln(&"  SATA Dev Auto P2S:     {idData.sataDeviceAutoP2S}")
