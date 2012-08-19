module std.d.identifier;

struct Identifier
{
    int value;
    string str;

    this(string s, int v)
    {
        str = s;
        value = v;
    }

    bool opEquals(Identifier *o)
    {
        return &this == o || this.str == o.str;
    }

    string toString()
    {
        return str;
    }
}

struct Id
{
    static Identifier *IUnknown;
    static Identifier *Object;
    static Identifier *object;
    static Identifier *max;
    static Identifier *min;
    static Identifier *This;
    static Identifier *Super;
    static Identifier *ctor;
    static Identifier *dtor;
    static Identifier *cpctor;
    static Identifier *_postblit;
    static Identifier *classInvariant;
    static Identifier *unitTest;
    static Identifier *require;
    static Identifier *ensure;
    static Identifier *init;
    static Identifier *size;
    static Identifier *__sizeof;
    static Identifier *__xalignof;
    static Identifier *Mangleof;
    static Identifier *Stringof;
    static Identifier *Tupleof;
    static Identifier *length;
    static Identifier *remove;
    static Identifier *ptr;
    static Identifier *array;
    static Identifier *funcptr;
    static Identifier *dollar;
    static Identifier *ctfe;
    static Identifier *offset;
    static Identifier *offsetof;
    static Identifier *ModuleInfo;
    static Identifier *ClassInfo;
    static Identifier *classinfo;
    static Identifier *typeinfo;
    static Identifier *outer;
    static Identifier *Exception;
    static Identifier *AssociativeArray;
    static Identifier *RTInfo;
    static Identifier *Throwable;
    static Identifier *Error;
    static Identifier *withSym;
    static Identifier *result;
    static Identifier *returnLabel;
    static Identifier *Delegate;
    static Identifier *line;
    static Identifier *empty;
    static Identifier *p;
    static Identifier *q;
    static Identifier *coverage;
    static Identifier *__vptr;
    static Identifier *__monitor;
    static Identifier *TypeInfo;
    static Identifier *TypeInfo_Class;
    static Identifier *TypeInfo_Interface;
    static Identifier *TypeInfo_Struct;
    static Identifier *TypeInfo_Enum;
    static Identifier *TypeInfo_Typedef;
    static Identifier *TypeInfo_Pointer;
    static Identifier *TypeInfo_Vector;
    static Identifier *TypeInfo_Array;
    static Identifier *TypeInfo_StaticArray;
    static Identifier *TypeInfo_AssociativeArray;
    static Identifier *TypeInfo_Function;
    static Identifier *TypeInfo_Delegate;
    static Identifier *TypeInfo_Tuple;
    static Identifier *TypeInfo_Const;
    static Identifier *TypeInfo_Invariant;
    static Identifier *TypeInfo_Shared;
    static Identifier *TypeInfo_Wild;
    static Identifier *elements;
    static Identifier *_arguments_typeinfo;
    static Identifier *_arguments;
    static Identifier *_argptr;
    static Identifier *_match;
    static Identifier *destroy;
    static Identifier *postblit;
    static Identifier *LINE;
    static Identifier *FILE;
    static Identifier *DATE;
    static Identifier *TIME;
    static Identifier *TIMESTAMP;
    static Identifier *VENDOR;
    static Identifier *VERSIONX;
    static Identifier *EOFX;
    static Identifier *nan;
    static Identifier *infinity;
    static Identifier *dig;
    static Identifier *epsilon;
    static Identifier *mant_dig;
    static Identifier *max_10_exp;
    static Identifier *max_exp;
    static Identifier *min_10_exp;
    static Identifier *min_exp;
    static Identifier *min_normal;
    static Identifier *re;
    static Identifier *im;
    static Identifier *C;
    static Identifier *D;
    static Identifier *Windows;
    static Identifier *Pascal;
    static Identifier *System;
    static Identifier *exit;
    static Identifier *success;
    static Identifier *failure;
    static Identifier *keys;
    static Identifier *values;
    static Identifier *rehash;
    static Identifier *sort;
    static Identifier *reverse;
    static Identifier *dup;
    static Identifier *idup;
    static Identifier *property;
    static Identifier *safe;
    static Identifier *trusted;
    static Identifier *system;
    static Identifier *disable;
    static Identifier *___out;
    static Identifier *___in;
    static Identifier *__int;
    static Identifier *__dollar;
    static Identifier *__LOCAL_SIZE;
    static Identifier *uadd;
    static Identifier *neg;
    static Identifier *com;
    static Identifier *add;
    static Identifier *add_r;
    static Identifier *sub;
    static Identifier *sub_r;
    static Identifier *mul;
    static Identifier *mul_r;
    static Identifier *div;
    static Identifier *div_r;
    static Identifier *mod;
    static Identifier *mod_r;
    static Identifier *eq;
    static Identifier *cmp;
    static Identifier *iand;
    static Identifier *iand_r;
    static Identifier *ior;
    static Identifier *ior_r;
    static Identifier *ixor;
    static Identifier *ixor_r;
    static Identifier *shl;
    static Identifier *shl_r;
    static Identifier *shr;
    static Identifier *shr_r;
    static Identifier *ushr;
    static Identifier *ushr_r;
    static Identifier *cat;
    static Identifier *cat_r;
    static Identifier *assign;
    static Identifier *addass;
    static Identifier *subass;
    static Identifier *mulass;
    static Identifier *divass;
    static Identifier *modass;
    static Identifier *andass;
    static Identifier *orass;
    static Identifier *xorass;
    static Identifier *shlass;
    static Identifier *shrass;
    static Identifier *ushrass;
    static Identifier *catass;
    static Identifier *postinc;
    static Identifier *postdec;
    static Identifier *index;
    static Identifier *indexass;
    static Identifier *slice;
    static Identifier *sliceass;
    static Identifier *call;
    static Identifier *Cast;
    static Identifier *match;
    static Identifier *next;
    static Identifier *opIn;
    static Identifier *opIn_r;
    static Identifier *opStar;
    static Identifier *opDot;
    static Identifier *opDispatch;
    static Identifier *opDollar;
    static Identifier *opUnary;
    static Identifier *opIndexUnary;
    static Identifier *opSliceUnary;
    static Identifier *opBinary;
    static Identifier *opBinaryRight;
    static Identifier *opOpAssign;
    static Identifier *opIndexOpAssign;
    static Identifier *opSliceOpAssign;
    static Identifier *pow;
    static Identifier *pow_r;
    static Identifier *powass;
    static Identifier *classNew;
    static Identifier *classDelete;
    static Identifier *apply;
    static Identifier *applyReverse;
    static Identifier *Fempty;
    static Identifier *Ffront;
    static Identifier *Fback;
    static Identifier *FpopFront;
    static Identifier *FpopBack;
    static Identifier *adDup;
    static Identifier *adReverse;
    static Identifier *aaLen;
    static Identifier *aaKeys;
    static Identifier *aaValues;
    static Identifier *aaRehash;
    static Identifier *monitorenter;
    static Identifier *monitorexit;
    static Identifier *criticalenter;
    static Identifier *criticalexit;
    static Identifier *_ArrayEq;
    static Identifier *GNU_asm;
    static Identifier *lib;
    static Identifier *msg;
    static Identifier *startaddress;
    static Identifier *tohash;
    static Identifier *tostring;
    static Identifier *getmembers;
    static Identifier *__alloca;
    static Identifier *main;
    static Identifier *WinMain;
    static Identifier *DllMain;
    static Identifier *tls_get_addr;
    static Identifier *va_argsave_t;
    static Identifier *va_argsave;
    static Identifier *std;
    static Identifier *core;
    static Identifier *math;
    static Identifier *sin;
    static Identifier *cos;
    static Identifier *tan;
    static Identifier *_sqrt;
    static Identifier *_pow;
    static Identifier *atan2;
    static Identifier *rndtol;
    static Identifier *expm1;
    static Identifier *exp2;
    static Identifier *yl2x;
    static Identifier *yl2xp1;
    static Identifier *fabs;
    static Identifier *bitop;
    static Identifier *bsf;
    static Identifier *bsr;
    static Identifier *bswap;
    static Identifier *isAbstractClass;
    static Identifier *isArithmetic;
    static Identifier *isAssociativeArray;
    static Identifier *isFinalClass;
    static Identifier *isFloating;
    static Identifier *isIntegral;
    static Identifier *isScalar;
    static Identifier *isStaticArray;
    static Identifier *isUnsigned;
    static Identifier *isVirtualFunction;
    static Identifier *isVirtualMethod;
    static Identifier *isAbstractFunction;
    static Identifier *isFinalFunction;
    static Identifier *isStaticFunction;
    static Identifier *isRef;
    static Identifier *isOut;
    static Identifier *isLazy;
    static Identifier *hasMember;
    static Identifier *identifier;
    static Identifier *parent;
    static Identifier *getMember;
    static Identifier *getOverloads;
    static Identifier *getVirtualFunctions;
    static Identifier *getVirtualMethods;
    static Identifier *classInstanceSize;
    static Identifier *allMembers;
    static Identifier *derivedMembers;
    static Identifier *isSame;
    static Identifier *compiles;
    static Identifier *parameters;
}

