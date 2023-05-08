type
  InterruptDescriptor {.packed.} = object
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

var
  idtDesc: IdtDescriptor

proc init*() =
  asm """
    sidt %0
    :"=m"(`idtDesc`)
  """

proc setInterruptHandler*(vector: uint8, handler: proc (intFrame: pointer) {.cdecl.}) =
  let intDesc = cast[ptr InterruptDescriptor](idtDesc.base + vector.uint64 * 16)
  let handlerAddr = cast[uint64](handler)
  intDesc.offset00 = uint16(handlerAddr and 0xffff'u64)
  intDesc.offset16 = uint16(handlerAddr shr 16 and 0xffff'u64)
  intDesc.offset32 = uint32(handlerAddr shr 32)
