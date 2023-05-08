#[
    Shell: interactively processes commands from the user

    Responsibilities:
    - for valid commands, dispatches the command to the appropriate handler
    - for invalid commands, show an error message

    Requires:
    - a way to receive input from keyboard
    - a way to send output to the screen

    Provides
    - shell
]#

import std/[strformat, strutils]

import boot/[uefi, uefi/simpletext, uefi/firmware, uefitypes]
import kernel/acpi/[fadt, madt, rsdp, xsdt]
import kernel/devices/cpu
import kernel/devices/console
import kernel/devices/keyboard
import kernel/inspect/ahci
import kernel/inspect/cpu
import kernel/inspect/pci
import kernel/inspect/smbios
import kernel/gdt
import kernel/idt
import kernel/ioapic
import kernel/lapic
import kernel/paging
import kernel/physmem
import kernel/system

var
  sysTable: ptr EfiSystemTable
  lineBuffer: string

proc init*(st: ptr EfiSystemTable) =
  sysTable = st

proc start*() {.cdecl.} =

  # loop
  writeln("] ")

    # read input

    # find handler

    # dispatch

  discard

proc dispatchCommand(cmd: string)

proc keyHandler*(evt: KeyEvent) =
  if evt.eventType == KeyDown and evt.ch != '\0':
    if evt.ch == '\n':
      writeln("")
      dispatchCommand(lineBuffer)
      writeln("")
      write("] ")
      lineBuffer = ""
    elif evt.ch == '\b':
      lineBuffer.delete(len(lineBuffer)-1 .. len(lineBuffer)-1)
      write(&"{evt.ch}")
    else:
      lineBuffer &= evt.ch
      write(&"{evt.ch}")

proc showHelp() =
  writeln("")
  writeln("UEFI")
  writeln("  uefi fw       Show UEFI firmware version")
  writeln("  uefi memory   Show UEFI memory map")
  writeln("  uefi tables   Show UEFI config table")
  # writeln("  uefi text     Show UEFI text modes")

  writeln("")
  writeln("SMBIOS")
  writeln("  smbios        Show SMBIOS information")

  writeln("")
  writeln("CPU")
  writeln("  cpuid         Show CPUID information")
  writeln("  ctlreg        Show CPU control registers")
  writeln("  gdt           Show GDT (Global Descriptor Table)")
  writeln("  idt           Show IDT (Interrupt Descriptor Table)")
  writeln("  paging        Show paging table")

  writeln("")
  writeln("ACPI")
  writeln("  rsdp          Show ACPI RSDP (Root System Description Pointer)")
  writeln("  xsdt          Show ACPI XSDT (eXtended System Description Table)")
  writeln("  fadt          Show ACPI FADT (Fixed ACPI Description Table)")
  writeln("  madt          Show ACPI MADT (Multiple APIC Description Table)")

  writeln("")
  writeln("Interrupt Controllers")
  writeln("  lapic         Show Local APIC information")
  writeln("  iopic         Show I/O APIC information")

  writeln("")
  writeln("PCI Bus")
  writeln("  pci           Show PCI configuration")

  writeln("")
  writeln("Storage")
  writeln("  ahci          Show AHCI configuration")

  writeln("")
  writeln("Other")
  writeln("  about         Information about Axiom OS")
  writeln("  ping          Respond with 'pong'")
  writeln("  font          Show font information")
  writeln("  halt          Halt without shutting down")
  writeln("  shutdown      Shutdown the system")
  writeln("  bye           Alias to 'shutdown'")

proc showAbout() =
  writeln("Axiom OS 0.1.0")
  writeln("Copyright (c) 2022-2023 Khaled Hammouda <khaledh@gmail.com>")

proc dispatchCommand(cmd: string) =
  case cmd:
  of "":
    discard
  of "help":
    showHelp()
  of "about":
    showAbout()
  of "ping":
    writeln("pong")
  of "rsdp":
    showRsdp()
  of "xsdt":
    showXsdt()
  of "fadt":
    showFadt()
  of "madt":
    showMadt()
  of "idt":
    showIdt()
  of "gdt":
    showGdt()
  of "lapic":
    lapic.show()
  of "ioapic":
    ioapic.show(ioapic0)
  of "pci":
    showPciConfig()
  of "ahci":
    showAhci(bus = 0, dev = 0x1f, fn = 2, sysTable.bootServices)
  of "font":
    showFont()
  of "cpuid":
    showCpuid()
  of "ctlreg":
    showControlRegisters()
  of "uefi memory":
    discard showMemoryMap(sysTable.bootServices)
  of "paging":
    showPagingTables()
  of "uefi fw":
    showFirmwareVersion(sysTable)
  of "uefi tables":
    showUefiConfigTables(sysTable)
  of "uefi text":
    showSimpletext(sysTable.conOut)
  of "smbios":
    showSmbios(sysTable)
  of "shutdown", "bye":
    writeln("Shutting down")
    shutdown()
  of "halt":
    writeln("Halt")
    halt()
  else:
    writeln("Uknown command")
