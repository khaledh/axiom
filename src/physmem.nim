import std/strformat

import debug
import uefitypes

proc dumpMemoryMap*(bs: ptr EfiBootServices): uint =
  var mapSize: uint = 0
  var memoryMap: ptr UncheckedArray[EfiMemoryDescriptor]
  var mapKey: uint
  var descriptorSize: uint
  var descriptorVersion: uint32

  discard bs.getMemoryMap(addr mapSize, memoryMap, addr mapKey, addr descriptorSize, addr descriptorVersion)
  inc mapSize, 2 * descriptorSize.int
  discard bs.allocatePool(mtLoaderData, mapSize, cast[ptr pointer](addr memoryMap))
  discard bs.getMemoryMap(addr mapSize, memoryMap, addr mapKey, addr descriptorSize, addr descriptorVersion)

  println(&"Memory Map")
  let numDescriptors = mapSize div descriptorSize
  var desc = addr memoryMap[0]
  println("             start  size (kb)  type")
  for i in 0..<numDescriptors:
    let s = &"  [{i:>3}] {desc.physicalStart.uint:>10x}  {desc.numberOfPages.int64 * 4:>9}  {desc.type}"
    println(s)
    desc = cast[ptr EfiMemoryDescriptor](cast[uint](desc) + descriptorSize)
  
  result = mapKey
