#[
  Fixed ACPI Description Table
]#
import std/options
import std/strformat

import table, xsdt, aml, amltree
import ../devices/console


type
  Fadt* {.packed.} = object
    hdr: TableDescriptionHeader
    firmwareCtrl: uint32
    dsdt: uint32
    reserved1: uint8
    preferredPmProfile: uint8
    sciInt: uint16
    smiCmd: uint32
    acpiEnable: uint8
    acpiDisable: uint8
    s4BiosReq: uint8
    pstateCnt: uint8
    pm1aEvtBlk: uint32
    pm1bEvtBlk: uint32
    pm1aCntBlk: uint32
    pm1bCntBlk: uint32
    pm2CntBlk: uint32
    pmTmrBlk: uint32
    gpe0Blk: uint32
    gpe1Blk: uint32
    pm1EvtLen: uint8
    pm1CntLen: uint8
    pm2CntLen: uint8
    pm_tmrLen: uint8
    gpe0BlkLen: uint8
    gpe1BlkLen: uint8
    gpe1Base: uint8
    cstCnt: uint8
    pLvl2Lat: uint16
    pLvl3Lat: uint16
    flushSize: uint16
    flushStride: uint16
    dutyOffset: uint8
    dutyWidth: uint8
    dayAlarm: uint8
    monAlarm: uint8
    century: uint8
    iapcBootArch: uint16
    reserved2: uint8
    flags: uint32
    # end of ACPI 1.0 fields
    resetReg: GenericAddress
    resetValue: uint8
    armBootArch: uint16
    fadtMinorVersion: uint8
    xFirmwareCtrl: uint64
    xDsdt: uint64
    xPm1aEvtBlk: GenericAddress
    xPm1bEvtBlk: GenericAddress
    xPm1aCntBlk: GenericAddress
    xPm1bCntBlk: GenericAddress
    xPm2CntBlk: GenericAddress
    xPm_tmrBlk: GenericAddress
    xGpe0Blk: GenericAddress
    xGpe1Blk: GenericAddress
    sleepControlReg: GenericAddress
    sleepStatusReg: GenericAddress
    hypervisorVendorIdentity: uint64

  IapcBootArchFlag {.size: sizeof(uint16).} = enum
    LegacyDevices
    Has8042
    VgaNotPresent
    MsiNotSupported
    PcieAspmControls
    CmosRtcNotPresent
  IapcBootArchFlags = set[IapcBootArchFlag]

  GenericAddress {.packed.} = object
    addrSpaceId: AddressSpaceId
    regBitWidth: uint8
    regBitOffset: uint8
    accessSize: uint8
    address: uint64

  AddressSpaceId = enum
    SystemMemory
    SystemIO
    PciConfig
    EmbeddedController
    SMBus
    SystemCMOS
    PciBarTarger
    Ipmi
    GeneralPurposeIO
    GenericSerialBus
    Pcc  # Platform Communications Channel

  Dsdt* {.packed.} = object
    hdr: TableDescriptionHeader
    aml: UncheckedArray[uint8]

var
  fadt0*: ptr Fadt


proc parseFadt*(p: pointer): ptr Fadt =
  result = cast[ptr Fadt](p)


proc init*() =
  let hdr = findBySignature(['F', 'A', 'C', 'P'])
  if hdr.isSome:
    fadt0 = parseFadt(cast[pointer](hdr.get()))
  else:
    writeln("Could not initialize FADT")


proc `$`(ga: GenericAddress): string =
  &"[{ga.addrSpaceId: >12}] {ga.address: >8x}h [offset: {ga.regBitOffset: >3}, width: {ga.regBitWidth: >3}, access_size: {ga.accessSize: >3}]"


