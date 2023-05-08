import std/strformat

import devices/console
import devices/cpu

type
  IA32ApicBaseMsr* {.packed.} = object
    reserved1*   {.bitsize:  8.}: uint64
    isBsp*       {.bitsize:  1.}: uint64
    reserved2    {.bitsize:  2.}: uint64
    enabled*     {.bitsize:  1.}: uint64
    baseAddress* {.bitsize: 24.}: uint64
    reserved3    {.bitsize: 28.}: uint64

  LapicOffset* = enum
    LapicId            = 0x020
    LapicVersion       = 0x030
    TaskPriority       = 0x080
    ProcessorPriority  = 0x0a0
    Eoi                = 0x0b0
    LogicalDestination = 0x0d0
    DestinationFormat  = 0x0e0
    SpuriousInterrupt  = 0x0f0
    InService          = 0x100
    TriggerMode        = 0x180
    InterruptRequest   = 0x200
    ErrorStatus        = 0x280
    LvtCmci            = 0x2f0
    InterruptCommandLo = 0x300
    InterruptCommandHi = 0x310
    LvtTimer           = 0x320
    LvtThermalSensor   = 0x330
    LvtPerfMonCounters = 0x340
    LvtLint0           = 0x350
    LvtLint1           = 0x360
    LvtError           = 0x370
    TimerInitialCount  = 0x380
    TimerCurrentCount  = 0x390
    TimerDivideConfig  = 0x3e0

  LapicIdRegister* {.packed.} = object
    reserved {.bitsize: 24.}: uint32
    apicId*  {.bitsize:  8.}: uint32

  LapicVersionRegister* {.packed.} = object
    version*                       {.bitsize: 8.}: uint32
    reserved1                      {.bitsize: 8.}: uint32
    maxLvtEntry*                   {.bitsize: 8.}: uint32
    suppressEoiBroadcastSupported* {.bitsize: 1.}: uint32
    reserved2                      {.bitsize: 7.}: uint32

  SupriousInterruptVectorRegister* {.packed.} = object
    vector*     {.bitsize:  8.}: uint32
    apicEnable* {.bitsize:  1.}: uint32
    reserved    {.bitsize: 23.}: uint32

  ErrorStatusRegister* {.packed.} = object
    reserved1               {.bitsize:  4.}: uint8
    redirectableIpi*        {.bitsize:  1.}: uint8
    sendIllegalVector*      {.bitsize:  1.}: uint8
    recvIllegalVector*      {.bitsize:  1.}: uint8
    illegalRegisterAddress* {.bitsize:  1.}: uint8
    reserved2               {.bitsize: 24.}: uint32

  LvtTimerMode* {.size: 1.} = enum
    tmOneShot     = (0b00, "One-shot")
    tmPeriodic    = (0b01, "Periodic")
    tmTscDeadline = (0b11, "TSC-Deadline")

  LvtDeliveryMode* {.size: 1.} = enum
    dmFixed  = (0b000, "Fixed")
    dmSMI    = (0b010, "SMI")
    dmNMI    = (0b100, "NMI")
    dmINIT   = (0b101, "INIT")
    dmExtINT = (0b111, "ExtINT")

  LvtDeliveryStatus* {.size: 1.} = enum
    dsIdle        = "Idle"
    dsSendPending = "SendPending"

  LvtInterruptPolarity* {.size: 1.} = enum
    ipoActiveHigh = "ActiveHigh"
    ipoActiveLow  = "ActiveLow"

  LvtInterruptTriggerMode* {.size: 1.} = enum
    itrEdge  = "Edge"
    itrLevel = "Level"

  LvtRegister* {.packed.} = object
    vector*         {.bitsize:  8.}: uint8
    deliveryMode*   {.bitsize:  3.}: LvtDeliveryMode
    reserved1       {.bitsize:  1.}: uint8
    deliveryStatus* {.bitsize:  1.}: LvtDeliveryStatus
    intPolarity*    {.bitsize:  1.}: LvtInterruptPolarity
    remoteIrrFlag*  {.bitsize:  1.}: uint8
    intTriggerMode* {.bitsize:  1.}: LvtInterruptTriggerMode
    mask*           {.bitsize:  1.}: uint8
    reserved2       {.bitsize: 15.}: uint16

  LvtTimerRegister* {.packed.} = object
    vector*         {.bitsize:  8.}: uint8
    reserved1       {.bitsize:  4.}: uint8
    deliveryStatus* {.bitsize:  1.}: LvtDeliveryStatus
    reserved2       {.bitsize:  3.}: uint8
    mask*           {.bitsize:  1.}: uint8
    timerMode*      {.bitsize:  2.}: LvtTimerMode
    reserved3       {.bitsize: 13.}: uint16

var
  baseAddress: uint32

