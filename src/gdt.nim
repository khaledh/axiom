import std/strformat

import debug

type
  SegmentDescriptor {.packed.} = object
    limit00: uint16
    base00:  uint16
    base16:  uint8
    `type`   {.bitsize: 4.}: uint8
    s        {.bitsize: 1.}: uint8
    dpl      {.bitsize: 2.}: uint8
    p        {.bitsize: 1.}: uint8
    limit16  {.bitsize: 4.}: uint8
    avl      {.bitsize: 1.}: uint8
    l        {.bitsize: 1.}: uint8
    d        {.bitsize: 1.}: uint8
    g        {.bitsize: 1.}: uint8
    base24:  uint8

  GdtDescriptor {.packed.} = object
    limit: uint16
    base: uint64

proc dumpGdt*() =
  var gdt_desc: GdtDescriptor

  asm """
    sgdt %0
    :"=m"(`gdt_desc`)
  """

  println("")
  println("Global Descritpor Table")
  println(&"  GDT Base  = {gdt_desc.base:0>16x}h")
  println(&"  GDT Limit = {gdt_desc.limit}")


  println("")
  println("  Segment Descriptors")
  for i in 0..8:
    let desc = cast[ptr SegmentDescriptor](gdt_desc.base + i.uint64 * 8)
    print(&"  [{i}] ")
    # print(&"{cast[uint64](desc[])}h ")
    if cast[uint64](desc[]) == 0:
      println("Null Descriptor")
      continue
  
    var segType = newStringOfCap(64)
    if (desc.type.uint8 and 0x8) == 0x8:
      segType &= "Code {Conforming: "
      segType &= (if (desc.type.uint8 and 0x4) == 0x4: "1" else: "0")
      segType &= ", Read: "
      segType &= (if (desc.type.uint8 and 0x2) == 0x2: "1" else: "0")
      segType &= ", Accessed:"
      segType &= (if (desc.type.uint8 and 0x1) == 0x1: "1" else: "0")
      segType &= "}  "
    else:
      segType &= "Data {Expand-down:"
      segType &= (if (desc.type.uint8 and 0x4) == 0x4: "1" else: "0")
      segType &= ", Write:"
      segType &= (if (desc.type.uint8 and 0x2) == 0x2: "1" else: "0")
      segType &= ", Accessed:"
      segType &= (if (desc.type.uint8 and 0x1) == 0x1: "1" else: "0")
      segType &= "}  "

    println(
      &"Selector={i * 8:0>2x}  " &
      &"P={desc.p}  " &
      &"S={desc.s}  " &
      &"DPL={desc.dpl}  " &
      &"Type={desc.type:0>4b} " & segType &
      &"D/B={desc.d}  " &
      &"L={desc.l}  " &
      &"G={desc.g}  " &
      &"Base={(desc.base24 shl 24) or (desc.base16 shl 16) or (desc.base00):x}  " &
      &"Limit={(desc.limit16.uint32 shl 16) or (desc.limit00):x}")