void foreach_identifier(void delegate(ref IdEntry i) dg)
{
    foreach (ref i; identifiers())
        dg(i);
}

struct IdEntry
{
    string       name;
    Identifier** id;
}

IdEntry[] identifiers()
{
    IdEntry[] idlist =
    [
        { "IUnknown",                  &Id.IUnknown                  },
        { "Object",                    &Id.Object                    },
        { "object",                    &Id.object                    },
        { "max",                       &Id.max                       },
        { "min",                       &Id.min                       },
        { "this",                      &Id.This                      },
        { "super",                     &Id.Super                     },
        { "__ctor",                    &Id.ctor                      },
        { "__dtor",                    &Id.dtor                      },
        { "__cpctor",                  &Id.cpctor                    },
        { "__postblit",                &Id._postblit                 },
        { "__invariant",               &Id.classInvariant            },
        { "__unitTest",                &Id.unitTest                  },
        { "__require",                 &Id.require                   },
        { "__ensure",                  &Id.ensure                    },
        { "init",                      &Id.init                      },
        { "size",                      &Id.size                      },
        { "sizeof",                    &Id.__sizeof                  },
        { "alignof",                   &Id.__xalignof                },
        { "mangleof",                  &Id.Mangleof                  },
        { "stringof",                  &Id.Stringof                  },
        { "tupleof",                   &Id.Tupleof                   },
        { "length",                    &Id.length                    },
        { "remove",                    &Id.remove                    },
        { "ptr",                       &Id.ptr                       },
        { "array",                     &Id.array                     },
        { "funcptr",                   &Id.funcptr                   },
        { "__dollar",                  &Id.dollar                    },
        { "__ctfe",                    &Id.ctfe                      },
        { "offset",                    &Id.offset                    },
        { "offsetof",                  &Id.offsetof                  },
        { "ModuleInfo",                &Id.ModuleInfo                },
        { "ClassInfo",                 &Id.ClassInfo                 },
        { "classinfo",                 &Id.classinfo                 },
        { "typeinfo",                  &Id.typeinfo                  },
        { "outer",                     &Id.outer                     },
        { "Exception",                 &Id.Exception                 },
        { "AssociativeArray",          &Id.AssociativeArray          },
        { "RTInfo",                    &Id.RTInfo                    },
        { "Throwable",                 &Id.Throwable                 },
        { "Error",                     &Id.Error                     },
        { "__withSym",                 &Id.withSym                   },
        { "__result",                  &Id.result                    },
        { "__returnLabel",             &Id.returnLabel               },
        { "delegate",                  &Id.Delegate                  },
        { "line",                      &Id.line                      },
        { "",                          &Id.empty                     },
        { "p",                         &Id.p                         },
        { "q",                         &Id.q                         },
        { "__coverage",                &Id.coverage                  },
        { "__vptr",                    &Id.__vptr                    },
        { "__monitor",                 &Id.__monitor                 },
        { "TypeInfo",                  &Id.TypeInfo                  },
        { "TypeInfo_Class",            &Id.TypeInfo_Class            },
        { "TypeInfo_Interface",        &Id.TypeInfo_Interface        },
        { "TypeInfo_Struct",           &Id.TypeInfo_Struct           },
        { "TypeInfo_Enum",             &Id.TypeInfo_Enum             },
        { "TypeInfo_Typedef",          &Id.TypeInfo_Typedef          },
        { "TypeInfo_Pointer",          &Id.TypeInfo_Pointer          },
        { "TypeInfo_Vector",           &Id.TypeInfo_Vector           },
        { "TypeInfo_Array",            &Id.TypeInfo_Array            },
        { "TypeInfo_StaticArray",      &Id.TypeInfo_StaticArray      },
        { "TypeInfo_AssociativeArray", &Id.TypeInfo_AssociativeArray },
        { "TypeInfo_Function",         &Id.TypeInfo_Function         },
        { "TypeInfo_Delegate",         &Id.TypeInfo_Delegate         },
        { "TypeInfo_Tuple",            &Id.TypeInfo_Tuple            },
        { "TypeInfo_Const",            &Id.TypeInfo_Const            },
        { "TypeInfo_Invariant",        &Id.TypeInfo_Invariant        },
        { "TypeInfo_Shared",           &Id.TypeInfo_Shared           },
        { "TypeInfo_Inout",            &Id.TypeInfo_Wild             },
        { "elements",                  &Id.elements                  },
        { "_arguments_typeinfo",       &Id._arguments_typeinfo       },
        { "_arguments",                &Id._arguments                },
        { "_argptr",                   &Id._argptr                   },
        { "_match",                    &Id._match                    },
        { "destroy",                   &Id.destroy                   },
        { "postblit",                  &Id.postblit                  },
        { "__LINE__",                  &Id.LINE                      },
        { "__FILE__",                  &Id.FILE                      },
        { "__DATE__",                  &Id.DATE                      },
        { "__TIME__",                  &Id.TIME                      },
        { "__TIMESTAMP__",             &Id.TIMESTAMP                 },
        { "__VENDOR__",                &Id.VENDOR                    },
        { "__VERSION__",               &Id.VERSIONX                  },
        { "__EOF__",                   &Id.EOFX                      },
        { "nan",                       &Id.nan                       },
        { "infinity",                  &Id.infinity                  },
        { "dig",                       &Id.dig                       },
        { "epsilon",                   &Id.epsilon                   },
        { "mant_dig",                  &Id.mant_dig                  },
        { "max_10_exp",                &Id.max_10_exp                },
        { "max_exp",                   &Id.max_exp                   },
        { "min_10_exp",                &Id.min_10_exp                },
        { "min_exp",                   &Id.min_exp                   },
        { "min_normal",                &Id.min_normal                },
        { "re",                        &Id.re                        },
        { "im",                        &Id.im                        },
        { "C",                         &Id.C                         },
        { "D",                         &Id.D                         },
        { "Windows",                   &Id.Windows                   },
        { "Pascal",                    &Id.Pascal                    },
        { "System",                    &Id.System                    },
        { "exit",                      &Id.exit                      },
        { "success",                   &Id.success                   },
        { "failure",                   &Id.failure                   },
        { "keys",                      &Id.keys                      },
        { "values",                    &Id.values                    },
        { "rehash",                    &Id.rehash                    },
        { "sort",                      &Id.sort                      },
        { "reverse",                   &Id.reverse                   },
        { "dup",                       &Id.dup                       },
        { "idup",                      &Id.idup                      },
        { "property",                  &Id.property                  },
        { "safe",                      &Id.safe                      },
        { "trusted",                   &Id.trusted                   },
        { "system",                    &Id.system                    },
        { "disable",                   &Id.disable                   },
        { "out",                       &Id.___out                    },
        { "in",                        &Id.___in                     },
        { "int",                       &Id.__int                     },
        { "$",                         &Id.__dollar                  },
        { "__LOCAL_SIZE",              &Id.__LOCAL_SIZE              },
        { "opPos",                     &Id.uadd                      },
        { "opNeg",                     &Id.neg                       },
        { "opCom",                     &Id.com                       },
        { "opAdd",                     &Id.add                       },
        { "opAdd_r",                   &Id.add_r                     },
        { "opSub",                     &Id.sub                       },
        { "opSub_r",                   &Id.sub_r                     },
        { "opMul",                     &Id.mul                       },
        { "opMul_r",                   &Id.mul_r                     },
        { "opDiv",                     &Id.div                       },
        { "opDiv_r",                   &Id.div_r                     },
        { "opMod",                     &Id.mod                       },
        { "opMod_r",                   &Id.mod_r                     },
        { "opEquals",                  &Id.eq                        },
        { "opCmp",                     &Id.cmp                       },
        { "opAnd",                     &Id.iand                      },
        { "opAnd_r",                   &Id.iand_r                    },
        { "opOr",                      &Id.ior                       },
        { "opOr_r",                    &Id.ior_r                     },
        { "opXor",                     &Id.ixor                      },
        { "opXor_r",                   &Id.ixor_r                    },
        { "opShl",                     &Id.shl                       },
        { "opShl_r",                   &Id.shl_r                     },
        { "opShr",                     &Id.shr                       },
        { "opShr_r",                   &Id.shr_r                     },
        { "opUShr",                    &Id.ushr                      },
        { "opUShr_r",                  &Id.ushr_r                    },
        { "opCat",                     &Id.cat                       },
        { "opCat_r",                   &Id.cat_r                     },
        { "opAssign",                  &Id.assign                    },
        { "opAddAssign",               &Id.addass                    },
        { "opSubAssign",               &Id.subass                    },
        { "opMulAssign",               &Id.mulass                    },
        { "opDivAssign",               &Id.divass                    },
        { "opModAssign",               &Id.modass                    },
        { "opAndAssign",               &Id.andass                    },
        { "opOrAssign",                &Id.orass                     },
        { "opXorAssign",               &Id.xorass                    },
        { "opShlAssign",               &Id.shlass                    },
        { "opShrAssign",               &Id.shrass                    },
        { "opUShrAssign",              &Id.ushrass                   },
        { "opCatAssign",               &Id.catass                    },
        { "opPostInc",                 &Id.postinc                   },
        { "opPostDec",                 &Id.postdec                   },
        { "opIndex",                   &Id.index                     },
        { "opIndexAssign",             &Id.indexass                  },
        { "opSlice",                   &Id.slice                     },
        { "opSliceAssign",             &Id.sliceass                  },
        { "opCall",                    &Id.call                      },
        { "opCast",                    &Id.Cast                      },
        { "opMatch",                   &Id.match                     },
        { "opNext",                    &Id.next                      },
        { "opIn",                      &Id.opIn                      },
        { "opIn_r",                    &Id.opIn_r                    },
        { "opStar",                    &Id.opStar                    },
        { "opDot",                     &Id.opDot                     },
        { "opDispatch",                &Id.opDispatch                },
        { "opDollar",                  &Id.opDollar                  },
        { "opUnary",                   &Id.opUnary                   },
        { "opIndexUnary",              &Id.opIndexUnary              },
        { "opSliceUnary",              &Id.opSliceUnary              },
        { "opBinary",                  &Id.opBinary                  },
        { "opBinaryRight",             &Id.opBinaryRight             },
        { "opOpAssign",                &Id.opOpAssign                },
        { "opIndexOpAssign",           &Id.opIndexOpAssign           },
        { "opSliceOpAssign",           &Id.opSliceOpAssign           },
        { "opPow",                     &Id.pow                       },
        { "opPow_r",                   &Id.pow_r                     },
        { "opPowAssign",               &Id.powass                    },
        { "new",                       &Id.classNew                  },
        { "delete",                    &Id.classDelete               },
        { "opApply",                   &Id.apply                     },
        { "opApplyReverse",            &Id.applyReverse              },
        { "empty",                     &Id.Fempty                    },
        { "front",                     &Id.Ffront                    },
        { "back",                      &Id.Fback                     },
        { "popFront",                  &Id.FpopFront                 },
        { "popBack",                   &Id.FpopBack                  },
        { "_adDupT",                   &Id.adDup                     },
        { "_adReverse",                &Id.adReverse                 },
        { "_aaLen",                    &Id.aaLen                     },
        { "_aaKeys",                   &Id.aaKeys                    },
        { "_aaValues",                 &Id.aaValues                  },
        { "_aaRehash",                 &Id.aaRehash                  },
        { "_d_monitorenter",           &Id.monitorenter              },
        { "_d_monitorexit",            &Id.monitorexit               },
        { "_d_criticalenter",          &Id.criticalenter             },
        { "_d_criticalexit",           &Id.criticalexit              },
        { "_ArrayEq",                  &Id._ArrayEq                  },
        { "GNU_asm",                   &Id.GNU_asm                   },
        { "lib",                       &Id.lib                       },
        { "msg",                       &Id.msg                       },
        { "startaddress",              &Id.startaddress              },
        { "toHash",                    &Id.tohash                    },
        { "toString",                  &Id.tostring                  },
        { "getMembers",                &Id.getmembers                },
        { "alloca",                    &Id.__alloca                  },
        { "main",                      &Id.main                      },
        { "WinMain",                   &Id.WinMain                   },
        { "DllMain",                   &Id.DllMain                   },
        { "___tls_get_addr",           &Id.tls_get_addr              },
        { "__va_argsave_t",            &Id.va_argsave_t              },
        { "__va_argsave",              &Id.va_argsave                },
        { "std",                       &Id.std                       },
        { "core",                      &Id.core                      },
        { "math",                      &Id.math                      },
        { "sin",                       &Id.sin                       },
        { "cos",                       &Id.cos                       },
        { "tan",                       &Id.tan                       },
        { "sqrt",                      &Id._sqrt                     },
        { "pow",                       &Id._pow                      },
        { "atan2",                     &Id.atan2                     },
        { "rndtol",                    &Id.rndtol                    },
        { "expm1",                     &Id.expm1                     },
        { "exp2",                      &Id.exp2                      },
        { "yl2x",                      &Id.yl2x                      },
        { "yl2xp1",                    &Id.yl2xp1                    },
        { "fabs",                      &Id.fabs                      },
        { "bitop",                     &Id.bitop                     },
        { "bsf",                       &Id.bsf                       },
        { "bsr",                       &Id.bsr                       },
        { "bswap",                     &Id.bswap                     },
        { "isAbstractClass",           &Id.isAbstractClass           },
        { "isArithmetic",              &Id.isArithmetic              },
        { "isAssociativeArray",        &Id.isAssociativeArray        },
        { "isFinalClass",              &Id.isFinalClass              },
        { "isFloating",                &Id.isFloating                },
        { "isIntegral",                &Id.isIntegral                },
        { "isScalar",                  &Id.isScalar                  },
        { "isStaticArray",             &Id.isStaticArray             },
        { "isUnsigned",                &Id.isUnsigned                },
        { "isVirtualFunction",         &Id.isVirtualFunction         },
        { "isVirtualMethod",           &Id.isVirtualMethod           },
        { "isAbstractFunction",        &Id.isAbstractFunction        },
        { "isFinalFunction",           &Id.isFinalFunction           },
        { "isStaticFunction",          &Id.isStaticFunction          },
        { "isRef",                     &Id.isRef                     },
        { "isOut",                     &Id.isOut                     },
        { "isLazy",                    &Id.isLazy                    },
        { "hasMember",                 &Id.hasMember                 },
        { "identifier",                &Id.identifier                },
        { "parent",                    &Id.parent                    },
        { "getMember",                 &Id.getMember                 },
        { "getOverloads",              &Id.getOverloads              },
        { "getVirtualFunctions",       &Id.getVirtualFunctions       },
        { "getVirtualMethods",         &Id.getVirtualMethods         },
        { "classInstanceSize",         &Id.classInstanceSize         },
        { "allMembers",                &Id.allMembers                },
        { "derivedMembers",            &Id.derivedMembers            },
        { "isSame",                    &Id.isSame                    },
        { "compiles",                  &Id.compiles                  },
        { "parameters",                &Id.parameters                },
    ];

    return idlist;
}
