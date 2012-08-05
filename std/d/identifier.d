module std.d.identifier;

import core.stdc.stdio : stdout, fprintf;
import core.stdc.string : memcmp, strlen;

import std.d.stringtable;
import std.d.lexer;

import std.outbuffer;

enum DYNCAST
{
    DYNCAST_OBJECT,
    DYNCAST_EXPRESSION,
    DYNCAST_DSYMBOL,
    DYNCAST_TYPE,
    DYNCAST_IDENTIFIER,
    DYNCAST_TUPLE,
}

struct Identifier
{
    int value;
    const char *str;
    uint len;

    this(const char *s, int v)
    {
        //printf("Identifier('%s', %d)\n", s, v);
        str = s;
        value = v;
        len = cast(uint)strlen(s);
    }

    int equals(Identifier *o)
    {
        return &this == o || memcmp(str, o.toChars(), len+1) == 0;
    }

    hash_t hashCode()
    {
        return calcHash(str, len);
    }

    int compare(Identifier *o)
    {
        return memcmp(str, o.toChars(), len + 1);
    }

    void print()
    {
        fprintf(stdout, "%s", str);
    }

    char *toChars()
    {
        return cast(char*)str;
    }

    //char *toHChars();
    const(char)* toHChars2()
    {
        const(char)* p = null;

        if (&this == Id.ctor) p = "this".ptr;
        else if (&this == Id.dtor) p = "~this".ptr;
        else if (&this == Id.classInvariant) p = "invariant".ptr;
        else if (&this == Id.unitTest) p = "unittest".ptr;
        else if (&this == Id.dollar) p = "$".ptr;
        else if (&this == Id.withSym) p = "with".ptr;
        else if (&this == Id.result) p = "result".ptr;
        else if (&this == Id.returnLabel) p = "return".ptr;
        else
        {   p = toChars();
            if (*p == '_')
            {
                if (memcmp(p, "_staticCtor".ptr, 11) == 0)
                    p = "static this".ptr;
                else if (memcmp(p, "_staticDtor".ptr, 11) == 0)
                    p = "static ~this".ptr;
            }
        }

        return p;
    }

    int dyncast()
    {
        return DYNCAST.DYNCAST_IDENTIFIER;
    }

    // BUG: these are redundant with Lexer.uniqueId()
    static Identifier *generateId(const char *prefix)
    {
        static size_t i;

        return generateId(prefix, ++i);
    }

