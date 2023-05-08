import std/strformat

import ../devices/console
import ../devices/cpu {.all.}

proc showControlRegisters*() =

  ##  CPU: CR0 register

  var cr0 = readCR0()

  writeln("")
  writeln(&"CR0 = {cr0:.>16x}h")
  writeln(&"  .PE          Protection Enable                   {cr0 shr  0 and 1}")
  writeln(&"  .MP          Monitor Coprocessor                 {cr0 shr  1 and 1}")
  writeln(&"  .EM          Emulation                           {cr0 shr  2 and 1}")
  writeln(&"  .TS          Task Switched                       {cr0 shr  3 and 1}")
  writeln(&"  .TS          Extension Type                      {cr0 shr  4 and 1}")
  writeln(&"  .NE          Numeric Error                       {cr0 shr  5 and 1}")
  writeln(&"  .WP          Write Protect                       {cr0 shr 16 and 1}")
  writeln(&"  .AM          Alignment Mask                      {cr0 shr 18 and 1}")
  writeln(&"  .NW          Not Write-through                   {cr0 shr 29 and 1}")
  writeln(&"  .CD          Cache Disable                       {cr0 shr 30 and 1}")
  writeln(&"  .PG          Paging                              {cr0 shr 31 and 1}")

  ##  CPU: CR4 register

  var cr4 = readCR4()

  writeln("")
  writeln(&"CR4 = {cr4:.>16x}h")
  writeln(&"  .VME         Virtual-8086 Mode Extensions        {cr4 shr  0 and 1}")
  writeln(&"  .PVI         Protected-Mode Virtual Interrupts   {cr4 shr  1 and 1}")
  writeln(&"  .TSD         Time Stamp Disable                  {cr4 shr  2 and 1}")
  writeln(&"  .DE          Debugging Extensions                {cr4 shr  3 and 1}")
  writeln(&"  .PSE         Page Size Extensions                {cr4 shr  4 and 1}")
  writeln(&"  .PAE         Physical Address Extension          {cr4 shr  5 and 1}")
  writeln(&"  .MCE         Machine-Check Enable                {cr4 shr  6 and 1}")
  writeln(&"  .PGE         Page Global Enable                  {cr4 shr  7 and 1}")
  writeln(&"  .PCE         Perf-Monitoring Counte Enable       {cr4 shr  8 and 1}")
  writeln(&"  .OSFXR       OS Support for FXSAVE & FXRSTOR     {cr4 shr  9 and 1}")
  writeln(&"  .OSXMMEXCPT  OS Support for Unmasked SIMD")
  writeln(&"               Floating-Point Exceptions           {cr4 shr 10 and 1}")
  writeln(&"  .UMIP        User-Mode Instruction Prevention    {cr4 shr 11 and 1}")
  writeln(&"  .LA57        57-bit linear addresses             {cr4 shr 12 and 1}")
  writeln(&"  .VMXE        VMX-Enable Bit                      {cr4 shr 13 and 1}")
  writeln(&"  .SMXE        SMX-Enable Bit                      {cr4 shr 14 and 1}")
  writeln(&"  .FSGSBASE    FSGSBASE-Enable Bit                 {cr4 shr 16 and 1}")
  writeln(&"  .PCIDE       PCID-Enable Bit                     {cr4 shr 17 and 1}")
  writeln(&"  .OSXSAVE     XSAVE and Processor Extended State-")
  writeln(&"               Enable Bit                          {cr4 shr 18 and 1}")
  writeln(&"  .KL          Key-Locker-Enable Bit               {cr4 shr 19 and 1}")
  writeln(&"  .SMEP        SMEP-Enable Bit                     {cr4 shr 20 and 1}")
  writeln(&"  .SMAP        SMAP-Enable Bit                     {cr4 shr 21 and 1}")
  writeln(&"  .PKE         Enable protection keys for user-")
  writeln(&"               mode pages                          {cr4 shr 22 and 1}")
  writeln(&"  .CET         Control-flow Enforcement Technology {cr4 shr 23 and 1}")
  writeln(&"  .PKS         Enable protection keys for")
  writeln(&"               supervisor-mode pages               {cr4 shr 24 and 1}")

  ##  CPU: IA32_EFER register

  var efer = readMSR(0xC0000080'u32) # EFER
  writeln("")
  writeln(&"IA32_EFER = {efer:.>16x}h")
  writeln(&"  .SCE         SYSCALL Enable                      {efer shr  0 and 1}")
  writeln(&"  .LME         IA-32e Mode Enable                  {efer shr  8 and 1}")
  writeln(&"  .LMA         IA-32e Mode Active                  {efer shr 10 and 1}")
  writeln(&"  .NXE         Execute Disable Bit Enable          {efer shr 11 and 1}")


proc showCpuid*() =
  var eax, ebx, ecx, edx: uint32

  ## Function 0

  eax = 0
  cpuid(addr eax, addr ebx, addr ecx, addr edx)

  proc registerToString(reg: uint32): string =
    result &= cast[char](reg shr 00)
    result &= cast[char](reg shr 08)
    result &= cast[char](reg shr 16)
    result &= cast[char](reg shr 24)

  var vendor: string
  vendor &= registerToString(ebx)
  vendor &= registerToString(edx)
  vendor &= registerToString(ecx)

  writeln("")
  writeln("CPUID")
  writeln(&"  Vendor:                    {vendor}")
  writeln(&"  Highest Basic Function:    {eax:0>2x}h")

  ## Extended Function 0x80000000

  eax = 0x80000000'u32
  cpuid(addr eax, addr ebx, addr ecx, addr edx)
  writeln(&"  Highest Extended Function: {eax:0>2x}h")

  ## Function 1

  eax = 1
  cpuid(addr eax, addr ebx, addr ecx, addr edx)

  var procType = (eax shr 12) and 0x3
  var family = eax shr 8 and 0xf
  if family == 0xf:
    family = (eax shr 20 and 0xff) + family
  var model = eax shr 4 and 0xf
  if family in [0x6.uint32, 0xf]:
    model += (eax shr 16 and 0xf) shl 4
  var stepping = eax and 0xf

  writeln("")
  writeln(&"  Processor Type:            {procType:0>2x}h")
  writeln(&"  Family ID:                 {family:0>2x}h")
  writeln(&"  Model ID:                  {model:0>2x}h")
  writeln(&"  Stepping ID:               {stepping:1x}h")

  writeln("")
  writeln(&"  Feature Info in ECX: {cast[CpuIdFeaturesEcx](ecx)}")
  writeln(&"  Feature Info in EDX: {cast[CpuIdFeaturesEdx](edx)}")
