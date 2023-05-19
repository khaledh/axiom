import std/importutils
import std/strformat

import ../devices/console
import ../idt {.all.}

privateAccess(InterruptDescriptor)
privateAccess(IdtDescriptor)

proc showIdt*() =
  writeln("")
  writeln("IDT (Interrupt Descritpor Table)")
  writeln(&"  IDT Base  = {idt_desc.base:0>16x}h")
  writeln(&"  IDT Limit = {idt_desc.limit}")

  writeln("")
  writeln("  Interrupt Descriptors")
  for i in 0..255:
    let desc = cast[ptr InterruptDescriptor](idt_desc.base + i.uint64 * 16)
    if (desc.present == 0):
      continue

    # if i == 0x20:  # Timer
    #   writeln("  Setting timer interrupt handler (0x20)")
    #   let timerIntHandlerAddr = cast[uint64](timerInterruptHandler)
    #   desc.offset00 = uint16(timerIntHandlerAddr and 0xffff'u64)
    #   desc.offset16 = uint16(timerIntHandlerAddr shr 16 and 0xffff'u64)
    #   desc.offset32 = uint32(timerIntHandlerAddr shr 32)

    if i in 0..255:
      if i > 33 and i != 255:
        continue
      if i > 33:
        writeln("  ...")
      write(&"  [{i:>3}] ")
      # write(&"{cast[ptr uint64](cast[uint64](desc) + 8)[]}h")
      # writeln(&"{cast[uint64](desc[])} ")
      let descType = case desc.type
        of 0b0010: "LDT"
        of 0b1001: "64-bit TSS (Available)"
        of 0b1011: "64-bit TSS (Busy)"
        of 0b1100: "64-bit Call Gate"
        of 0b1110: "64-bit Interrupt Gate"
        of 0b1111: "64-bit Trap Gate"
        else: ""

      write(descType)

      write(&"  Selector={desc.selector:0>2x}")
      writeln(&"  Offset={(desc.offset32.uint64 shl 32) or (desc.offset16.uint64 shl 16) or (desc.offset00):x}h")