    static Identifier *generateId(const char *prefix, size_t i)
    {
        OutBuffer buf = new OutBuffer();
        scope(exit) delete buf;

        buf.write(prefix[0 .. strlen(prefix)]);
        buf.printf("%llu", cast(ulong)i);

        const char *id = buf.toString().ptr;
        buf.reset();
        return Lexer.idPool(id);
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

    static void initialize()
    {
        IUnknown = Lexer.idPool("IUnknown");
        Object = Lexer.idPool("Object");
        object = Lexer.idPool("object");
        max = Lexer.idPool("max");
        min = Lexer.idPool("min");
        This = Lexer.idPool("this");
        Super = Lexer.idPool("super");
        ctor = Lexer.idPool("__ctor");
        dtor = Lexer.idPool("__dtor");
        cpctor = Lexer.idPool("__cpctor");
        _postblit = Lexer.idPool("__postblit");
        classInvariant = Lexer.idPool("__invariant");
        unitTest = Lexer.idPool("__unitTest");
        require = Lexer.idPool("__require");
        ensure = Lexer.idPool("__ensure");
        init = Lexer.idPool("init");
        size = Lexer.idPool("size");
        __sizeof = Lexer.idPool("sizeof");
        __xalignof = Lexer.idPool("alignof");
        Mangleof = Lexer.idPool("mangleof");
        Stringof = Lexer.idPool("stringof");
        Tupleof = Lexer.idPool("tupleof");
        length = Lexer.idPool("length");
        remove = Lexer.idPool("remove");
        ptr = Lexer.idPool("ptr");
        array = Lexer.idPool("array");
        funcptr = Lexer.idPool("funcptr");
        dollar = Lexer.idPool("__dollar");
        ctfe = Lexer.idPool("__ctfe");
        offset = Lexer.idPool("offset");
        offsetof = Lexer.idPool("offsetof");
        ModuleInfo = Lexer.idPool("ModuleInfo");
        ClassInfo = Lexer.idPool("ClassInfo");
        classinfo = Lexer.idPool("classinfo");
        typeinfo = Lexer.idPool("typeinfo");
        outer = Lexer.idPool("outer");
        Exception = Lexer.idPool("Exception");
        AssociativeArray = Lexer.idPool("AssociativeArray");
        RTInfo = Lexer.idPool("RTInfo");
        Throwable = Lexer.idPool("Throwable");
        Error = Lexer.idPool("Error");
        withSym = Lexer.idPool("__withSym");
        result = Lexer.idPool("__result");
        returnLabel = Lexer.idPool("__returnLabel");
        Delegate = Lexer.idPool("delegate");
        line = Lexer.idPool("line");
        empty = Lexer.idPool("");
        p = Lexer.idPool("p");
        q = Lexer.idPool("q");
        coverage = Lexer.idPool("__coverage");
        __vptr = Lexer.idPool("__vptr");
        __monitor = Lexer.idPool("__monitor");
        TypeInfo = Lexer.idPool("TypeInfo");
        TypeInfo_Class = Lexer.idPool("TypeInfo_Class");
        TypeInfo_Interface = Lexer.idPool("TypeInfo_Interface");
        TypeInfo_Struct = Lexer.idPool("TypeInfo_Struct");
        TypeInfo_Enum = Lexer.idPool("TypeInfo_Enum");
        TypeInfo_Typedef = Lexer.idPool("TypeInfo_Typedef");
        TypeInfo_Pointer = Lexer.idPool("TypeInfo_Pointer");
        TypeInfo_Vector = Lexer.idPool("TypeInfo_Vector");
        TypeInfo_Array = Lexer.idPool("TypeInfo_Array");
        TypeInfo_StaticArray = Lexer.idPool("TypeInfo_StaticArray");
        TypeInfo_AssociativeArray = Lexer.idPool("TypeInfo_AssociativeArray");
        TypeInfo_Function = Lexer.idPool("TypeInfo_Function");
        TypeInfo_Delegate = Lexer.idPool("TypeInfo_Delegate");
        TypeInfo_Tuple = Lexer.idPool("TypeInfo_Tuple");
        TypeInfo_Const = Lexer.idPool("TypeInfo_Const");
        TypeInfo_Invariant = Lexer.idPool("TypeInfo_Invariant");
        TypeInfo_Shared = Lexer.idPool("TypeInfo_Shared");
        TypeInfo_Wild = Lexer.idPool("TypeInfo_Inout");
        elements = Lexer.idPool("elements");
        _arguments_typeinfo = Lexer.idPool("_arguments_typeinfo");
        _arguments = Lexer.idPool("_arguments");
        _argptr = Lexer.idPool("_argptr");
        _match = Lexer.idPool("_match");
        destroy = Lexer.idPool("destroy");
        postblit = Lexer.idPool("postblit");
        LINE = Lexer.idPool("__LINE__");
        FILE = Lexer.idPool("__FILE__");
        DATE = Lexer.idPool("__DATE__");
        TIME = Lexer.idPool("__TIME__");
        TIMESTAMP = Lexer.idPool("__TIMESTAMP__");
        VENDOR = Lexer.idPool("__VENDOR__");
        VERSIONX = Lexer.idPool("__VERSION__");
        EOFX = Lexer.idPool("__EOF__");
        nan = Lexer.idPool("nan");
        infinity = Lexer.idPool("infinity");
        dig = Lexer.idPool("dig");
        epsilon = Lexer.idPool("epsilon");
        mant_dig = Lexer.idPool("mant_dig");
        max_10_exp = Lexer.idPool("max_10_exp");
        max_exp = Lexer.idPool("max_exp");
        min_10_exp = Lexer.idPool("min_10_exp");
        min_exp = Lexer.idPool("min_exp");
        min_normal = Lexer.idPool("min_normal");
        re = Lexer.idPool("re");
        im = Lexer.idPool("im");
        C = Lexer.idPool("C");
        D = Lexer.idPool("D");
        Windows = Lexer.idPool("Windows");
        Pascal = Lexer.idPool("Pascal");
        System = Lexer.idPool("System");
        exit = Lexer.idPool("exit");
        success = Lexer.idPool("success");
        failure = Lexer.idPool("failure");
        keys = Lexer.idPool("keys");
        values = Lexer.idPool("values");
        rehash = Lexer.idPool("rehash");
        sort = Lexer.idPool("sort");
        reverse = Lexer.idPool("reverse");
        dup = Lexer.idPool("dup");
        idup = Lexer.idPool("idup");
        property = Lexer.idPool("property");
        safe = Lexer.idPool("safe");
        trusted = Lexer.idPool("trusted");
        system = Lexer.idPool("system");
        disable = Lexer.idPool("disable");
        ___out = Lexer.idPool("out");
        ___in = Lexer.idPool("in");
        __int = Lexer.idPool("int");
        __dollar = Lexer.idPool("$");
        __LOCAL_SIZE = Lexer.idPool("__LOCAL_SIZE");
        uadd = Lexer.idPool("opPos");
        neg = Lexer.idPool("opNeg");
        com = Lexer.idPool("opCom");
        add = Lexer.idPool("opAdd");
        add_r = Lexer.idPool("opAdd_r");
        sub = Lexer.idPool("opSub");
        sub_r = Lexer.idPool("opSub_r");
        mul = Lexer.idPool("opMul");
        mul_r = Lexer.idPool("opMul_r");
        div = Lexer.idPool("opDiv");
        div_r = Lexer.idPool("opDiv_r");
        mod = Lexer.idPool("opMod");
        mod_r = Lexer.idPool("opMod_r");
        eq = Lexer.idPool("opEquals");
        cmp = Lexer.idPool("opCmp");
        iand = Lexer.idPool("opAnd");
        iand_r = Lexer.idPool("opAnd_r");
        ior = Lexer.idPool("opOr");
        ior_r = Lexer.idPool("opOr_r");
        ixor = Lexer.idPool("opXor");
        ixor_r = Lexer.idPool("opXor_r");
        shl = Lexer.idPool("opShl");
        shl_r = Lexer.idPool("opShl_r");
        shr = Lexer.idPool("opShr");
        shr_r = Lexer.idPool("opShr_r");
        ushr = Lexer.idPool("opUShr");
        ushr_r = Lexer.idPool("opUShr_r");
        cat = Lexer.idPool("opCat");
        cat_r = Lexer.idPool("opCat_r");
        assign = Lexer.idPool("opAssign");
        addass = Lexer.idPool("opAddAssign");
        subass = Lexer.idPool("opSubAssign");
        mulass = Lexer.idPool("opMulAssign");
        divass = Lexer.idPool("opDivAssign");
        modass = Lexer.idPool("opModAssign");
        andass = Lexer.idPool("opAndAssign");
        orass = Lexer.idPool("opOrAssign");
        xorass = Lexer.idPool("opXorAssign");
        shlass = Lexer.idPool("opShlAssign");
        shrass = Lexer.idPool("opShrAssign");
        ushrass = Lexer.idPool("opUShrAssign");
        catass = Lexer.idPool("opCatAssign");
        postinc = Lexer.idPool("opPostInc");
        postdec = Lexer.idPool("opPostDec");
        index = Lexer.idPool("opIndex");
        indexass = Lexer.idPool("opIndexAssign");
        slice = Lexer.idPool("opSlice");
        sliceass = Lexer.idPool("opSliceAssign");
        call = Lexer.idPool("opCall");
        Cast = Lexer.idPool("opCast");
        match = Lexer.idPool("opMatch");
        next = Lexer.idPool("opNext");
        opIn = Lexer.idPool("opIn");
        opIn_r = Lexer.idPool("opIn_r");
        opStar = Lexer.idPool("opStar");
        opDot = Lexer.idPool("opDot");
        opDispatch = Lexer.idPool("opDispatch");
        opDollar = Lexer.idPool("opDollar");
        opUnary = Lexer.idPool("opUnary");
        opIndexUnary = Lexer.idPool("opIndexUnary");
        opSliceUnary = Lexer.idPool("opSliceUnary");
        opBinary = Lexer.idPool("opBinary");
        opBinaryRight = Lexer.idPool("opBinaryRight");
        opOpAssign = Lexer.idPool("opOpAssign");
        opIndexOpAssign = Lexer.idPool("opIndexOpAssign");
        opSliceOpAssign = Lexer.idPool("opSliceOpAssign");
        pow = Lexer.idPool("opPow");
        pow_r = Lexer.idPool("opPow_r");
        powass = Lexer.idPool("opPowAssign");
        classNew = Lexer.idPool("new");
        classDelete = Lexer.idPool("delete");
        apply = Lexer.idPool("opApply");
        applyReverse = Lexer.idPool("opApplyReverse");
        Fempty = Lexer.idPool("empty");
        Ffront = Lexer.idPool("front");
        Fback = Lexer.idPool("back");
        FpopFront = Lexer.idPool("popFront");
        FpopBack = Lexer.idPool("popBack");
        adDup = Lexer.idPool("_adDupT");
        adReverse = Lexer.idPool("_adReverse");
        aaLen = Lexer.idPool("_aaLen");
        aaKeys = Lexer.idPool("_aaKeys");
        aaValues = Lexer.idPool("_aaValues");
        aaRehash = Lexer.idPool("_aaRehash");
        monitorenter = Lexer.idPool("_d_monitorenter");
        monitorexit = Lexer.idPool("_d_monitorexit");
        criticalenter = Lexer.idPool("_d_criticalenter");
        criticalexit = Lexer.idPool("_d_criticalexit");
        _ArrayEq = Lexer.idPool("_ArrayEq");
        GNU_asm = Lexer.idPool("GNU_asm");
        lib = Lexer.idPool("lib");
        msg = Lexer.idPool("msg");
        startaddress = Lexer.idPool("startaddress");
        tohash = Lexer.idPool("toHash");
        tostring = Lexer.idPool("toString");
        getmembers = Lexer.idPool("getMembers");
        __alloca = Lexer.idPool("alloca");
        main = Lexer.idPool("main");
        WinMain = Lexer.idPool("WinMain");
        DllMain = Lexer.idPool("DllMain");
        tls_get_addr = Lexer.idPool("___tls_get_addr");
        va_argsave_t = Lexer.idPool("__va_argsave_t");
        va_argsave = Lexer.idPool("__va_argsave");
        std = Lexer.idPool("std");
        core = Lexer.idPool("core");
        math = Lexer.idPool("math");
        sin = Lexer.idPool("sin");
        cos = Lexer.idPool("cos");
        tan = Lexer.idPool("tan");
        _sqrt = Lexer.idPool("sqrt");
        _pow = Lexer.idPool("pow");
        atan2 = Lexer.idPool("atan2");
        rndtol = Lexer.idPool("rndtol");
        expm1 = Lexer.idPool("expm1");
        exp2 = Lexer.idPool("exp2");
        yl2x = Lexer.idPool("yl2x");
        yl2xp1 = Lexer.idPool("yl2xp1");
        fabs = Lexer.idPool("fabs");
        bitop = Lexer.idPool("bitop");
        bsf = Lexer.idPool("bsf");
        bsr = Lexer.idPool("bsr");
        bswap = Lexer.idPool("bswap");
        isAbstractClass = Lexer.idPool("isAbstractClass");
        isArithmetic = Lexer.idPool("isArithmetic");
        isAssociativeArray = Lexer.idPool("isAssociativeArray");
        isFinalClass = Lexer.idPool("isFinalClass");
        isFloating = Lexer.idPool("isFloating");
        isIntegral = Lexer.idPool("isIntegral");
        isScalar = Lexer.idPool("isScalar");
        isStaticArray = Lexer.idPool("isStaticArray");
        isUnsigned = Lexer.idPool("isUnsigned");
        isVirtualFunction = Lexer.idPool("isVirtualFunction");
        isVirtualMethod = Lexer.idPool("isVirtualMethod");
        isAbstractFunction = Lexer.idPool("isAbstractFunction");
        isFinalFunction = Lexer.idPool("isFinalFunction");
        isStaticFunction = Lexer.idPool("isStaticFunction");
        isRef = Lexer.idPool("isRef");
        isOut = Lexer.idPool("isOut");
        isLazy = Lexer.idPool("isLazy");
        hasMember = Lexer.idPool("hasMember");
        identifier = Lexer.idPool("identifier");
        parent = Lexer.idPool("parent");
        getMember = Lexer.idPool("getMember");
        getOverloads = Lexer.idPool("getOverloads");
        getVirtualFunctions = Lexer.idPool("getVirtualFunctions");
        getVirtualMethods = Lexer.idPool("getVirtualMethods");
        classInstanceSize = Lexer.idPool("classInstanceSize");
        allMembers = Lexer.idPool("allMembers");
        derivedMembers = Lexer.idPool("derivedMembers");
        isSame = Lexer.idPool("isSame");
        compiles = Lexer.idPool("compiles");
        parameters = Lexer.idPool("parameters");
    }
}

