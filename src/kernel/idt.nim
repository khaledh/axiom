import std/strformat

type
  InterruptDescriptor* {.packed.} = object
    offset00: uint16
    selector: uint16
    ist       {.bitsize: 3.}: uint8
    zeros1    {.bitsize: 5.}: uint8
    `type`    {.bitsize: 4.}: uint8
    zeros2    {.bitsize: 1.}: uint8
    dpl       {.bitsize: 2.}: uint8
    present   {.bitsize: 1.}: uint8
    offset16: uint16
    offset32: uint32
    reserved: uint32

  IdtDescriptor {.packed.} = object
    limit: uint16
    base: uint64

  InterruptFrame* {.packed.} = object
    ds*: uint64
    r15*, r14*, r13*, r12*, r11*, r10*, r09*, r08*: uint64
    rdi*, rsi*, rbp*, rbx*, rdx*, rcx*, rax*: uint64
    vector*: uint64
    errorCode*: uint64
    rip*, cs*, rflags*, rsp*, ss: uint64

proc `$`*(intFrame: ptr InterruptFrame): string =
  result = &"ds: {intFrame.ds:0>4x}\n" &
    &"cs:rip: {intFrame.cs:0>4x}:{intFrame.rip:0>16x}\n" &
    &"ss:rsp: {intFrame.ss:0>4x}:{intFrame.rsp:0>16x}\n" &
    &"rflags: {intFrame.rflags:0>16x}\n" &
    &"vector: {intFrame.vector:0>2x}h, errorCode: {intFrame.errorCode}\n" &
    &"rbx: {intFrame.rax:0>16x}, rdx: {intFrame.rbx:0>16x}, rcx: {intFrame.rcx:0>16x}, rax: {intFrame.rdx:0>16x}\n" &
    &"rdi: {intFrame.rdi:0>16x}, rsi: {intFrame.rsi:0>16x}, rbp: {intFrame.rbp:0>16x}\n" &
    &"r11: {intFrame.r11:0>16x}, r10: {intFrame.r10:0>16x}, r09: {intFrame.r09:0>16x}, r08: {intFrame.r08:0>16x}\n" &
    &"r15: {intFrame.r15:0>16x}, r14: {intFrame.r14:0>16x}, r13: {intFrame.r13:0>16x}, r12: {intFrame.r12:0>16x}\n"

var
  idtDesc: IdtDescriptor

proc init*() =
  asm """
    sidt %0
    :"=m"(`idtDesc`)
  """

# proc setInterruptHandler*(vector: uint8, handler: proc (intFrame: pointer) {.cdecl.}) =
proc setInterruptHandler*(vector: uint8, handler: proc (intFrame: ptr InterruptFrame) {.cdecl.}) =
  let intDesc = cast[ptr InterruptDescriptor](idtDesc.base + vector.uint64 * 16)
  let handlerAddr = cast[uint64](handler)
  intDesc.offset00 = uint16(handlerAddr and 0xffff'u64)
  intDesc.offset16 = uint16(handlerAddr shr 16 and 0xffff'u64)
  intDesc.offset32 = uint32(handlerAddr shr 32)
