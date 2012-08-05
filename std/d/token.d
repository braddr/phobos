module std.d.token;

import core.stdc.stdio : fprintf, sprintf;
import core.stdc.string : strcat; 
import core.stdc.ctype : isprint;

import std.outbuffer;
import std.utf;
import std.d.keywords;
import std.d.identifier;
import std.d.stringtable;

enum TOK
{
    TOKreserved,

    // Other
    TOKlparen,      TOKrparen,
    TOKlbracket,    TOKrbracket,
    TOKlcurly,      TOKrcurly,
    TOKcolon,       TOKneg,
    TOKsemicolon,   TOKdotdotdot,
    TOKeof,         TOKcast,
    TOKnull,        TOKassert,
    TOKtrue,        TOKfalse,
    TOKarray,       TOKcall,
    TOKaddress,
    TOKtype,        TOKthrow,
    TOKnew,         TOKdelete,
    TOKstar,        TOKsymoff,
    TOKvar,         TOKdotvar,
    TOKdotti,       TOKdotexp,
    TOKdottype,     TOKslice,
    TOKarraylength, TOKversion,
    TOKmodule,      TOKdollar,
    TOKtemplate,    TOKdottd,
    TOKdeclaration, TOKtypeof,
    TOKpragma,      TOKdsymbol,
    TOKtypeid,      TOKuadd,
    TOKremove,
    TOKnewanonclass, TOKcomment,
    TOKarrayliteral, TOKassocarrayliteral,
    TOKstructliteral,

    // Operators
    TOKlt,          TOKgt,
    TOKle,          TOKge,
    TOKequal,       TOKnotequal,
    TOKidentity,    TOKnotidentity,
    TOKindex,       TOKis,
    TOKtobool,

    // 60
    // NCEG floating point compares
    // !<>=     <>    <>=    !>     !>=   !<     !<=   !<>
    TOKunord,TOKlg,TOKleg,TOKule,TOKul,TOKuge,TOKug,TOKue,

    TOKshl,         TOKshr,
    TOKshlass,      TOKshrass,
    TOKushr,        TOKushrass,
    TOKcat,         TOKcatass,      // ~ ~=
    TOKadd,         TOKmin,         TOKaddass,      TOKminass,
    TOKmul,         TOKdiv,         TOKmod,
    TOKmulass,      TOKdivass,      TOKmodass,
    TOKand,         TOKor,          TOKxor,
    TOKandass,      TOKorass,       TOKxorass,
    TOKassign,      TOKnot,         TOKtilde,
    TOKplusplus,    TOKminusminus,  TOKconstruct,   TOKblit,
    TOKdot,         TOKarrow,       TOKcomma,
    TOKquestion,    TOKandand,      TOKoror,
    TOKpreplusplus, TOKpreminusminus,

    // 106
    // Numeric literals
    TOKint32v, TOKuns32v,
    TOKint64v, TOKuns64v,
    TOKfloat32v, TOKfloat64v, TOKfloat80v,
    TOKimaginary32v, TOKimaginary64v, TOKimaginary80v,

    // Char constants
    TOKcharv, TOKwcharv, TOKdcharv,

    // Leaf operators
    TOKidentifier,  TOKstring,
    TOKthis,        TOKsuper,
    TOKhalt,        TOKtuple,
    TOKerror,

    // Basic types
    TOKvoid,
    TOKint8, TOKuns8,
    TOKint16, TOKuns16,
    TOKint32, TOKuns32,
    TOKint64, TOKuns64,
    TOKfloat32, TOKfloat64, TOKfloat80,
    TOKimaginary32, TOKimaginary64, TOKimaginary80,
    TOKcomplex32, TOKcomplex64, TOKcomplex80,
    TOKchar, TOKwchar, TOKdchar, TOKbit, TOKbool,
    TOKcent, TOKucent,

    // 152
    // Aggregates
    TOKstruct, TOKclass, TOKinterface, TOKunion, TOKenum, TOKimport,
    TOKtypedef, TOKalias, TOKoverride, TOKdelegate, TOKfunction,
    TOKmixin,

