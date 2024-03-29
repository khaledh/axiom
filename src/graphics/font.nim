import std/base64

type
  Font* = object
    width*: int
    height*: int
    glyphs*: ptr UncheckedArray[array[16, byte]]

const
  dina8x16Base64 = """
    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
    /1r/W/9c/13/Xv9f/2D/Yf9i/2P/ZP9l/2b/Z/9o/2n/av9r/2z/bf9u/2//cP9x/3L/c/90/3X/
    dv93/3j/ef96/3v/fP99/37//+KCrP//4oCa/8aS/+KAnv/igKb/4oCg/+KAof/Lhv/igLD/xaD/
    4oC5/8WS///Fvf///+KAmP/igJn/4oCc/+KAnf/igKL/4oCT/+KAlP/LnP/ihKL/xaH/4oC6/8WT
    ///Fvv/FuP/CoP/Cof/Cov/Co//CpP/Cpf/Cpv/Cp//CqP/Cqf/Cqv/Cq//CrP/Crf/Crv/Cr//C
    sP/Csf/Csv/Cs//CtP/Ctf/Ctv/Ct//CuP/Cuf/Cuv/Cu//CvP/Cvf/Cvv/Cv//DgP/Dgf/Dgv/D
    g//DhP/Dhf/Dhv/Dh//DiP/Dif/Div/Di//DjP/Djf/Djv/Dj//DkP/Dkf/Dkv/Dk//DlP/Dlf/D
    lv/Dl//DmP/Dmf/Dmv/Dm//DnP/Dnf/Dnv/Dn//DoP/Dof/Dov/Do//DpP/Dpf/Dpv/Dp//DqP/D
    qf/Dqv/Dq//DrP/Drf/Drv/Dr//DsP/Dsf/Dsv/Ds//DtP/Dtf/Dtv/Dt//DuP/Duf/Duv/Du//D
    vP/Dvf/Dvv//
  """

var dina8x16*: seq[byte]

proc loadFont*(): Font =
  dina8x16 = cast[seq[byte]](dina8x16Base64.decode())
  let glyphs8x16 = cast[ptr UncheckedArray[array[16, byte]]](addr dina8x16[32])
  Font(width: 8, height: 16, glyphs: glyphs8x16)
