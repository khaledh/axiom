proc halt*() =
  asm """
    cli
    hlt
  """

proc shutdown*() =
  asm """
    mov ax, 0x2000
    mov dx, 0x604
    out dx, ax
  """

proc portOut8*(port: uint16, data: uint8) {.inline.}  =
  asm """
    out %0, %1
    :
    :"Nd"(`port`), "a"(`data`)
  """

proc portOut16*(port: uint16, data: uint16) {.inline.} =
  asm """
    out %0, %1
    :
    :"Nd"(`port`), "a"(`data`)
  """

proc portIn8*(port: uint16): uint8 {.inline.}  =
  asm """
    in %0, %1
    :"=a"(`result`)
    :"Nd"(`port`)
  """

proc portIn16*(port: uint16): uint16  {.inline.} =
  asm """
    in %0, %1
    :"=a"(`result`)
    :"Nd"(`port`)
  """

proc readCR0*(): uint64 =
  asm """
    movq rax, cr0
    :"=a"(`result`)
  """

proc readCR3*(): uint64 =
  asm """
    movq rax, cr3
    :"=a"(`result`)
  """

proc readCR4*(): uint64 =
  asm """
    movq rax, cr4
    :"=a"(`result`)
  """

proc readMSR*(ecx: uint32): uint64 =
  var eax, edx: uint32
  asm """
    rdmsr
    :"=a"(`eax`), "=d"(`edx`)
    :"c"(`ecx`)
  """
  result = (edx.uint64 shl 32) or eax

proc cpuid*(eax, ebx, ecx, edx: ptr uint32) =
  asm """
    cpuid
    :"=a"(*eax), "=b"(*ebx), "=c"(*ecx), "=d"(*edx)
    :"a"(*eax)
  """