    TOKalign, TOKextern, TOKprivate, TOKprotected, TOKpublic, TOKexport,
    TOKstatic, /*TOKvirtual,*/ TOKfinal, TOKconst, TOKabstract, TOKvolatile,
    TOKdebug, TOKdeprecated, TOKin, TOKout, TOKinout, TOKlazy,
    TOKauto, TOKpackage, TOKmanifest, TOKimmutable,

    // Statements
    TOKif, TOKelse, TOKwhile, TOKfor, TOKdo, TOKswitch,
    TOKcase, TOKdefault, TOKbreak, TOKcontinue, TOKwith,
    TOKsynchronized, TOKreturn, TOKgoto, TOKtry, TOKcatch, TOKfinally,
    TOKasm, TOKforeach, TOKforeach_reverse,
    TOKscope,
    TOKon_scope_exit, TOKon_scope_failure, TOKon_scope_success,

    // Contracts
    TOKbody, TOKinvariant,

    // Testing
    TOKunittest,

    // Added after 1.0
    TOKargTypes,
    TOKref,
    TOKmacro,
    TOKparameters,
    TOKtraits,
    TOKoverloadset,
    TOKpure,
    TOKnothrow,
    TOKtls,
    TOKgshared,
    TOKline,
    TOKfile,
    TOKshared,
    TOKat,
    TOKpow,
    TOKpowass,
    TOKgoesto,
    TOKvector,
    TOKpound,

    TOKMAX
}

struct Token
{
    Token* next;

    byte* ptr;         // pointer to first character of this token within buffer
    TOK value;
    byte* blockComment; // doc comment string prior to this token
    byte* lineComment;  // doc comment for previous token
    union
    {
        // Integers
        int int32value;
        uint uns32value;
        long int64value;
        ulong uns64value;

        // Floats
        real float80value;

        struct
        {   byte* ustring;     // UTF8 string
            int   len;
            byte  postfix;     // 'c', 'w', 'd'
        };

        Identifier *ident;
    };

    static const(char)* tochars[TOK.TOKMAX];

    void print()
    {
        fprintf(stdout, "%s\n", toChars());
    }

    const(char)* toChars()
    {
        static char buffer[3 + 3 * float80value.sizeof + 1];

        const(char)* p = buffer;
        switch (value)
        {
            case TOK.TOKint32v:
                sprintf(buffer, "%d", int32value);
                break;

            case TOK.TOKuns32v:
            case TOK.TOKcharv:
            case TOK.TOKwcharv:
            case TOK.TOKdcharv:
                sprintf(buffer, "%uU", uns32value);
                break;

            case TOK.TOKint64v:
                sprintf(buffer, "%lldL", int64value);
                break;

            case TOK.TOKuns64v:
                sprintf(buffer, "%lluUL", uns64value);
                break;

            case TOK.TOKfloat32v:
                sprintf(buffer, "%g", float80value);
                strcat(buffer, "f");
                break;

            case TOK.TOKfloat64v:
                sprintf(buffer, "%g", float80value);
                break;

            case TOK.TOKfloat80v:
                sprintf(buffer, "%g", float80value);
                strcat(buffer, "L");
                break;

            case TOK.TOKimaginary32v:
                sprintf(buffer, "%g", float80value);
                strcat(buffer, "fi");
                break;

            case TOK.TOKimaginary64v:
                sprintf(buffer, "%g", float80value);
                strcat(buffer, "i");
                break;

            case TOK.TOKimaginary80v:
                sprintf(buffer, "%g", float80value);
                strcat(buffer, "Li");
                break;

            case TOK.TOKstring:
            {
                OutBuffer buf = new OutBuffer();
                scope(exit) delete buf;

                buf.write('"');
                for (size_t i = 0; i < len; )
                {
                    int c = decode(cast(char[])ustring[0 .. len], i);
                    switch (c)
                    {
                        case 0:
                            break;

                        case '"':
                        case '\\':
                            buf.write('\\');
                            goto default;
                        default:
                            if (isprint(c))
                                buf.write(cast(byte)c);
                            else if (c <= 0x7F)
                                buf.printf("\\x%02x", c);
                            else if (c <= 0xFFFF)
                                buf.printf("\\u%04x", c);
                            else
                                buf.printf("\\U%08x", c);
                            continue;
                    }
                    break;
                }
                buf.write('"');
                if (postfix)
                    buf.write('"');
                buf.write(cast(byte)0);
                p = cast(const(char)*)(buf.toBytes().ptr);
                break;
            }

            case TOK.TOKidentifier:
            case TOK.TOKenum:
            case TOK.TOKstruct:
            case TOK.TOKimport:
            case TOK.TOKwchar:
            case TOK.TOKdchar:
            case TOK.TOKbit:
            case TOK.TOKbool:
            case TOK.TOKchar:
            case TOK.TOKint8:
            case TOK.TOKuns8:
            case TOK.TOKint16:
            case TOK.TOKuns16:
            case TOK.TOKint32:
            case TOK.TOKuns32:
            case TOK.TOKint64:
            case TOK.TOKuns64:
            case TOK.TOKfloat32:
            case TOK.TOKfloat64:
            case TOK.TOKfloat80:
            case TOK.TOKimaginary32:
            case TOK.TOKimaginary64:
            case TOK.TOKimaginary80:
            case TOK.TOKcomplex32:
            case TOK.TOKcomplex64:
            case TOK.TOKcomplex80:
            case TOK.TOKvoid:
                p = ident.toChars();
                break;

            default:
                p = toChars(value);
                break;
        }
        return p;
    }

