import std/strformat

import debug

const
  KernelDataSegment = 0x30
  KernelCodeSegment = 0x38

type
  InterruptFrame {.packed.} = object
    ds: uint64
    r15, r14, r13, r12, r11, r10, r09, r08: uint64
    rdi, rsi, rbp, rbx, rdx, rcx, rax: uint64
    vector: uint64
    errorCode: uint64
    rip, cs, eflags, esp, ss: uint64

proc handleInterrupt*(intFrame: InterruptFrame) {.cdecl, exportc.} =
  print(&" int[{intFrame.vector}] ")

proc isr00*(intFrame: pointer) {.asmNoStackFrame, cdecl.} =
  asm """
    cli

    pushq   0  # error code
    pushq   0  # interrupt vector

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
    mov     ax, ds
    push    ax

    # set kernel ds
    mov     ax, %0
    mov     ds, ax
    mov     es, ax
    mov     fs, ax
    mov     gs, ax

    call    handleInterrupt

    jmp     exitInterrupt
    :
    :"i"(`KernelDataSegment`)
  """

proc exitInterrupt*() {.asmNoStackFrame, exportc.} =
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
