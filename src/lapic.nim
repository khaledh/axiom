import std/strformat

import cpu
import debug

type
  IA32ApicBaseMsr* {.packed.} = object
    reserved1*   {.bitsize:  8.}: uint64
    isBsp*       {.bitsize:  1.}: uint64
    reserved2    {.bitsize:  2.}: uint64
    enabled*     {.bitsize:  1.}: uint64
    baseAddress* {.bitsize: 24.}: uint64
    reserved3    {.bitsize: 28.}: uint64

var lapicBaseMsr*: Ia32ApicBaseMsr
var lapicBaseAddress*: uint32

proc lapicLoadBaseAddress*() =
  lapicBaseMsr = cast[Ia32ApicBaseMsr](readMSR(0x1b))
  lapicBaseAddress = (lapicBaseMsr.baseAddress shl 12).uint32


#[
  Local APIC Registers
]#

type
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

type
  LapicIdRegister* {.packed.} = object
    reserved     {.bitsize: 24.}: uint32
    apicId*      {.bitsize:  8.}: uint32

  LapicVersionRegister* {.packed.} = object
    version*     {.bitsize:  8.}: uint32
    reserved1    {.bitsize:  8.}: uint32
    maxLvtEntry* {.bitsize:  8.}: uint32
    suppressEoiBroadcastSupported*
                 {.bitsize:  1.}: uint32
    reserved2    {.bitsize:  7.}: uint32

  SupriousInterruptVectorRegister* {.packed.} = object
    vector*      {.bitsize:  8.}: uint32
    apicEnable*  {.bitsize:  1.}: uint32
    reserved     {.bitsize: 23.}: uint32

  ErrorStatusRegister* {.packed.} = object
    reserved1               {.bitsize:  4.}: uint8
    redirectableIpi*        {.bitsize:  1.}: uint8
    sendIllegalVector*      {.bitsize:  1.}: uint8
    recvIllegalVector*      {.bitsize:  1.}: uint8
    illegalRegisterAddress* {.bitsize:  1.}: uint8
    reserved2               {.bitsize: 24.}: uint32

type
  LvtTimerMode* {.size: 1.} = enum
    tmOneShot     = (0b00, "One-shot")
    tmPeriodic    = (0b01, "Periodic")
    tmTscDeadline = (0b11, "TSC-Deadline")

  LvtDeliveryMode* {.size: 1.} = enum
    dmFixed       = (0b000, "Fixed")
    dmSMI         = (0b010, "SMI")
    dmNMI         = (0b100, "NMI")
    dmINIT        = (0b101, "INIT")
    dmExtINT      = (0b111, "ExtINT")

  LvtDeliveryStatus* {.size: 1.} = enum
    dsIdle        = "Idle"
    dsSendPending = "SendPending"

  LvtInterruptPolarity* {.size: 1.} = enum
    ipoActiveHigh = "ActiveHigh"
    ipoActiveLow  = "ActiveLow"

  LvtInterruptTriggerMode* {.size: 1.} = enum
    itrEdge       = "Edge"
    itrLevel      = "Level"

type
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


proc lapicRead*(offset: int): uint32 =
  result = cast[ptr uint32](lapicBaseAddress + offset.uint16)[]

proc lapicRead*(offset: LapicOffset): uint32 =
  lapicRead(offset.int)

proc lapicWrite*(offset: int, value: uint32) =
  cast[ptr uint32](lapicBaseAddress + offset.uint16)[] = value

proc lapicWrite*(offset: LapicOffset, value: uint32) =
  lapicWrite(offset.int, value)


proc dumpLapic*() =
  println("")
  println("IA32_APIC_BASE MSR")
  println(&"  Is Bootstrap Processor (BSP) = {lapicBaseMsr.isBsp}")
  println(&"  APIC Global Enable           = {lapicBaseMsr.enabled}")
  println(&"  APIC Base Address            = {lapicBaseAddress:0>8x}")

  println("")
  println("Local APIC Registers")

  let lapicid = cast[LapicIdRegister](lapicRead(LapicOffset.LapicId))
  println("")
  println("  APIC ID Register")
  println(&"    APIC ID      = {lapicid.apicId}")

  let lapicVersion = cast[LapicVersionRegister](lapicRead(0x30))
  println("")
  println("  APIC Version Register")
  println(&"    Version                           = {lapicVersion.version:0>2x}h")
  println(&"    Max LVT Entry:                    = {lapicVersion.maxLvtEntry}")
  println(&"    Suppress EOI-broadcasts Supported = {lapicVersion.suppressEoiBroadcastSupported}")


  let svr = cast[SupriousInterruptVectorRegister](lapicRead(LapicOffset.SpuriousInterrupt))
  println("")
  println("  Spurious Interrupt Vector Register")
  println(&"    Vector       = {svr.vector:0>2x}h")
  println(&"    APIC Enabled = {svr.apicEnable}")


  let timer = cast[LvtTimerRegister](lapicRead(LapicOffset.LvtTimer))
  let lint0 = cast[LvtRegister](lapicRead(LapicOffset.LvtLint0))
  let lint1 = cast[LvtRegister](lapicRead(LapicOffset.LvtLint1))
  let error = cast[LvtRegister](lapicRead(LapicOffset.LvtError))

  println("")
  println("  LVT Registers")
  println(&"           Vector  DeliveryMode  DeliveryStatus  Polarity    TriggerMode  RemoteIRRFlag  Mask")
  println(&"    Timer  {timer.vector:0>2x}                    {timer.deliveryStatus}                                                    {timer.mask}     TimerMode: {timer.timerMode}")
  println(&"    LINT0  {lint0.vector:0>2x}      {lint0.deliveryMode: <12}  {lint0.deliveryStatus}            {lint0.intPolarity}  {lint0.intTriggerMode}         {lint0.remoteIrrFlag}              {lint0.mask}")
  println(&"    LINT1  {lint1.vector:0>2x}      {lint1.deliveryMode: <12}  {lint1.deliveryStatus}            {lint1.intPolarity}  {lint1.intTriggerMode}         {lint1.remoteIrrFlag}              {lint1.mask}")
  println(&"    Error  {error.vector:0>2x}                    {error.deliveryStatus}                                                    {error.mask}")
  if lapicVersion.maxLvtEntry >= 4:
    let perf = cast[LvtRegister](lapicRead(0x340))
    println(&"    Perf   {perf.vector:0>2x}      {perf.deliveryMode: <12}  {perf.deliveryStatus}                                                    {perf.mask}")
  if lapicVersion.maxLvtEntry >= 5:
    let therm = cast[LvtRegister](lapicRead(0x330))
    println(&"    Therm  {therm.vector:0>2x}      {therm.deliveryMode: <12}  {therm.deliveryStatus}                                                    {therm.mask}")


proc lapicSetTimer*(vector: uint8) =
  lapicWrite(LapicOffset.TimerDivideConfig, 0b1001) # Divide by 64
  lapicWrite(LapicOffset.TimerInitialCount, 4375000)
  lapicWrite(LapicOffset.LvtTimer, vector.uint32 or (0x01 shl 17))