    static const(char*) toChars(TOK value)
    {
        static char buffer[3 + 3 * value.sizeof + 1];

        const(char)* p = tochars[value];
        if (!p)
        {
            sprintf(buffer,"TOK%d",value);
            p = buffer;
        }
        return p;
    }
}


void init_keywords()
{
    add_keywords_to_token();

    Token.tochars[TOK.TOKeof]              = "EOF";
    Token.tochars[TOK.TOKlcurly]           = "{";
    Token.tochars[TOK.TOKrcurly]           = "}";
    Token.tochars[TOK.TOKlparen]           = "(";
    Token.tochars[TOK.TOKrparen]           = ")";
    Token.tochars[TOK.TOKlbracket]         = "[";
    Token.tochars[TOK.TOKrbracket]         = "]";
    Token.tochars[TOK.TOKsemicolon]        = ";";
    Token.tochars[TOK.TOKcolon]            = ":";
    Token.tochars[TOK.TOKcomma]            = ",";
    Token.tochars[TOK.TOKdot]              = ".";
    Token.tochars[TOK.TOKxor]              = "^";
    Token.tochars[TOK.TOKxorass]           = "^=";
    Token.tochars[TOK.TOKassign]           = "=";
    Token.tochars[TOK.TOKconstruct]        = "=";
    Token.tochars[TOK.TOKblit]             = "=";
    Token.tochars[TOK.TOKlt]               = "<";
    Token.tochars[TOK.TOKgt]               = ">";
    Token.tochars[TOK.TOKle]               = "<=";
    Token.tochars[TOK.TOKge]               = ">=";
    Token.tochars[TOK.TOKequal]            = "==";
    Token.tochars[TOK.TOKnotequal]         = "!=";
    Token.tochars[TOK.TOKnotidentity]      = "!is";
    Token.tochars[TOK.TOKtobool]           = "!!";

    Token.tochars[TOK.TOKunord]            = "!<>=";
    Token.tochars[TOK.TOKue]               = "!<>";
    Token.tochars[TOK.TOKlg]               = "<>";
    Token.tochars[TOK.TOKleg]              = "<>=";
    Token.tochars[TOK.TOKule]              = "!>";
    Token.tochars[TOK.TOKul]               = "!>=";
    Token.tochars[TOK.TOKuge]              = "!<";
    Token.tochars[TOK.TOKug]               = "!<=";

    Token.tochars[TOK.TOKnot]              = "!";
    Token.tochars[TOK.TOKtobool]           = "!!";
    Token.tochars[TOK.TOKshl]              = "<<";
    Token.tochars[TOK.TOKshr]              = ">>";
    Token.tochars[TOK.TOKushr]             = ">>>";
    Token.tochars[TOK.TOKadd]              = "+";
    Token.tochars[TOK.TOKmin]              = "-";
    Token.tochars[TOK.TOKmul]              = "*";
    Token.tochars[TOK.TOKdiv]              = "/";
    Token.tochars[TOK.TOKmod]              = "%";
    Token.tochars[TOK.TOKslice]            = "..";
    Token.tochars[TOK.TOKdotdotdot]        = "...";
    Token.tochars[TOK.TOKand]              = "&";
    Token.tochars[TOK.TOKandand]           = "&&";
    Token.tochars[TOK.TOKor]               = "|";
    Token.tochars[TOK.TOKoror]             = "||";
    Token.tochars[TOK.TOKarray]            = "[]";
    Token.tochars[TOK.TOKindex]            = "[i]";
    Token.tochars[TOK.TOKaddress]          = "&";
    Token.tochars[TOK.TOKstar]             = "*";
    Token.tochars[TOK.TOKtilde]            = "~";
    Token.tochars[TOK.TOKdollar]           = "$";
    Token.tochars[TOK.TOKcast]             = "cast";
    Token.tochars[TOK.TOKplusplus]         = "++";
    Token.tochars[TOK.TOKminusminus]       = "--";
    Token.tochars[TOK.TOKpreplusplus]      = "++";
    Token.tochars[TOK.TOKpreminusminus]    = "--";
    Token.tochars[TOK.TOKtype]             = "type";
    Token.tochars[TOK.TOKquestion]         = "?";
    Token.tochars[TOK.TOKneg]              = "-";
    Token.tochars[TOK.TOKuadd]             = "+";
    Token.tochars[TOK.TOKvar]              = "var";
    Token.tochars[TOK.TOKaddass]           = "+=";
    Token.tochars[TOK.TOKminass]           = "-=";
    Token.tochars[TOK.TOKmulass]           = "*=";
    Token.tochars[TOK.TOKdivass]           = "/=";
    Token.tochars[TOK.TOKmodass]           = "%=";
    Token.tochars[TOK.TOKshlass]           = "<<=";
    Token.tochars[TOK.TOKshrass]           = ">>=";
    Token.tochars[TOK.TOKushrass]          = ">>>=";
    Token.tochars[TOK.TOKandass]           = "&=";
    Token.tochars[TOK.TOKorass]            = "|=";
    Token.tochars[TOK.TOKcatass]           = "~=";
    Token.tochars[TOK.TOKcat]              = "~";
    Token.tochars[TOK.TOKcall]             = "call";
    Token.tochars[TOK.TOKidentity]         = "is";
    Token.tochars[TOK.TOKnotidentity]      = "!is";

    Token.tochars[TOK.TOKorass]            = "|=";
    Token.tochars[TOK.TOKidentifier]       = "identifier";
    Token.tochars[TOK.TOKat]               = "@";
    Token.tochars[TOK.TOKpow]              = "^^";
    Token.tochars[TOK.TOKpowass]           = "^^=";
    Token.tochars[TOK.TOKgoesto]           = "=>";
    Token.tochars[TOK.TOKpound]            = "#";

    // For debugging
    Token.tochars[TOK.TOKerror]            = "error";
    Token.tochars[TOK.TOKdotexp]           = "dotexp";
    Token.tochars[TOK.TOKdotti]            = "dotti";
    Token.tochars[TOK.TOKdotvar]           = "dotvar";
    Token.tochars[TOK.TOKdottype]          = "dottype";
    Token.tochars[TOK.TOKsymoff]           = "symoff";
    Token.tochars[TOK.TOKarraylength]      = "arraylength";
    Token.tochars[TOK.TOKarrayliteral]     = "arrayliteral";
    Token.tochars[TOK.TOKassocarrayliteral] = "assocarrayliteral";
    Token.tochars[TOK.TOKstructliteral]    = "structliteral";
    Token.tochars[TOK.TOKstring]           = "string";
    Token.tochars[TOK.TOKdsymbol]          = "symbol";
    Token.tochars[TOK.TOKtuple]            = "tuple";
    Token.tochars[TOK.TOKdeclaration]      = "declaration";
    Token.tochars[TOK.TOKdottd]            = "dottd";
    Token.tochars[TOK.TOKon_scope_exit]    = "scope(exit)";
    Token.tochars[TOK.TOKon_scope_success] = "scope(success)";
    Token.tochars[TOK.TOKon_scope_failure] = "scope(failure)";
}
