proc cmpxchg*(location: var bool, expected: bool, newval: bool): bool {.inline.} =
  asm """
    lock cmpxchg %0, %3
    sete %1
    : "+m"(*`location`), "=q"(`result`)
    : "a"(`expected`), "r"(`newval`)
    : "memory"
  """
