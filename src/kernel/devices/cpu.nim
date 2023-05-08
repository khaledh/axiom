#[
  CPU State
]#

proc idle*() {.cdecl.} =
  while true:
    asm """
      hlt
    """

proc halt*() {.inline.} =
  asm """
    cli
    hlt
  """

proc enableInterrupts*() {.inline.} =
  asm "sti"

proc disableInterrupts*() {.inline.} =
  asm "cli"

#[
  Control Registers
]#

proc readCR0*(): uint64 =
  asm """
    movq rax, cr0
    :"=a"(`result`)
  """

proc readCR3*(): uint64 =
  asm """
    movq rax, cr3
    :"=a"(`result`)
  """

proc readCR4*(): uint64 =
  asm """
    movq rax, cr4
    :"=a"(`result`)
  """

#[
  MSR
]#

proc readMSR*(ecx: uint32): uint64 =
  var eax, edx: uint32
  asm """
    rdmsr
    :"=a"(`eax`), "=d"(`edx`)
    :"c"(`ecx`)
  """
  result = (edx.uint64 shl 32) or eax

#[
  CPUID
]#

proc cpuid*(eax, ebx, ecx, edx: ptr uint32) =
  asm """
    cpuid
    :"=a"(*`eax`), "=b"(*`ebx`), "=c"(*`ecx`), "=d"(*`edx`)
    :"a"(*`eax`)
  """

type
  CpuIdFeaturesEcx {.packed.} = object
    sse3 {.bitsize: 1.}: uint32
    pclmulqdq {.bitsize: 1.}: uint32
    dtes64 {.bitsize: 1.}: uint32
    monitor {.bitsize: 1.}: uint32
    dscpl {.bitsize: 1.}: uint32
    vmx {.bitsize: 1.}: uint32
    smx {.bitsize: 1.}: uint32
    eist {.bitsize: 1.}: uint32
    tm2 {.bitsize: 1.}: uint32
    ssse3 {.bitsize: 1.}: uint32
    cnxtid {.bitsize: 1.}: uint32
    sdbg {.bitsize: 1.}: uint32
    fma {.bitsize: 1.}: uint32
    cmpxchg16b {.bitsize: 1.}: uint32
    xtprupdctl {.bitsize: 1.}: uint32
    pdcm {.bitsize: 1.}: uint32
    res1 {.bitsize: 1.}: uint32
    pcid {.bitsize: 1.}: uint32
    dca {.bitsize: 1.}: uint32
    sse41 {.bitsize: 1.}: uint32
    sse42 {.bitsize: 1.}: uint32
    x2apic {.bitsize: 1.}: uint32
    movbe {.bitsize: 1.}: uint32
    popcnt {.bitsize: 1.}: uint32
    tscdeadline {.bitsize: 1.}: uint32
    aesni {.bitsize: 1.}: uint32
    xsave {.bitsize: 1.}: uint32
    osxsave {.bitsize: 1.}: uint32
    avx {.bitsize: 1.}: uint32
    f16c {.bitsize: 1.}: uint32
    rdrand {.bitsize: 1.}: uint32
    res2 {.bitsize: 1.}: uint32

  CpuIdFeaturesEdx {.packed.} = object
    fpu {.bitsize: 1.}: uint32
    vme {.bitsize: 1.}: uint32
    de {.bitsize: 1.}: uint32
    pse {.bitsize: 1.}: uint32
    tsc {.bitsize: 1.}: uint32
    msr {.bitsize: 1.}: uint32
    pae {.bitsize: 1.}: uint32
    mce {.bitsize: 1.}: uint32
    cx8 {.bitsize: 1.}: uint32
    apic {.bitsize: 1.}: uint32
    res1 {.bitsize: 1.}: uint32
    sep {.bitsize: 1.}: uint32
    mtrr {.bitsize: 1.}: uint32
    pge {.bitsize: 1.}: uint32
    mca {.bitsize: 1.}: uint32
    cmov {.bitsize: 1.}: uint32
    pat {.bitsize: 1.}: uint32
    pse36 {.bitsize: 1.}: uint32
    psn {.bitsize: 1.}: uint32
    clfsh {.bitsize: 1.}: uint32
    res2 {.bitsize: 1.}: uint32
    ds {.bitsize: 1.}: uint32
    acpi {.bitsize: 1.}: uint32
    mmx {.bitsize: 1.}: uint32
    fxsr {.bitsize: 1.}: uint32
    sse {.bitsize: 1.}: uint32
    sse2 {.bitsize: 1.}: uint32
    ss {.bitsize: 1.}: uint32
    htt {.bitsize: 1.}: uint32
    tm {.bitsize: 1.}: uint32
    res3 {.bitsize: 1.}: uint32
    pbe {.bitsize: 1.}: uint32
