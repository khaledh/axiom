import aml {.all.}


type
  Visitor = concept
    proc enter(v: Self, terms: TermList)
    proc leave(v: Self, terms: TermList)

    proc enter(v: Self, termObj: TermObj)
    proc leave(v: Self, termObj: TermObj)

    proc enter(v: Self, obj: Obj)
    proc leave(v: Self, obj: Obj)

    proc enter(v: Self, nsModObj: NamespaceModifierObj)
    proc leave(v: Self, nsModObj: NamespaceModifierObj)

    proc enter(v: Self, defName: DefAlias)
    proc leave(v: Self, defName: DefAlias)

    proc enter(v: Self, defName: DefName)
    proc leave(v: Self, defName: DefName)

    proc enter(v: Self, defScope: DefScope)
    proc leave(v: Self, defScope: DefScope)

    proc enter(v: Self, namedObj: NamedObj)
    proc leave(v: Self, namedObj: NamedObj)

    proc enter(v: Self, defCreateDWordField: DefCreateDWordField)
    proc leave(v: Self, defCreateDWordField: DefCreateDWordField)

    proc enter(v: Self, defField: DefField)
    proc leave(v: Self, defField: DefField)

    proc enter(v: Self, fieldElement: FieldElement)
    proc leave(v: Self, fieldElement: FieldElement)

    proc enter(v: Self, defDevice: DefDevice)
    proc leave(v: Self, defDevice: DefDevice)

    proc enter(v: Self, defMethod: DefMethod)
    proc leave(v: Self, defMethod: DefMethod)

    proc enter(v: Self, defMutex: DefMutex)
    proc leave(v: Self, defMutex: DefMutex)

    proc enter(v: Self, defOpRegion: DefOpRegion)
    proc leave(v: Self, defOpRegion: DefOpRegion)

    proc enter(v: Self, defProcessor: DefProcessor)
    proc leave(v: Self, defProcessor: DefProcessor)


# forward declarations
proc accept*(terms: TermList, v: Visitor)
proc accept(termObj: TermObj, v: Visitor)
proc accept(obj: Obj, v: Visitor)
proc accept(nsModObj: NamespaceModifierObj, v: Visitor)
proc accept(defAlias: DefAlias, v: Visitor)
proc accept(namedObj: NamedObj, v: Visitor)
proc accept(defCreateDWordField: DefCreateDWordField, v: Visitor)
proc accept(defField: DefField, v: Visitor)
proc accept(fieldElement: FieldElement, v: Visitor)
proc accept(defName: DefName, v: Visitor)
proc accept(defScope: DefScope, v: Visitor)
proc accept(defDevice: DefDevice, v: Visitor)
proc accept(defMethod: DefMethod, v: Visitor)
proc accept(defMutex: DefMutex, v: Visitor)
proc accept(defOpRegion: DefOpRegion, v: Visitor)
proc accept(defProcessor: DefProcessor, v: Visitor)

proc accept(termArg: TermArg, v: Visitor)


template visit(v: Visitor, elem: untyped, body: untyped) =
  v.enter(elem)
  body
  v.leave(elem)

proc accept*(terms: TermList, v: Visitor) =
  v.visit(terms):
    for termObj in terms:
      termObj.accept(v)

proc accept(termObj: TermObj, v: Visitor) =
  v.visit(termObj):
    case termObj.kind:
    of toObject:
      termObj.obj.accept(v)
    # of toStatement:
    #   v.visit(term.stmt)
    # of toExpression:
    #   v.visit(term.expr)
    else:
      discard

proc accept(obj: Obj, v: Visitor) =
  v.visit(obj):
    case obj.kind:
    of okNsModObj:
      obj.nsModObj.accept(v)
    of okNamedObj:
      obj.namedObj.accept(v)

proc accept(nsModObj: NamespaceModifierObj, v: Visitor) =
  v.visit(nsModObj):
    case nsModObj.kind:
    of nmoDefName:
      nsModObj.defName.accept(v)
    of nmoDefScope:
      nsModObj.defScope.accept(v)
    else:
      discard

