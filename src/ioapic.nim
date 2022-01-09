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

proc setIoApic*(id: uint8, address: uint32, gsiBase: uint32) =
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
