import std/strformat

import ../devices/console
import ../devices/cpu
import ../lapic {.all.}

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
