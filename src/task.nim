const
  MaxTasks = 16
  StackSize = 1024

type
  Task* = object
    id: uint
    rax: uint64
    rbx: uint64
    rcx: uint64
    rdx: uint64
    rsi: uint64
    rdi: uint64
    rbp: uint64
    rsp: pointer
    rip: pointer
    rflags: uint64

var
  currId: uint
  stacks: array[MaxTasks, array[StackSize, byte]]

proc initTasks*() =
    currId = 0

proc newTask*(entryPoint: pointer): Task =
    let stack = stacks[currId]
    let t = Task(
        id: currId,
        rip: entryPoint,
        rsp: unsafeAddr stack[StackSize],
    )
    inc(currId)
    return t
