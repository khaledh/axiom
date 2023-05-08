import std/strformat

import devices/console
import devices/cpu

type
  PageDirectoryPointerEntry {.packed.} = object
    present {.bitsize: 1.}: uint64     # bit      0
    write {.bitsize: 1.}: uint64       # bit      1
    supervisor {.bitsize: 1.}: uint64  # bit      2
    pwt {.bitsize: 1.}: uint64         # bit      3
    pcd {.bitsize: 1.}: uint64         # bit      4
    accessed {.bitsize: 1.}: uint64    # bit      5
    dirty {.bitsize: 1.}: uint64       # bit      6
    pageSize {.bitsize: 1.}: uint64    # bit      7
    global {.bitsize: 1.}: uint64      # bit      8
    ignored1 {.bitsize: 3.}: uint64    # bits 11: 9
    pat {.bitsize: 1.}: uint64         # bit     12
    reserved1 {.bitsize: 17.}: uint64  # bits 29:13
    phyAddress {.bitsize: 10.}: uint64 # bits 39:30
    reserved2 {.bitsize: 12.}: uint64  # bits 51:40
    ignored2 {.bitsize: 11.}: uint64   # bits 58:52
    protKey {.bitsize: 4.}: uint64     # bits 62:59
    xd {.bitsize: 1.}: uint64          # bit    63

proc showPagingTables*() =
  var cr3 = readCR3()
  let pml4addr = cr3 and 0xfffffff000'u64

  writeln("")
  writeln("Page Tables")
  writeln("")
  writeln(&"  PML4 Table Address = {pml4addr:.>16x}h")

  type PagingL4Entry {.packed.} = object
    present {.bitsize: 1.}: uint64     # bit      0
    write {.bitsize: 1.}: uint64       # bit      1
    supervisor {.bitsize: 1.}: uint64  # bit      2
    pwt {.bitsize: 1.}: uint64         # bit      3
    pcd {.bitsize: 1.}: uint64         # bit      4
    accessed {.bitsize: 1.}: uint64    # bit      5
    ignored1 {.bitsize: 1.}: uint64    # bit      6
    reserved1 {.bitsize: 1.}: uint64   # bit      7
    ignored2 {.bitsize: 4.}: uint64    # bits 11: 8
    phyAddress {.bitsize: 28.}: uint64 # bits 39:12
    reserved2 {.bitsize: 12.}: uint64  # bits 51:40
    ignored3 {.bitsize: 11.}: uint64   # bits 62:52
    xd {.bitsize: 1.}: uint64          # bit     63

  # A PML4 table comprises 512 64-bit entries (PML4Es)
  var pdpTableAddrs: seq[uint64]
  for i in 0..<512:
    let pml4e = cast[ptr PagingL4Entry](pml4addr + i.uint64 * 64)
    # If a paging-structure entry's P flag (bit 0) is 0 or if the entry sets any reserved bit,
    # the entry is used neither to reference another paging-structure entry nor to map a page.
    if pml4e.present == 1 and pml4e.reserved1 == 0 and pml4e.reserved2 == 0:
      write(&"  [{i:>3}]  ")
      let phyAddr = pml4e.phyAddress shl 12
      writeln(&"PhyAddress={phyAddr:0>8x}  Write={pml4e.write}  User/Supervisor={pml4e.supervisor}  Accessed={pml4e.accessed}  XD={pml4e.xd}")
      pdpTableAddrs &= phyAddr


  writeln("")
  writeln("  Page Directory Pointer Tables (showing first 10 only)")
  writeln("")
  for j, pdpTableAddr in pdpTableAddrs:
    # for i in 0..<512:
    writeln(&"  Page Directory Pointer Table [{j}]")
    for i in 0..<10:
      let pdpte = cast[ptr PageDirectoryPointerEntry](pdpTableAddr + i.uint64 * 64)
      if pdpte.present == 1 and pdpte.reserved1 == 0 and pdpte.reserved2 == 0:
        writeln(&"  [{i:>3}]  PhyAddress={pdpte.phyAddress shl 30:0>10x}  PS={pdpte.pageSize}  Write={pdpte.write}  User/Supervisor={pdpte.supervisor}  Accessed={pdpte.accessed}  Dirty={pdpte.dirty}  XD={pdpte.xd}")
    writeln("")
