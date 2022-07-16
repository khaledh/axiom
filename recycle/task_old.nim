import std/strformat

import cpu
import debug

const
  MaxTasks = 4
  StackSize = 1024

type
  Stack = ref array[StackSize, uint64]

#######################################################################
#                              tasks (old)                            #
#######################################################################

# type
#   Task* = object
#     id: uint
#     rax: uint64
#     rbx: uint64
#     rcx: uint64
#     rdx: uint64
#     rsi: uint64
#     rdi: uint64
#     rbp: uint64
#     rsp: pointer
#     rip: pointer
#     rflags: uint64

# var
#   currId: uint
#   stacks: array[MaxTasks, array[StackSize, byte]]

# proc initTasks*() =
#     currId = 0

# proc newTask*(entryPoint: pointer): Task =
#     let stack = stacks[currId]
#     let t = Task(
#         id: currId,
#         rip: entryPoint,
#         rsp: unsafeAddr stack[StackSize],
#     )
#     inc(currId)
#     return t

#######################################################################
#                              tasks                                  #
#######################################################################

type
  Task* = ref object
    rsp: pointer
    id: uint64
    # rax: uint64
    # rbx: uint64
    # rcx: uint64
    # rdx: uint64
    # rsi: uint64
    # rdi: uint64
    # rbp: uint64
    # rip: pointer
    rflags: uint64


var
  nextAvailableId: uint64
  # stacks: array[MaxTasks, array[StackSize, uint64]]
  stack0: Stack
  stack1: Stack
  tasks: array[MaxTasks, Task]
  currentTaskId: int

proc newTask*(entryPoint: pointer): Task =
  # var stack = stacks[0]
  stack0 = new(Stack)
  var stack = stack0

  # println(&"addr stack[0] = {cast[uint64](addr stack[0]):x}")
  # println(&"addr stack[255] = {cast[uint64](addr stack[StackSize - 1]):x}")

  for i in 0..<StackSize:
    stack[i] = 0

  let rip = cast[uint64](entryPoint)
  let stackTop = cast[uint64](addr stack[StackSize - 1])

  # interrupt frame
  stack[StackSize - 01] = 0x30   # ss
  stack[StackSize - 02] = stackTop # rsp
  stack[StackSize - 03] = 0x202  # rflags
  stack[StackSize - 04] = 0x038  # cs
  stack[StackSize - 05] = rip    # rip

  # schedule() saved regs
  stack[StackSize - 06] = 0      # r12
  stack[StackSize - 07] = 0      # r11
  stack[StackSize - 08] = 0      # r10
  stack[StackSize - 09] = 0      # r9
  stack[StackSize - 10] = 0      # r8
  stack[StackSize - 11] = 0      # rcx
  stack[StackSize - 12] = 0      # rdx
  stack[StackSize - 13] = 0      # rax
  stack[StackSize - 13] = 0      # rax

  # 0x38 bytes stack space for schedule() locals

  # schedule() right after calling switchTo()
  stack[StackSize - 68] = 0      # rip ??

  # switchTo() saved regs
  stack[StackSize - 69] = 0      # rax
  stack[StackSize - 70] = 0      # rbx
  stack[StackSize - 71] = 0      # rcx
  stack[StackSize - 72] = 0      # rdx
  stack[StackSize - 73] = 0      # rsi
  stack[StackSize - 74] = 0      # rdi
  stack[StackSize - 75] = 0      # rbp

  let rsp = addr stack[StackSize - 75]
  println(&"rsp = {cast[uint64](rsp):x}")
  println(&"rsp[] = {rsp[]:x}")


  let t = new(Task)
  t.id = nextAvailableId
  t.rsp = rsp

  inc(nextAvailableId)
  return t

proc task1() =
  print("task1")
  while true:
    print(".")
    for i in 0..250000:
      asm "pause"

proc initTasks*() =
  currentTaskId = 0
  nextAvailableId = 1

  # currently executing task (this will become the idle task)
  tasks[0] = new(Task)
  tasks[0].id = 0
  tasks[0].rsp = cast[pointer](0x50505050'u64)

  let pt0 = cast[ptr uint64](tasks[0])
  println(&"addr tasks[0] = {cast[uint64](pt0):x}")
  println(&"tasks[0].rsp = {pt0[]:x}")

  # new task
  tasks[1] = newTask(task1)

  let pt1 = cast[ptr uint64](tasks[1])
  println(&"addr tasks[1] = {cast[uint64](pt1):x}")
  println(&"tasks[1].rsp = {pt1[]:x}")

  println("Initialized tasks")

{.push stackTrace:off.}
proc switchTo(currTask: Task, nextTask: Task) {.asmNoStackFrame.} =
  # currTask is in rcx, nextTask is in rdx
  asm """
    push    rax
    push    rbx
    push    rcx
    push    rdx
    push    rsi
    push    rdi
    push    rbp

    mov     [rcx], rsp               # save current task's kernel stack esp

    mov     rsp, [rdx]               # load new task's kernel stack esp

    # cli
    # hlt

    pop     rbp
    pop     rdi
    pop     rsi
    pop     rdx
    pop     rcx
    pop     rbx
    pop     rax

    ret
  """
{.pop.}
