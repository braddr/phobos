module std.d.keywords;

import std.d.token;

bool isKeyword(const ref Token t)
{
    foreach (ref k; keywords())
    {
        if (k.value == t.value)
            return true;
    }
    return false;
}

void foreach_keyword(void delegate(ref const Keyword k) dg)
{
    foreach (ref k; keywords())
        dg(k);
}

struct Keyword
{
    string name;
    TOK value;
}

Keyword[] keywords()
{
    static Keyword keywords[] =
    [
        {   "this",         TOK.TOKthis         },
        {   "super",        TOK.TOKsuper        },
        {   "assert",       TOK.TOKassert       },
        {   "null",         TOK.TOKnull         },
        {   "true",         TOK.TOKtrue         },
        {   "false",        TOK.TOKfalse        },
        {   "cast",         TOK.TOKcast         },
        {   "new",          TOK.TOKnew          },
        {   "delete",       TOK.TOKdelete       },
        {   "throw",        TOK.TOKthrow        },
        {   "module",       TOK.TOKmodule       },
        {   "pragma",       TOK.TOKpragma       },
        {   "typeof",       TOK.TOKtypeof       },
        {   "typeid",       TOK.TOKtypeid       },

        {   "template",     TOK.TOKtemplate     },

        {   "void",         TOK.TOKvoid         },
        {   "byte",         TOK.TOKint8         },
        {   "ubyte",        TOK.TOKuns8         },
        {   "short",        TOK.TOKint16        },
        {   "ushort",       TOK.TOKuns16        },
        {   "int",          TOK.TOKint32        },
        {   "uint",         TOK.TOKuns32        },
        {   "long",         TOK.TOKint64        },
        {   "ulong",        TOK.TOKuns64        },
        {   "cent",         TOK.TOKcent,        },
        {   "ucent",        TOK.TOKucent,       },
        {   "float",        TOK.TOKfloat32      },
        {   "double",       TOK.TOKfloat64      },
        {   "real",         TOK.TOKfloat80      },

        {   "bool",         TOK.TOKbool         },
        {   "char",         TOK.TOKchar         },
        {   "wchar",        TOK.TOKwchar        },
        {   "dchar",        TOK.TOKdchar        },

        {   "ifloat",       TOK.TOKimaginary32  },
        {   "idouble",      TOK.TOKimaginary64  },
        {   "ireal",        TOK.TOKimaginary80  },

        {   "cfloat",       TOK.TOKcomplex32    },
        {   "cdouble",      TOK.TOKcomplex64    },
        {   "creal",        TOK.TOKcomplex80    },

        {   "delegate",     TOK.TOKdelegate     },
        {   "function",     TOK.TOKfunction     },

        {   "is",           TOK.TOKis           },
        {   "if",           TOK.TOKif           },
        {   "else",         TOK.TOKelse         },
        {   "while",        TOK.TOKwhile        },
        {   "for",          TOK.TOKfor          },
        {   "do",           TOK.TOKdo           },
        {   "switch",       TOK.TOKswitch       },
        {   "case",         TOK.TOKcase         },
        {   "default",      TOK.TOKdefault      },
        {   "break",        TOK.TOKbreak        },
        {   "continue",     TOK.TOKcontinue     },
        {   "synchronized", TOK.TOKsynchronized },
        {   "return",       TOK.TOKreturn       },
        {   "goto",         TOK.TOKgoto         },
        {   "try",          TOK.TOKtry          },
        {   "catch",        TOK.TOKcatch        },
        {   "finally",      TOK.TOKfinally      },
        {   "with",         TOK.TOKwith         },
        {   "asm",          TOK.TOKasm          },
        {   "foreach",      TOK.TOKforeach      },
        {   "foreach_reverse",      TOK.TOKforeach_reverse      },
        {   "scope",        TOK.TOKscope        },

        {   "struct",       TOK.TOKstruct       },
        {   "class",        TOK.TOKclass        },
        {   "interface",    TOK.TOKinterface    },
        {   "union",        TOK.TOKunion        },
        {   "enum",         TOK.TOKenum         },
        {   "import",       TOK.TOKimport       },
        {   "mixin",        TOK.TOKmixin        },
        {   "static",       TOK.TOKstatic       },
        {   "final",        TOK.TOKfinal        },
        {   "const",        TOK.TOKconst        },
        {   "typedef",      TOK.TOKtypedef      },
        {   "alias",        TOK.TOKalias        },
        {   "override",     TOK.TOKoverride     },
        {   "abstract",     TOK.TOKabstract     },
        {   "volatile",     TOK.TOKvolatile     },
        {   "debug",        TOK.TOKdebug        },
        {   "deprecated",   TOK.TOKdeprecated   },
        {   "in",           TOK.TOKin           },
        {   "out",          TOK.TOKout          },
        {   "inout",        TOK.TOKinout        },
        {   "lazy",         TOK.TOKlazy         },
        {   "auto",         TOK.TOKauto         },

        {   "align",        TOK.TOKalign        },
        {   "extern",       TOK.TOKextern       },
        {   "private",      TOK.TOKprivate      },
        {   "package",      TOK.TOKpackage      },
        {   "protected",    TOK.TOKprotected    },
        {   "public",       TOK.TOKpublic       },
        {   "export",       TOK.TOKexport       },

        {   "body",         TOK.TOKbody         },
        {   "invariant",    TOK.TOKinvariant    },
        {   "unittest",     TOK.TOKunittest     },
        {   "version",      TOK.TOKversion      },

        {   "__argTypes",   TOK.TOKargTypes     },
        {   "__parameters", TOK.TOKparameters   },
        {   "ref",          TOK.TOKref          },
        {   "macro",        TOK.TOKmacro        },
        {   "pure",         TOK.TOKpure         },
        {   "nothrow",      TOK.TOKnothrow      },
        {   "__thread",     TOK.TOKtls          },
        {   "__gshared",    TOK.TOKgshared      },
        {   "__traits",     TOK.TOKtraits       },
        {   "__vector",     TOK.TOKvector       },
        {   "__overloadset", TOK.TOKoverloadset },
        {   "__FILE__",     TOK.TOKfile         },
        {   "__LINE__",     TOK.TOKline         },
        {   "shared",       TOK.TOKshared       },
        {   "immutable",    TOK.TOKimmutable    },
    ];

    return keywords;
}

