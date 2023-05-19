import std/strformat

import devices/console
import devices/cpu
import debug
import idt

const
  KernelDataSegment = 0x30
  # KernelCodeSegment = 0x38

let
  exceptionMsg = [
    " #DE Divide Error ",
    " #DB Debug Exception ",
    " NMI Interrupt ",
    " #BP Breakpoint ",
    " #OF Overflow ",
    " #BR BOUND Range Exceeded ",
    " #UD Invalid Opcode (Undefined Opcode) ",
    " #NM Device Not Available (No Math Coprocessor) ",
    " #DF Double Fault ",
    " Coprocessor Segment Overrun ",
    " #TS Invalid TSS ",
    " #NP Segment Not Present ",
    " #SS Stack-Segment Fault ",
    " #GP General Protection ",
    " #PF Page Fault ",
    "",
    " #MF x87 FPU Floating-Point Error (Math Fault) ",
    " #AC Alignment Check ",
    " #MC Machine Check ",
    " #XF SIMD Floating-Point Exception ",
    " #VE Virtualization Exception ",
    " #CP Control Protection Exception ",
  ]

{.push stackTrace:off.}
proc handleInterrupt(intFrame: ptr InterruptFrame) {.cdecl, exportc.} =
  # debugln(&"Interrupt frame dddress: {cast[uint64](intFrame):016x}")
  debugln(&"Divide Error:\nInterrupt Frame:\n{intFrame}")

  if intFrame.vector < 22:
    putTextAt(exceptionMsg[intFrame.vector], 31, 79 - (intFrame.vector.int div 2), bgColor = DarkRed, fgColor = White)
    flush()
    halt()
{.pop.}

proc isrPrologue*() {.asmNoStackFrame, exportc.} =
  asm """
    # save all regs
    push    rax
    push    rcx
    push    rdx
    push    rbx
    push    rbp
    push    rsi
    push    rdi
    push    r8
    push    r9
    push    r10
    push    r11
    push    r12
    push    r13
    push    r14
    push    r15

    # save original data seg selector
    xor     rax, rax
    mov     ax, ds
    push    rax

    # set kernel ds
    mov     ax, %0
    mov     ds, ax
    mov     es, ax
    mov     fs, ax
    mov     gs, ax

    mov     rcx, rsp
    call    handleInterrupt

    jmp     isrEpilogue
    :
    :"i"(`KernelDataSegment`)
  """

proc isrEpilogue*() {.asmNoStackFrame, exportc.} =
  asm """
    # restore original data seg selectors
    pop     ax
    mov     ds, ax
    mov     es, ax
    mov     fs, ax
    mov     gs, ax

    # resore all regs
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     r11
    pop     r10
    pop     r9
    pop     r8
    pop     rdi
    pop     rsi
    pop     rbp
    pop     rbx
    pop     rdx
    pop     rcx
    pop     rax

    # pop interrupt vector and error code
    add     rsp, 16

    iretq
  """

proc isr00*(intFrame: ptr InterruptFrame) {.asmNoStackFrame, cdecl.} =
  asm """
    pushq   0  # error code
    pushq   0  # interrupt vector
    jmp     isrPrologue
  """

proc isr01*(intFrame: ptr InterruptFrame) {.asmNoStackFrame, cdecl.} =
  asm """
    pushq   0  # error code
    pushq   1  # interrupt vector
    jmp     isrPrologue
  """

proc isr02*(intFrame: ptr InterruptFrame) {.asmNoStackFrame, cdecl.} =
  asm """
    pushq   0  # error code
    pushq   2  # interrupt vector
    jmp     isrPrologue
  """

proc isr03*(intFrame: ptr InterruptFrame) {.asmNoStackFrame, cdecl.} =
  asm """
    pushq   0  # error code
    pushq   3  # interrupt vector
    jmp     isrPrologue
  """

proc isr04*(intFrame: ptr InterruptFrame) {.asmNoStackFrame, cdecl.} =
  asm """
    pushq   0  # error code
    pushq   4  # interrupt vector
    jmp     isrPrologue
  """

proc isr05*(intFrame: ptr InterruptFrame) {.asmNoStackFrame, cdecl.} =
  asm """
    pushq   0  # error code
    pushq   5  # interrupt vector
    jmp     isrPrologue
  """