proc accept(namedObj: NamedObj, v: Visitor) =
  v.visit(namedObj):
    case namedObj.kind:
    of noDefField:
      namedObj.defField.accept(v)
    of noDefCreateDWordField:
      namedObj.defCreateDWordField.accept(v)
    of noDefDevice:
      namedObj.defDevice.accept(v)
    of noDefMethod:
      namedObj.defMethod.accept(v)
    of noDefMutex:
      namedObj.defMutex.accept(v)
    of noDefOpRegion:
      namedObj.defOpRegion.accept(v)
    of noDefProcessor:
      namedObj.defProcessor.accept(v)
    else:
      discard

proc accept(defAlias: DefAlias, v: Visitor) =
  v.visit(defAlias):
    discard

proc accept(defName: DefName, v: Visitor) =
  v.visit(defName):
    discard
    # defName.obj.accept(v)

proc accept(defScope: DefScope, v: Visitor) =
  v.visit(defScope):
    defScope.terms.accept(v)

proc accept(defCreateDWordField: DefCreateDWordField, v: Visitor) =
  v.visit(defCreateDWordField):
    defCreateDWordField.srcBuffer.accept(v)
    defCreateDWordField.byteIndex.accept(v)

proc accept(defField: DefField, v: Visitor) =
  v.visit(defField):
    for elem in defField.elements:
      elem.accept(v)

proc accept(fieldElement: FieldElement, v: Visitor) =
  v.visit(fieldElement):
    discard

proc accept(defDevice: DefDevice, v: Visitor) =
  v.visit(defDevice):
    defDevice.body.accept(v)

proc accept(defMethod: DefMethod, v: Visitor) =
  v.visit(defMethod):
    # defMethod.terms.accept(v)
    discard

proc accept(defMutex: DefMutex, v: Visitor) =
  v.visit(defMutex):
    discard

proc accept(defOpRegion: DefOpRegion, v: Visitor) =
  v.visit(defOpRegion):
    discard

proc accept(defProcessor: DefProcessor, v: Visitor) =
  v.visit(defProcessor):
    defProcessor.objects.accept(v)

proc accept(termArg: TermArg, v: Visitor) =
  # v.visit(termArg):
  #   case termArg.kind:
  #   else:
  #     discard
  discard

# forward declarations
# proc accept*[V](terms: TermList, v: V)
# proc accept[V](termObj: TermObj, v: V)
# proc accept[V](obj: Obj, v: V)
# proc accept[V](nsModObj: NamespaceModifierObj, v: V)

# proc accept*[V](terms: TermList, v: V) =
#   v.visit(terms)
#   for termObj in terms:
#     termObj.accept(v)

# proc accept[V](termObj: TermObj, v: V) =
#   v.visit(termObj)

#   case termObj.kind:
#   of toObject:
#     termObj.obj.accept(v)
#   # of toStatement:
#   #   v.visit(term.stmt)
#   # of toExpression:
#   #   v.visit(term.expr)
#   else:
#     discard

# proc accept[V](obj: Obj, v: V) =
#   v.visit(obj)
#   case obj.kind:
#   of okNsModObj:
#     obj.nsModObj.accept(v)
#   # okNamedObj:
#   #   v.visit(obj.namedObj)
#   else:
#     discard

# proc accept[V](nsModObj: NamespaceModifierObj, v: V) =
#   v.visit(nsModObj)
#   case nsModObj.kind:
# #   of nmoDefName:
# #     v.visit(nsModObj.defName)
#   of nmoDefScope:
#     nsModObj.defScope.accept(v)
#   else:
#     discard

# # proc accept*[V](namedObj: NamedObj, v: V) =
# #   discard

# # proc accept*[V](defName: DefName, v: V) =
# #   v.visit(defName.obj)

# proc accept[V](defScope: DefScope, v: V) =
#   v.visit(defScope)
