import std/strformat

import ../boot/uefitypes
import devices/console
import devices/cpu

proc showMemoryMap*(bs: ptr EfiBootServices): uint =
  var mapSize: uint = 0
  var memoryMap: ptr UncheckedArray[EfiMemoryDescriptor]
  var mapKey: uint
  var descriptorSize: uint
  var descriptorVersion: uint32

  discard bs.getMemoryMap(addr mapSize, memoryMap, addr mapKey, addr descriptorSize,
      addr descriptorVersion)
  inc mapSize, 2 * descriptorSize.int
  discard bs.allocatePool(mtLoaderData, mapSize, cast[ptr pointer](addr memoryMap))
  discard bs.getMemoryMap(addr mapSize, memoryMap, addr mapKey, addr descriptorSize,
      addr descriptorVersion)

  writeln(&"Memory Map")
  let numDescriptors = mapSize div descriptorSize
  var desc = addr memoryMap[0]
  writeln("             start  size (kb)  type")
  for i in 0..<numDescriptors:
    let s = &"  [{i:>3}] {desc.physicalStart.uint:>10x}  {desc.numberOfPages.int64 * 4:>9}  {desc.type}"
    writeln(s)
    desc = cast[ptr EfiMemoryDescriptor](cast[uint](desc) + descriptorSize)

  result = mapKey

  # Get physical and linear address sizes
  var eax, ebx, ecx, edx: uint32
  eax = 0x80000008'u32
  cpuid(addr eax, addr ebx, addr ecx, addr edx)

  writeln("")
  writeln(&"  Physical Address Bits: {eax and 0xff}")
  writeln(&"  Linear Address Bits:   {(eax shr 8) and 0xff}")