proc isr06*(intFrame: ptr InterruptFrame) {.asmNoStackFrame, cdecl.} =
  asm """
    pushq   0  # error code
    pushq   6  # interrupt vector
    jmp     isrPrologue
  """

proc isr07*(intFrame: ptr InterruptFrame) {.asmNoStackFrame, cdecl.} =
  asm """
    pushq   0  # error code
    pushq   7  # interrupt vector
    jmp     isrPrologue
  """

proc isr08*(intFrame: ptr InterruptFrame) {.asmNoStackFrame, cdecl.} =
  asm """
    pushq   8  # interrupt vector
    jmp     isrPrologue
  """

proc isr09*(intFrame: ptr InterruptFrame) {.asmNoStackFrame, cdecl.} =
  asm """
    pushq   1  # error code
    pushq   9  # interrupt vector
    jmp     isrPrologue
  """

proc isr10*(intFrame: ptr InterruptFrame) {.asmNoStackFrame, cdecl.} =
  asm """
    pushq   10  # interrupt vector
    jmp     isrPrologue
  """

proc isr11*(intFrame: ptr InterruptFrame) {.asmNoStackFrame, cdecl.} =
  asm """
    pushq   11  # interrupt vector
    jmp     isrPrologue
  """

proc isr12*(intFrame: ptr InterruptFrame) {.asmNoStackFrame, cdecl.} =
  asm """
    pushq   12  # interrupt vector
    jmp     isrPrologue
  """

proc isr13*(intFrame: ptr InterruptFrame) {.asmNoStackFrame, cdecl.} =
  asm """
    pushq   13  # interrupt vector
    jmp     isrPrologue
  """

proc isr14*(intFrame: ptr InterruptFrame) {.asmNoStackFrame, cdecl.} =
  asm """
    pushq   14  # interrupt vector
    jmp     isrPrologue
  """

proc isr15*(intFrame: ptr InterruptFrame) {.asmNoStackFrame, cdecl.} =
  asm """
    pushq   1  # error code
    pushq   15  # interrupt vector
    jmp     isrPrologue
  """

proc isr16*(intFrame: ptr InterruptFrame) {.asmNoStackFrame, cdecl.} =
  asm """
    pushq   0  # error code
    pushq   16  # interrupt vector
    jmp     isrPrologue
  """

proc isr17*(intFrame: ptr InterruptFrame) {.asmNoStackFrame, cdecl.} =
  asm """
    pushq   17  # interrupt vector
    jmp     isrPrologue
  """

proc isr18*(intFrame: ptr InterruptFrame) {.asmNoStackFrame, cdecl.} =
  asm """
    pushq   0  # error code
    pushq   18  # interrupt vector
    jmp     isrPrologue
  """

proc isr19*(intFrame: ptr InterruptFrame) {.asmNoStackFrame, cdecl.} =
  asm """
    pushq   0  # error code
    pushq   19  # interrupt vector
    jmp     isrPrologue
  """

proc isr20*(intFrame: ptr InterruptFrame) {.asmNoStackFrame, cdecl.} =
  asm """
    pushq   1  # error code
    pushq   20  # interrupt vector
    jmp     isrPrologue
  """

proc isr21*(intFrame: ptr InterruptFrame) {.asmNoStackFrame, cdecl.} =
  asm """
    pushq   21  # interrupt vector
    jmp     isrPrologue
  """

proc init*() =
  setInterruptHandler(0, isr00)
  setInterruptHandler(1, isr01)
  setInterruptHandler(2, isr02)
  setInterruptHandler(3, isr03)
  setInterruptHandler(4, isr04)
  setInterruptHandler(5, isr05)
  setInterruptHandler(6, isr06)
  setInterruptHandler(7, isr07)
  setInterruptHandler(8, isr08)
  setInterruptHandler(9, isr09)
  setInterruptHandler(10, isr10)
  setInterruptHandler(11, isr11)
  setInterruptHandler(12, isr12)
  setInterruptHandler(13, isr13)
  setInterruptHandler(14, isr14)
  setInterruptHandler(15, isr15)
  setInterruptHandler(16, isr16)
  setInterruptHandler(17, isr17)
  setInterruptHandler(18, isr18)
  setInterruptHandler(19, isr19)
  setInterruptHandler(20, isr20)
  setInterruptHandler(21, isr21)
