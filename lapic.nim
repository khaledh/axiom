import cpu

type
  IA32ApicBaseMsr* {.packed.} = object
    reserved1*   {.bitsize:  8.}: uint64
    isBsp*       {.bitsize:  1.}: uint64
    reserved2    {.bitsize:  2.}: uint64
    enabled*     {.bitsize:  1.}: uint64
    baseAddress* {.bitsize: 24.}: uint64
    reserved3    {.bitsize: 28.}: uint64

let apicBaseMsr = cast[Ia32ApicBaseMsr](readMSR(0x1b))
let apicBaseAddress = apicBaseMsr.baseAddress shl 12

#[
  Local APIC Registers
]#

const
  LapicIdRegisterOffset*            = 0x020
  LapicVersionRegisterOffset*       = 0x030
  TaskPriorityRegisterOffset*       = 0x080
  ProcessorPriorityRegisterOffset*  = 0x0a0
  EoiRegisterOffset*                = 0x0b0
  LogicalDestinationRegisterOffset* = 0x0d0
  DestinationFormatRegisterOffset*  = 0x0e0
  SpuriousInterruptRegisterOffset*  = 0x0f0
  InServiceRegisterOffset*          = 0x100
  TriggerModeRegisterOffset*        = 0x180
  InterruptRequestRegisterOffset*   = 0x200
  ErrorStatusRegisterOffset*        = 0x280
  LvtCmciRegisterOffset*            = 0x2f0
  InterruptCommandRegisterLoOffset* = 0x300
  InterruptCommandRegisterHiOffset* = 0x310
  LvtTimerRegisterOffset*           = 0x320
  LvtThermalSensorRegisterOffset*   = 0x330
  LvtPerfMonCountersRegisterOffset* = 0x340
  LvtLint0RegisterOffset*           = 0x350
  LvtLint1RegisterOffset*           = 0x360
  LvtErrorRegisterOffset*           = 0x370
  TimerInitialCountRegisterOffset*  = 0x380
  TimerCurrentCountRegisterOffset*  = 0x390
  TimerDivideConfigRegisterOffset*  = 0x3e0

type
  LapicIdRegister* {.packed.} = object
    reserved     {.bitsize: 24.}: uint32
    apicId*      {.bitsize:  8.}: uint32

  LapicVersionRegister* {.packed.} = object
    version*     {.bitsize:  8.}: uint32
    reserved1    {.bitsize:  8.}: uint32
    maxLvtEntry* {.bitsize:  8.}: uint32
    suppressEoiBroadcastSupported*
                 {.bitsize:  8.}: uint32
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
  let temp = cast[ptr uint32](apicBaseAddress + offset.uint64)
  result = temp[]
