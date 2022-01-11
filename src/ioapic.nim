import std/strformat

import debug

type
  IoapicIdRegister* {.packed.} = object
    reserved1        {.bitsize: 24.}: uint32
    id*              {.bitsize:  4.}: uint32
    reserved2        {.bitsize: 24.}: uint32
  
  IoapicVersionRegister* {.packed.} = object
    version*         {.bitsize:  8.}: uint32
    reserved1        {.bitsize:  8.}: uint32
    maxRedirEntry*   {.bitsize:  8.}: uint32
    reserved2        {.bitsize:  8.}: uint32

  IoapicRedirectionEntry* {.packed.} = object
    vector*          {.bitsize:  8.}: uint64
    deliveryMode*    {.bitsize:  3.}: uint64
    destinationMode* {.bitsize:  1.}: uint64
    deliveryStatus*  {.bitsize:  1.}: uint64
    polarity*        {.bitsize:  1.}: uint64
    remoteIrr*       {.bitsize:  1.}: uint64
    triggerMode*     {.bitsize:  1.}: uint64
    mask*            {.bitsize:  1.}: uint64
    reserved         {.bitsize: 39.}: uint64
    destination*     {.bitsize:  8.}: uint64

var ioapicId: uint8
var ioapicRegisterSelect: ptr uint32
var ioapicRegisterData: ptr uint32
var ioapicGsiBase: uint32

proc setIoapic*(id: uint8, address: uint32, gsiBase: uint32) =
  ioApicId = id
  ioapicRegisterSelect = cast[ptr uint32](address)
  ioapicRegisterData = cast[ptr uint32](address + 0x10)
  ioApicGsiBase = gsiBase

proc ioapicRead*(index: int): uint32 =
  ioapicRegisterSelect[] = index.uint32
  result = ioapicRegisterData[]

proc ioapicWrite*(index: uint32, value: uint32) =
  ioapicRegisterSelect[] = index
  ioapicRegisterData[] = value

proc dumpIoapic*() =
  println("")
  println("I/O APIC")

  # set keyboard interrupt: interrupt input 1 => vector 33h
  let kbdRedirEntry = IoapicRedirectionEntry(
    vector           : 0x33,
    deliveryMode     : 0,  # Fixed
    destinationMode  : 0,  # Physical
    deliveryStatus   : 0,
    polarity         : 0,  # ActiveHigh
    remoteIrr        : 0,
    triggerMode      : 0,  # Edge
    mask             : 0,  # Enabled
    destination      : 0,  # Lapic ID 0
  )
  ioapicWrite(0x12, cast[uint32](cast[uint64](kbdRedirEntry) and 0xffff))
  ioapicWrite(0x13, cast[uint32](cast[uint64](kbdRedirEntry) shr 32))

  let ioapicId = cast[IoApicIdRegister](ioapicRead(0))
  let ioapicVer = cast[IoApicVersionRegister](ioapicRead(1))
  println(&"  IOAPICID  = {ioapicId.id}")
  println(&"  IOAPICVER = Version: {ioapicVer.version:0>2x}h, MaxRedirectionEntry: {ioapicVer.maxRedirEntry}")
  println("  IOREDTBL")
  println("       Vector  DeliveryMode  DestinationMode  Destination  Polarity  TriggerMode  DeliveryStatus  RemoteIRR  Mask")
  for i in 0..ioapicVer.maxRedirEntry:
    let lo = ioapicRead(2*i.int + 0x10)
    let hi = ioapicRead(2*i.int + 0x11)
    let entry = cast[IoapicRedirectionEntry](hi.uint64 shl 32 or lo)
    print(&"  [{i: >2}] {entry.vector:0>2x}h     {entry.deliveryMode: <12}  {entry.destinationMode: <15}  {entry.destination: <11}")
    println(&"  {entry.polarity: <8}  {entry.triggerMode: <11}  {entry.deliveryStatus: <14}  {entry.remoteIrr: <9}  {entry.mask}")
