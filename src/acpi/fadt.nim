import std/strformat

import ../acpi
import ../debug

#[
  Fixed ACPI Description Table
]#

type
  AcpiFadt {.packed.} = object
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

proc `$`(ga: GenericAddress): string =
  &"[{ga.addrSpaceId: >12}] {ga.address: >8x}h [offset: {ga.regBitOffset: >3}, width: {ga.regBitWidth: >3}, access_size: {ga.accessSize: >3}]"

proc parseFadt*(p: pointer): ptr AcpiFadt =
  result = cast[ptr AcpiFadt](p)

proc dumpFadt*(fadt: ptr AcpiFadt) =
    println("")
    println("FADT (Fixed ACPI Description Table)")

    # printTableDescHeader(fadt.hdr)
    println(&"  Revision:             {fadt.hdr.revision: >8}")

    println(&"  FIRMWARE_CTRL (FACS): {fadt.firmwareCtrl:0>8x}h")
    println(&"  DSDT:                 {fadt.dsdt:0>8x}h")
    println(&"  Preferred PM Profile: {fadt.preferred_pm_profile: >8}")
    println(&"  SCI_INT:              {fadt.sciInt: >8}")
    println(&"  SMI_CMD:              {fadt.smiCmd:>8x}h")
    println(&"  ACPI_ENABLE:          {fadt.acpiEnable:>8x}h")
    println(&"  ACPI_DISABLE:         {fadt.acpiDisable:>8x}h")
    println(&"  S4BIOS_REQ:           {fadt.s4BiosReq:0>8x}h")
    println(&"  PSTATE_CNT:           {fadt.pstateCnt:0>8x}h")
    println(&"  PM1a_EVT_BLK:         {fadt.pm1aEvtBlk: >8x}h")
    println(&"  PM1b_EVT_BLK:         {fadt.pm1b_evt_blk: >8x}h")
    println(&"  PM1a_CNT_BLK:         {fadt.pm1a_cnt_blk: >8x}h")
    println(&"  PM1b_CNT_BLK:         {fadt.pm1bCntBlk: >8x}h")
    println(&"  PM2_CNT_BLK:          {fadt.pm2CntBlk: >8x}h")
    println(&"  PM_TMR_BLK:           {fadt.pmTmrBlk: >8x}h")
    println(&"  GPE0_BLK:             {fadt.gpe0Blk: >8x}h")
    println(&"  GPE1_BLK:             {fadt.gpe1Blk: >8x}h")
    println(&"  PM1_EVT_LEN:          {fadt.pm1EvtLen: >8}")
    println(&"  PM1_CNT_LEN:          {fadt.pm1CntLen: >8}")
    println(&"  PM2_CNT_LEN:          {fadt.pm2CntLen: >8}")
    println(&"  PM_TMR_LEN:           {fadt.pmTmrLen: >8}")
    println(&"  GPE0_BLK_LEN:         {fadt.gpe0BlkLen: >8}")
    println(&"  GPE1_BLK_LEN:         {fadt.gpe1BlkLen: >8}")
    println(&"  GPE1_BASE:            {fadt.gpe1Base: >8}")
    println(&"  CST_CNT:              {fadt.cstCnt: >8x}h")
    println(&"  P_LVL2_LAT:           {fadt.pLvl2Lat: >8x}h")
    println(&"  P_LVL3_LAT:           {fadt.pLvl3Lat: >8x}h")
    println(&"  FLUSH_SIZE:           {fadt.flushSize: >8}")
    println(&"  FLUSH_STRIDE:         {fadt.flushStride: >8}")
    println(&"  DUTY_OFFSET:          {fadt.dutyOffset: >8}")
    println(&"  DUTY_WIDTH:           {fadt.dutyWidth: >8}")
    println(&"  DAY_ALRM:             {fadt.dayAlarm: >8}")
    println(&"  MON_ALRM:             {fadt.monAlarm: >8}")
    println(&"  CENTURY:              {fadt.century: >8}")
    println(&"  IAPC_BOOT_ARCH:       {cast[IapcBootArchFlags](fadt.iapcBootArch)}")
    println(&"  Flags:        {fadt.flags: >16b}b")
    println(&"  RESET_REG:            {fadt.resetReg}")
    println(&"  RESET_VALUE:          {fadt.resetValue: >8x}h")

    if fadt.hdr.revision >= 3:
      println(&"  X_FIRMWARE_CTRL:      {fadt.xFirmwareCtrl:0>8}h")
      println(&"  X_DSDT:               {fadt.xdsdt:0>8x}h")
      println(&"  X_PM1a_EVT_BLK:       {fadt.xPm1aEvtBlk}")
      println(&"  X_PM1b_EVT_BLK:       {fadt.xPm1b_evt_blk}")
      println(&"  X_PM1a_CNT_BLK:       {fadt.xPm1a_cnt_blk}")
      println(&"  X_PM1b_CNT_BLK:       {fadt.xPm1bCntBlk}")
      println(&"  X_PM2_CNT_BLK:        {fadt.xPm2CntBlk}")
      println(&"  X_PM_TMR_BLK:         {fadt.xPmTmrBlk}")
      println(&"  X_GPE0_BLK:           {fadt.xGpe0Blk}")
      println(&"  X_GPE1_BLK:           {fadt.xGpe1Blk}")

    if fadt.hdr.revision >= 5:
      println(&"  X_GPE1_BLK:           {fadt.sleepControlReg}")
      println(&"  X_GPE1_BLK:           {fadt.sleepStatusReg}")

    if fadt.hdr.revision >= 5 and fadt.fadtMinorVersion >= 1:
      println(&"  ARM_BOOT_ARCH:        {fadt.armBootArch:0>16b}b")

    if fadt.hdr.revision >= 6:
      println(&"  Hypervisor Vendor Identity: {fadt.hypervisorVendorIdentity: >16x}h")
