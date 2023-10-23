# Given a parsed DSDT syntax tree, traverse the tree to construct the ACPI namespace.

# The namespace is a dictionary of ACPI objects, indexed by their fully qualified
# names.  Each object is a dictionary with the following keys:
#  - name: the name of the object
#  - type: the type of the object (e.g. "Scope", "Method", "Field", etc.)
#  - parent: the fully qualified name of the parent object
#  - children: a list of the fully qualified names of the children of this object
#  - scope: the fully qualified name of the scope of this object

# Use a variant type to represent objects in the namespace. Possible variants are:
#  - Scope: a scope object
#  - Name: a name declaration object
#  - Method: a method object
#  - Field: a field object
#  - Device: a device object
#  - Processor: a processor object

# The namespace is constructed by traversing the tree in a depth-first manner.
# The namespace is constructed in two passes.  The first pass constructs the
# namespace objects.  The second pass resolves the scope of each object.
import std/algorithm
import std/sequtils
import std/strformat
import std/sugar
import std/tables

import aml {.all.}
import visitor
import ../debug
import ../utils

# {.experimental: "codeReordering".}

type
  NamespaceNodeKind = enum
    nnAlias      = (0, "Alias")
    nnName       = (1, "Name")
    nnScope      = (2, "Scope")
    nnDWordField = (3, "DWordField")
    nnDevice     = (4, "Device")
    nnField      = (5, "Field")
    nnMethod     = (6, "Method")
    nnMutex      = (7, "Mutex")
    nnOpRegion   = (8, "OperationRegion")
    nnProcessor  = (9, "Processor")
  NamespaceNode = ref object
    name: string
    parent: NamespaceNode
    children: seq[NamespaceNode]
    case kind: NamespaceNodeKind
    of nnAlias:
      defAlias: DefAlias
    of nnName:
      defName: DefName
    of nnScope:
      defScope: DefScope
    of nnDWordField:
      defDWordField: DefCreateDWordField
    of nnDevice:
      defDevice: DefDevice
    of nnField:
      defField: FieldElement
    of nnMethod:
      defMethod: DefMethod
    of nnMutex:
      defMutex: DefMutex
    of nnOpRegion:
      defOpRegion: DefOpRegion
    of nnProcessor:
      defProcessor: DefProcessor


proc resolveName(scope: string, name: string): string =
  if name[0] == '\\':
    return name
  elif scope == "\\":
    return scope & name
  else:
    return scope & "." & name


type
  NamespaceVisitor = ref object
    namespaces: OrderedTable[string, NamespaceNode]
    scopeStack: seq[string] = @["\\"]

proc enter(v: NamespaceVisitor, terms: TermList) = discard
proc leave(v: NamespaceVisitor, terms: TermList) = discard

proc enter(v: NamespaceVisitor, termObj: TermObj) = discard
proc leave(v: NamespaceVisitor, termObj: TermObj) = discard

proc enter(v: NamespaceVisitor, obj: Obj) = discard
proc leave(v: NamespaceVisitor, obj: Obj) = discard

## NamespaceModifierObj

proc enter(v: NamespaceVisitor, nsModObj: NamespaceModifierObj) = discard
proc leave(v: NamespaceVisitor, nsModObj: NamespaceModifierObj) = discard

proc enter(v: NamespaceVisitor, defAlias: DefAlias) =
  let fqn = resolveName(v.scopeStack[^1], defAlias.name)
  v.scopeStack.add(fqn)
  v.namespaces[fqn] = NamespaceNode(name: fqn, kind: nnAlias, defAlias: defAlias)

proc leave(v: NamespaceVisitor, defAlias: DefAlias) =
  discard v.scopeStack.pop()

proc enter(v: NamespaceVisitor, defName: DefName) =
  let fqn = resolveName(v.scopeStack[^1], defName.name)
  v.scopeStack.add(fqn)
  v.namespaces[fqn] = NamespaceNode(name: fqn, kind: nnName, defName: defName)

proc leave(v: NamespaceVisitor, defName: DefName) =
  discard v.scopeStack.pop()

