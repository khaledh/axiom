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
import std/sugar
import std/tables

import boot/[uefi, uefi/simpletext, uefi/firmware, uefitypes]
import kernel/debug
import kernel/acpi/[fadt, rsdp]
import kernel/devices/console
import kernel/devices/cpu
import kernel/devices/keyboard
import kernel/devices/rtc
import kernel/inspect/[madt, xsdt]
import kernel/inspect/ahci
import kernel/inspect/cpu
import kernel/inspect/gui
import kernel/inspect/idt
import kernel/inspect/ioapic
import kernel/inspect/lapic
import kernel/inspect/pci
import kernel/inspect/smbios
import kernel/inspect/threads
import kernel/gdt
import kernel/paging
import kernel/physmem
import kernel/system
import kernel/thread

var
  sysTable: ptr EfiSystemTable
  lastLine: string
  spinnerThread: Thread

proc init*(st: ptr EfiSystemTable) =
  sysTable = st

proc showStatusBar() =
  putTextAt(" ".repeat(158), 62, 0, bgColor = LighterBlue)
  putTextAt("Axiom OS 0.1.0", 62, 0, fgColor = DarkOrange, bgColor = LighterBlue)


proc spinner() {.cdecl.} =
  const spinner = ['-', '\\', '|', '/']
  var index = 0

  while true:
      putCharAt(spinner[index mod len(spinner)], 0, 157)
      inc index
      sleep(50)

proc clearSpinner() =
  putCharAt(' ', 0, 157)

proc dispatchCommand(cmd: string)

proc readLine(): string =
  debugln("shell: reading line")
  var evt = console.readKeyEvent()
  if evt.eventType == KeyDown and evt.ch == '\x18':
    # up arrow
    result = lastLine
    writeln(result)

  while true:
    debugln(&"shell: got key event: {evt}")
    if evt.eventType == KeyDown and evt.ch != '\0':
      if evt.ch == '\n':
        debugln("shell: got newline")
        lastLine = result
        break
      elif evt.ch == '\b':
        debugln("shell: got backspace")
        if len(result) > 0:
          result.delete(result.len-1 .. result.len-1)
          write(&"{evt.ch}")
      elif evt.ch == '\x1b':
        debugln("shell: got esc")
        for i in 0 ..< len(result):
          write("\b")
        result = ""
      else:
        debugln(&"shell: got character {evt.ch:02x}h")
        result &= evt.ch
        write(&"{evt.ch}")
    elif evt.eventType == KeyUp:
      debugln("shell: got key up")
    evt = console.readKeyEvent()

proc start*() {.cdecl.} =
  while true:
    # showStatusBar()
    write("] ")
    let line = readLine()
    writeln("")
    dispatchCommand(line)
    writeln("")

proc showHelp() {.cdecl.} =
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
  writeln("Kernel")
  writeln("  threads       Show kernel threads")

  writeln("")
  writeln("Shell")
  writeln("  clear         Clear the screen")
  writeln("  busy          Simulate busy thread")
  writeln("  spinner on    Start the spinner thread")
  writeln("  spinner off   Stop the spinner thread")

  writeln("")
  writeln("Other")
  writeln("  about         Information about Axiom OS")
  writeln("  ping          Respond with 'pong'")
  writeln("  date          Show current date and time")
  writeln("  font          Show font information")
  writeln("  halt          Halt without shutting down")
  writeln("  shutdown      Shutdown the system")
  writeln("  bye           Alias to 'shutdown'")

proc showAbout() {.cdecl.} =
  writeln("Axiom OS 0.1.0")
  writeln("Copyright (c) 2022-2023 Khaled Hammouda <khaledh@gmail.com>")

let commands = {
  "help": showHelp,
  "about": showAbout,
  "ping": () {.cdecl.} => writeln("pong")
}.toTable

proc dispatchCommand(cmd: string) =
  debugln(&"shell: dispatching command: {cmd}")

  if commands.hasKey(cmd):
    var th = createThread(commands[cmd], name=cmd)
    th.start()
    th.join()
    return

  case cmd:
  of "":
    discard

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
    ioapic.show()

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
    write("Halt")
    flush()
    halt()

  of "threads":
    showThreads()
  
  of "clear":
    clear()

  of "busy":
    for i in 0 .. 500_000_000:
      if i mod 10_000_000 == 0:
        write(".")

  of "spinner":
    writeln("usage: spinner on|off")

  of "spinner on":
    if spinnerThread != nil:
      writeln("shell: spinner thread already running")
    else:
      spinnerThread = createThread(spinner, name = "spinner")
      debugln("shell: starting spinner thread")
      spinnerThread.start()

  of "spinner off":
    if spinnerThread == nil:
      writeln("shell: spinner thread not running")
    else:
      debugln("shell: stopping spinner thread")
      spinnerThread.stop()
      spinnerThread = nil
      clearSpinner()

  of "date":
    writeln($getDateTime())

  else:
    writeln("Unknown command")