proc showFadt*() =
    writeln("")
    writeln("FADT (Fixed ACPI Description Table)")

    # writeTableDescHeader(fadt0.hdr)
    writeln(&"  Revision:             {fadt0.hdr.revision: >8}")

    writeln(&"  FIRMWARE_CTRL (FACS): {fadt0.firmwareCtrl:0>8x}h")
    writeln(&"  DSDT:                 {fadt0.xDsdt:0>16x}h")
    writeln(&"  Preferred PM Profile: {fadt0.preferred_pm_profile: >8}")
    writeln(&"  SCI_INT:              {fadt0.sciInt: >8}")
    writeln(&"  SMI_CMD:              {fadt0.smiCmd:>8x}h")
    writeln(&"  ACPI_ENABLE:          {fadt0.acpiEnable:>8x}h")
    writeln(&"  ACPI_DISABLE:         {fadt0.acpiDisable:>8x}h")
    writeln(&"  S4BIOS_REQ:           {fadt0.s4BiosReq:0>8x}h")
    writeln(&"  PSTATE_CNT:           {fadt0.pstateCnt:0>8x}h")
    writeln(&"  PM1a_EVT_BLK:         {fadt0.pm1aEvtBlk: >8x}h")
    writeln(&"  PM1b_EVT_BLK:         {fadt0.pm1b_evt_blk: >8x}h")
    writeln(&"  PM1a_CNT_BLK:         {fadt0.pm1a_cnt_blk: >8x}h")
    writeln(&"  PM1b_CNT_BLK:         {fadt0.pm1bCntBlk: >8x}h")
    writeln(&"  PM2_CNT_BLK:          {fadt0.pm2CntBlk: >8x}h")
    writeln(&"  PM_TMR_BLK:           {fadt0.pmTmrBlk: >8x}h")
    writeln(&"  GPE0_BLK:             {fadt0.gpe0Blk: >8x}h")
    writeln(&"  GPE1_BLK:             {fadt0.gpe1Blk: >8x}h")
    writeln(&"  PM1_EVT_LEN:          {fadt0.pm1EvtLen: >8}")
    writeln(&"  PM1_CNT_LEN:          {fadt0.pm1CntLen: >8}")
    writeln(&"  PM2_CNT_LEN:          {fadt0.pm2CntLen: >8}")
    writeln(&"  PM_TMR_LEN:           {fadt0.pmTmrLen: >8}")
    writeln(&"  GPE0_BLK_LEN:         {fadt0.gpe0BlkLen: >8}")
    writeln(&"  GPE1_BLK_LEN:         {fadt0.gpe1BlkLen: >8}")
    writeln(&"  GPE1_BASE:            {fadt0.gpe1Base: >8}")
    writeln(&"  CST_CNT:              {fadt0.cstCnt: >8x}h")
    writeln(&"  P_LVL2_LAT:           {fadt0.pLvl2Lat: >8x}h")
    writeln(&"  P_LVL3_LAT:           {fadt0.pLvl3Lat: >8x}h")
    writeln(&"  FLUSH_SIZE:           {fadt0.flushSize: >8}")
    writeln(&"  FLUSH_STRIDE:         {fadt0.flushStride: >8}")
    writeln(&"  DUTY_OFFSET:          {fadt0.dutyOffset: >8}")
    writeln(&"  DUTY_WIDTH:           {fadt0.dutyWidth: >8}")
    writeln(&"  DAY_ALRM:             {fadt0.dayAlarm: >8}")
    writeln(&"  MON_ALRM:             {fadt0.monAlarm: >8}")
    writeln(&"  CENTURY:              {fadt0.century: >8}")
    writeln(&"  IAPC_BOOT_ARCH:       {cast[IapcBootArchFlags](fadt0.iapcBootArch)}")
    writeln(&"  Flags:        {fadt0.flags: >16b}b")
    writeln(&"  RESET_REG:            {fadt0.resetReg}")
    writeln(&"  RESET_VALUE:          {fadt0.resetValue: >8x}h")

    if fadt0.hdr.revision >= 3:
      writeln(&"  X_FIRMWARE_CTRL:      {fadt0.xFirmwareCtrl:0>8}h")
      writeln(&"  X_DSDT:               {fadt0.xdsdt:0>8x}h")
      writeln(&"  X_PM1a_EVT_BLK:       {fadt0.xPm1aEvtBlk}")
      writeln(&"  X_PM1b_EVT_BLK:       {fadt0.xPm1b_evt_blk}")
      writeln(&"  X_PM1a_CNT_BLK:       {fadt0.xPm1a_cnt_blk}")
      writeln(&"  X_PM1b_CNT_BLK:       {fadt0.xPm1bCntBlk}")
      writeln(&"  X_PM2_CNT_BLK:        {fadt0.xPm2CntBlk}")
      writeln(&"  X_PM_TMR_BLK:         {fadt0.xPmTmrBlk}")
      writeln(&"  X_GPE0_BLK:           {fadt0.xGpe0Blk}")
      writeln(&"  X_GPE1_BLK:           {fadt0.xGpe1Blk}")

    if fadt0.hdr.revision >= 5:
      writeln(&"  X_GPE1_BLK:           {fadt0.sleepControlReg}")
      writeln(&"  X_GPE1_BLK:           {fadt0.sleepStatusReg}")

    if fadt0.hdr.revision >= 5 and fadt0.fadtMinorVersion >= 1:
      writeln(&"  ARM_BOOT_ARCH:        {fadt0.armBootArch:0>16b}b")

    if fadt0.hdr.revision >= 6:
      writeln(&"  Hypervisor Vendor Identity: {fadt0.hypervisorVendorIdentity: >16x}h")


    let dsdt = cast[ptr Dsdt](fadt0.xDsdt)
    writeln(&"  DSDT:                 {cast[uint64](dsdt):0>8x}h")
    writeln(&"  DSDT Signature:       {dsdt.hdr.signature}")
    writeln(&"  DSDT Length:          {dsdt.hdr.length: >8}")
    writeln(&"  DSDT Revision:        {dsdt.hdr.revision: >8}")
    writeln(&"  AML address:          {cast[uint64](addr dsdt.aml):0>8x}h")

    var p = Parser()
    let termList = p.parse(addr dsdt.aml, dsdt.hdr.length.int - sizeof(TableDescriptionHeader))
    writeln("")
    print(termList)

    # proc dumpHex(bytes: ptr UncheckedArray[uint8], len: int) =
    #   for i in 0 ..< len:
    #     if i mod 16 == 0:
    #       writeln("")
    #     write(&"{bytes[i]:0>2x} ")

    # dumpHex(addr dsdt.aml, dsdt.hdr.length.int - sizeof(TableDescriptionHeader))