proc enter(v: NamespaceVisitor, defScope: DefScope) =
  let fqn = resolveName(v.scopeStack[^1], defScope.name)
  v.scopeStack.add(fqn)
  v.namespaces[fqn] = NamespaceNode(name: fqn, kind: nnScope, defScope: defScope)

proc leave(v: NamespaceVisitor, defScope: DefScope) =
  discard v.scopeStack.pop()

## NamedObj

proc enter(v: NamespaceVisitor, namedObj: NamedObj) = discard
proc leave(v: NamespaceVisitor, namedObj: NamedObj) = discard

proc enter(v: NamespaceVisitor, defCreateDWordField: DefCreateDWordField) =
  let fqn = resolveName(v.scopeStack[^1], defCreateDWordField.name)
  v.scopeStack.add(fqn)
  v.namespaces[fqn] = NamespaceNode(name: fqn, kind: nnDWordField, defDWordField: defCreateDWordField)

proc enter(v: NamespaceVisitor, defField: DefField) = discard
proc leave(v: NamespaceVisitor, defField: DefField) = discard

proc enter(v: NamespaceVisitor, fieldElement: FieldElement) =
  if fieldElement.kind == feNamedField:
    let fqn = resolveName(v.scopeStack[^1], fieldElement.namedField.name)
    v.scopeStack.add(fqn)
    v.namespaces[fqn] = NamespaceNode(name: fqn, kind: nnField, defField: fieldElement)

proc leave(v: NamespaceVisitor, fieldElement: FieldElement) =
  if fieldElement.kind == feNamedField:
    discard v.scopeStack.pop()

proc leave(v: NamespaceVisitor, defCreateDWordField: DefCreateDWordField) =
  discard v.scopeStack.pop()

proc enter(v: NamespaceVisitor, defDevice: DefDevice) =
  let fqn = resolveName(v.scopeStack[^1], defDevice.name)
  v.scopeStack.add(fqn)
  v.namespaces[fqn] = NamespaceNode(name: fqn, kind: nnDevice, defDevice: defDevice)

proc leave(v: NamespaceVisitor, defDevice: DefDevice) =
  discard v.scopeStack.pop()

proc enter(v: NamespaceVisitor, defMethod: DefMethod) =
  let fqn = resolveName(v.scopeStack[^1], defMethod.name)
  v.scopeStack.add(fqn)
  v.namespaces[fqn] = NamespaceNode(name: fqn, kind: nnMethod, defMethod: defMethod)

proc leave(v: NamespaceVisitor, defMethod: DefMethod) =
  discard v.scopeStack.pop()

proc enter(v: NamespaceVisitor, defMutex: DefMutex) =
  let fqn = resolveName(v.scopeStack[^1], defMutex.name)
  v.scopeStack.add(fqn)
  v.namespaces[fqn] = NamespaceNode(name: fqn, kind: nnMutex, defMutex: defMutex)

proc leave(v: NamespaceVisitor, defMutex: DefMutex) =
  discard v.scopeStack.pop()

proc enter(v: NamespaceVisitor, defOpRegion: DefOpRegion) =
  let fqn = resolveName(v.scopeStack[^1], defOpRegion.name)
  v.scopeStack.add(fqn)
  v.namespaces[fqn] = NamespaceNode(name: fqn, kind: nnOpRegion, defOpRegion: defOpRegion)

proc leave(v: NamespaceVisitor, defOpRegion: DefOpRegion) =
  discard v.scopeStack.pop()

proc enter(v: NamespaceVisitor, defProcessor: DefProcessor) =
  let fqn = resolveName(v.scopeStack[^1], defProcessor.name)
  v.scopeStack.add(fqn)
  v.namespaces[fqn] = NamespaceNode(name: fqn, kind: nnProcessor, defProcessor: defProcessor)

proc leave(v: NamespaceVisitor, defProcessor: DefProcessor) =
  discard v.scopeStack.pop()

## ----

var
  nv = NamespaceVisitor()

proc build*(terms: TermList) =
  terms.accept(nv)

  nv.namespaces.sort((a, b) => utils.compare(a[0], b[0]))

  debugln("")
  debugln("Names:")
  for n in nv.namespaces.values:
    debugln(&"  {n.name: 25} {n.kind}")