proc init*() =
  let baseMsr = cast[Ia32ApicBaseMsr](readMSR(0x1b))
  baseAddress = (baseMsr.baseAddress shl 12).uint32

proc readRegister(offset: int): uint32 =
  result = cast[ptr uint32](baseAddress.uint64 + offset.uint16)[]

proc readRegister(offset: LapicOffset): uint32 =
  readRegister(offset.int)

proc writeRegister(offset: int, value: uint32) =
  cast[ptr uint32](baseAddress.uint64 + offset.uint16)[] = value

proc writeRegister(offset: LapicOffset, value: uint32) =
  writeRegister(offset.int, value)

type
  LvtTimerDivisor* {.size: 4.} = enum
    DivideBy2   = 0b0000
    DivideBy4   = 0b0001
    DivideBy8   = 0b0010
    DivideBy16  = 0b0011
    DivideBy32  = 0b1000
    DivideBy64  = 0b1001
    DivideBy128 = 0b1010
    DivideBy1   = 0b1011

proc setTimer*(vector: uint8) =
  writeRegister(LapicOffset.TimerDivideConfig, DivideBy16.uint32)
  writeRegister(LapicOffset.TimerInitialCount, 150_000)
  writeRegister(LapicOffset.LvtTimer, vector.uint32 or (1 shl 17))

# End of Interrupt
proc eoi*() =
  writeRegister(LapicOffset.Eoi, 0)

proc show*() =
  let baseMsr = cast[Ia32ApicBaseMsr](readMSR(0x1b))

  writeln("")
  writeln("IA32_APIC_BASE MSR")
  writeln(&"  Is Bootstrap Processor (BSP) = {baseMsr.isBsp}")
  writeln(&"  APIC Global Enable           = {baseMsr.enabled}")
  writeln(&"  APIC Base Address            = {baseAddress:0>8x}")

  writeln("")
  writeln("Local APIC Registers")

  let lapicid = cast[LapicIdRegister](readRegister(LapicId))
  writeln("")
  writeln("  APIC ID Register")
  writeln(&"    APIC ID      = {lapicid.apicId}")

  let lapicVersion = cast[LapicVersionRegister](readRegister(LapicVersion))
  writeln("")
  writeln("  APIC Version Register")
  writeln(&"    Version                           = {lapicVersion.version:0>2x}h")
  writeln(&"    Max LVT Entry:                    = {lapicVersion.maxLvtEntry}")
  writeln(&"    Suppress EOI-broadcasts Supported = {lapicVersion.suppressEoiBroadcastSupported}")


  let svr = cast[SupriousInterruptVectorRegister](readRegister(SpuriousInterrupt))
  writeln("")
  writeln("  Spurious Interrupt Vector Register")
  writeln(&"    Vector       = {svr.vector:0>2x}h")
  writeln(&"    APIC Enabled = {svr.apicEnable}")


  let timer = cast[LvtTimerRegister](readRegister(LvtTimer))
  let lint0 = cast[LvtRegister](readRegister(LvtLint0))
  let lint1 = cast[LvtRegister](readRegister(LvtLint1))
  let error = cast[LvtRegister](readRegister(LvtError))

  writeln("")
  writeln("  LVT Registers")
  writeln(&"           Vector  DeliveryMode  DeliveryStatus  Polarity    TriggerMode  RemoteIRRFlag  Mask")
  writeln(&"    Timer  {timer.vector:0>2x}                    {timer.deliveryStatus}                                                    {timer.mask}     TimerMode: {timer.timerMode}")
  writeln(&"    LINT0  {lint0.vector:0>2x}      {lint0.deliveryMode: <12}  {lint0.deliveryStatus}            {lint0.intPolarity}  {lint0.intTriggerMode}         {lint0.remoteIrrFlag}              {lint0.mask}")
  writeln(&"    LINT1  {lint1.vector:0>2x}      {lint1.deliveryMode: <12}  {lint1.deliveryStatus}            {lint1.intPolarity}  {lint1.intTriggerMode}         {lint1.remoteIrrFlag}              {lint1.mask}")
  writeln(&"    Error  {error.vector:0>2x}                    {error.deliveryStatus}                                                    {error.mask}")
  if lapicVersion.maxLvtEntry >= 4:
    let perf = cast[LvtRegister](readRegister(LvtPerfMonCounters))
    writeln(&"    Perf   {perf.vector:0>2x}      {perf.deliveryMode: <12}  {perf.deliveryStatus}                                                    {perf.mask}")
  if lapicVersion.maxLvtEntry >= 5:
    let therm = cast[LvtRegister](readRegister(LvtThermalSensor))
    writeln(&"    Therm  {therm.vector:0>2x}      {therm.deliveryMode: <12}  {therm.deliveryStatus}                                                    {therm.mask}")
