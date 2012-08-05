module std.d.lexer;

import core.memory;
import core.vararg;

import core.stdc.ctype;
import core.stdc.errno;
import core.stdc.stdio : sprintf;
import core.stdc.stdlib : strtoull, strtold, strtod, strtof;
import core.stdc.string : memset, strdup, strlen;
import core.stdc.time;

import std.d.htmlentity;
import std.d.identifier;
import std.d.keywords;
import std.d.stringtable;
import std.d.token;

import std.outbuffer;
import std.uni;
import std.utf;

enum LS = 0x2028;      // UTF line separator
enum PS = 0x2029;      // UTF paragraph separator

enum GLOBAL_VERSION = "v2.060";
enum GLOBAL_USE_DEPRECATED = false;

static this()
{
    Lexer.stringbuffer = new OutBuffer;
    Lexer.stringtable.init(6151);
    init_charmap();
    init_keywords();

    foreach_keyword((ref const Keyword k)
    {
        const char *s = k.name;
        TOK v = k.value;
        StringValue *sv = Lexer.stringtable.insert(s, cast(uint)strlen(s));
        sv.ptrvalue = cast(void *) new Identifier(sv.toDchars(),v);

        Token.tochars[v] = s;
    });
}

struct Loc
{
    string filename;
    uint linnum;

    char* toChars()
    {
        OutBuffer buf = new OutBuffer();
        scope(exit) delete buf;

        if (filename)
            buf.printf("%s", filename);

        if (linnum)
            buf.printf("(%d)", linnum);
        buf.write(cast(byte)0);
        ubyte[] b = buf.toBytes();
        buf.reset();

        return cast(char *)b.ptr;
    }
}

/*************************** Lexer ********************************************/

struct Lexer
{
    static StringTable stringtable;
    static OutBuffer stringbuffer;
    static Token *freelist = null;

    Loc loc;                    // for error messages

    byte *base;        // pointer to start of buffer
    byte *end;         // past end of buffer
    byte *p;           // current character
    Token token;
    string mod;
    int doDocComment;           // collect doc comment information
    int anyToken;               // !=0 means seen at least one token
    int commentToken;           // !=0 means comments are TOKcomment's

    this(string mod,
        byte *base, uint begoffset, uint endoffset,
        int doDocComment, int commentToken)
    {
        loc = Loc(mod, 1);

        //printf("Lexer::Lexer(%p,%d)\n",base,length);
        //printf("lexer.mod = %p, %p\n", mod, this.loc.mod);
        memset(&token, 0, token.sizeof);
        this.base = base;
        this.end  = base + endoffset;
        p = base + begoffset;
        this.mod = mod;
        this.doDocComment = doDocComment;
        this.anyToken = 0;
        this.commentToken = commentToken;
        //initKeywords();

        /* If first line starts with '#!', ignore the line
         */

        if (p[0] == '#' && p[1] =='!')
        {
            p += 2;
            while (1)
            {   byte c = *p;
                switch (c)
                {
                    case '\n':
                        p++;
                        break;

                    case '\r':
                        p++;
                        if (*p == '\n')
                            p++;
                        break;

                    case 0:
                    case 0x1A:
                        break;

                    default:
                        if (c & 0x80)
                        {   uint u = decodeUTF();
                            if (u == PS || u == LS)
                                break;
                        }
                        p++;
                        continue;
                }
                break;
            }
            loc.linnum = 2;
        }
    }

    static void initKeywords();

    /********************************************
     * Create an identifier in the string table.
     */
    static Identifier *idPool(const char *s)
    {
        size_t len = strlen(s);
        StringValue *sv = stringtable.update(s, cast(uint)len);
        Identifier *id = cast(Identifier *) sv.ptrvalue;
        if (!id)
        {
            id = new Identifier(sv.toDchars(), TOK.TOKidentifier);
            sv.ptrvalue = id;
        }
        return id;
    }

    static Identifier *uniqueId(const char *s)
    {
        static int num;
        return uniqueId(s, ++num);
    }

    /*********************************************
     * Create a unique identifier using the prefix s.
     */
    static Identifier *uniqueId(const char *s, int num)
    {
        char buffer[32];
        size_t slen = strlen(s);

        assert(slen + num.sizeof * 3 + 1 <= buffer.sizeof);
        sprintf(buffer, "%s%d", s, num);
        return idPool(buffer);
    }

    TOK nextToken()
    {
        if (token.next)
        {
            Token *t = token.next;
            memcpy(&token, t, Token.sizeof);
            t.next = freelist;
            freelist = t;
        }
        else
        {
            scan(&token);
        }
        //token.print();
        return token.value;
    }

    /***********************
     * Look ahead at next token's value.
     */
    TOK peekNext()
    {
        return peek(&token).value;
    }

    /***********************
     * Look 2 tokens ahead at value.
     */
    TOK peekNext2()
    {
        Token *t = peek(&token);
        return peek(t).value;
    }

    /****************************
     * Turn next token in buffer into a token.
     */
    void scan(Token *t)
    {
        uint lastLine = loc.linnum;
        uint linnum;

        t.blockComment = null;
        t.lineComment = null;
        while (1)
        {
            assert(base <= p && p <= end);
            t.ptr = p;
            //printf("offset = %6ld, p = %p, *p = '%c'\n", p - base, p, *p);
            switch (*p)
            {
                case 0:
                case 0x1A:
                    t.value = TOK.TOKeof;                      // end of file
                    return;

                case ' ':
                case '\t':
                case '\v':
                case '\f':
                    p++;
                    continue;                       // skip white space

                case '\r':
                    p++;
                    if (*p != '\n')                 // if CR stands by itself
                        loc.linnum++;
                    continue;                       // skip white space

                case '\n':
                    p++;
                    loc.linnum++;
                    continue;                       // skip white space

                case '0':   case '1':   case '2':   case '3':   case '4':
                case '5':   case '6':   case '7':   case '8':   case '9':
                    t.value = number(t);
                    return;

                case '\'':
                    t.value = charConstant(t,0);
                    return;

                case 'r':
                    if (p[1] != '"')
                        goto case_ident;
                    p++;
                    goto case; // fallthru
                case '`':
                    t.value = wysiwygStringConstant(t, *p);
                    return;

                case 'x':
                    if (p[1] != '"')
                        goto case_ident;
                    p++;
                    t.value = hexStringConstant(t);
                    return;

                case 'q':
                    if (p[1] == '"')
                    {
                        p++;
                        t.value = delimitedStringConstant(t);
                        return;
                    }
                    else if (p[1] == '{')
                    {
                        p++;
                        t.value = tokenStringConstant(t);
                        return;
                    }
                    else
                        goto case_ident;

                case '"':
                    t.value = escapeStringConstant(t,0);
                    return;

                case '\\':                  // escaped string literal
                {   uint c;
                    byte *pstart = p;

                    stringbuffer.reset();
                    do
                    {
                        p++;
                        switch (*p)
                        {
                            case 'u':
                            case 'U':
                            case '&':
                            {
                                c = escapeSequence();
                                char[4] buf;
                                size_t l = encode(buf, c);
                                stringbuffer.write(buf[0 .. l]);
                                break;
                            }

                            default:
                                c = escapeSequence();
                                stringbuffer.write(cast(byte)c);
                                break;
                        }
                    } while (*p == '\\');
                    t.len = cast(uint)stringbuffer.offset;
                    stringbuffer.write(cast(byte)0);
                    t.ustring = cast(byte*)GC.malloc(stringbuffer.offset);
                    memcpy(t.ustring, cast(char*)stringbuffer.data.ptr, stringbuffer.offset);
                    t.postfix = 0;
                    t.value = TOK.TOKstring;
                    if (!GLOBAL_USE_DEPRECATED)
                        error("Escape String literal %.*s is deprecated, use double quoted string literal \"%.*s\" instead", p - pstart, pstart, p - pstart, pstart);
                    return;
                }

                case 'a':   case 'b':   case 'c':   case 'd':   case 'e':
                case 'f':   case 'g':   case 'h':   case 'i':   case 'j':
                case 'k':   case 'l':   case 'm':   case 'n':   case 'o':
                case 'p':   /*case 'q': case 'r':*/ case 's':   case 't':
                case 'u':   case 'v':   case 'w': /*case 'x':*/ case 'y':
                case 'z':
                case 'A':   case 'B':   case 'C':   case 'D':   case 'E':
                case 'F':   case 'G':   case 'H':   case 'I':   case 'J':
                case 'K':   case 'L':   case 'M':   case 'N':   case 'O':
                case 'P':   case 'Q':   case 'R':   case 'S':   case 'T':
                case 'U':   case 'V':   case 'W':   case 'X':   case 'Y':
                case 'Z':
                case '_':
                case_ident:
                {
                    while (1)
                    {
                        byte c = *++p;
                        if (isidchar(c))
                            continue;
                        else if (c & 0x80)
                        {
                            byte *s = p;
                            uint u = decodeUTF();
                            if (isAlpha(u))
                                continue;
                            error("char 0x%04x not allowed in identifier", u);
                            p = s;
                        }
                        break;
                    }

                    StringValue *sv = stringtable.update(cast(const(char*))t.ptr, cast(uint)(p - t.ptr));
                    Identifier *id = cast(Identifier *) sv.ptrvalue;
                    if (!id)
                    {   id = new Identifier(sv.toDchars(), TOK.TOKidentifier);
                        sv.ptrvalue = id;
                    }
                    t.ident = id;
                    t.value = cast(TOK) id.value;
                    anyToken = 1;
                    if (*t.ptr == '_')     // if special identifier token
                    {
                        static char date[11+1];
                        static char time[8+1];
                        static char timestamp[24+1];

                        if (!date[0])       // lazy evaluation
                        {
                            core.stdc.time.time_t t;
                            core.stdc.time.time(&t);
                            char* p = ctime(&t);
                            assert(p);
                            sprintf(date, "%.6s %.4s", p + 4, p + 20);
                            sprintf(time, "%.8s", p + 11);
                            sprintf(timestamp, "%.24s", p);
                        }

                        if (id == Id.DATE)
                        {
                            t.ustring = cast(byte*)date;
                            goto Lstr;
                        }
                        else if (id == Id.TIME)
                        {
                            t.ustring = cast(byte*)time;
                            goto Lstr;
                        }
                        else if (id == Id.VENDOR)
                        {
                            t.ustring = cast(byte*)("Digital Mars D".ptr);
                            goto Lstr;
                        }
                        else if (id == Id.TIMESTAMP)
                        {
                            t.ustring = cast(byte*)timestamp;
                         Lstr:
                            t.value = TOK.TOKstring;
                            t.postfix = 0;
                            t.len = cast(uint)strlen(cast(char*)t.ustring);
                        }
                        else if (id == Id.VERSIONX)
                        {   uint major = 0;
                            uint minor = 0;

                            for (const(char)* p = GLOBAL_VERSION.ptr + 1; 1; p++)
                            {
                                char c = *p;
                                if (isdigit(c))
                                    minor = minor * 10 + c - '0';
                                else if (c == '.')
                                {   major = minor;
                                    minor = 0;
                                }
                                else
                                    break;
                            }
                            t.value = TOK.TOKint64v;
                            t.uns64value = major * 1000 + minor;
                        }
                        else if (id == Id.EOFX)
                        {
                            t.value = TOK.TOKeof;
                            // Advance scanner to end of file
                            while (!(*p == 0 || *p == 0x1A))
                                p++;
                        }
                    }
                    //printf("t.value = %d\n",t.value);
                    return;
                }

                case '/':
                    p++;
                    switch (*p)
                    {
                        case '=':
                            p++;
                            t.value = TOK.TOKdivass;
                            return;

                        case '*':
                            p++;
                            linnum = loc.linnum;
                            while (1)
                            {
                                while (1)
                                {   byte c = *p;
                                    switch (c)
                                    {
                                        case '/':
                                            break;

                                        case '\n':
                                            loc.linnum++;
                                            p++;
                                            continue;

                                        case '\r':
                                            p++;
                                            if (*p != '\n')
                                                loc.linnum++;
                                            continue;

                                        case 0:
                                        case 0x1A:
                                            error("unterminated /* */ comment");
                                            p = end;
                                            t.value = TOK.TOKeof;
                                            return;

                                        default:
                                            if (c & 0x80)
                                            {   uint u = decodeUTF();
                                                if (u == PS || u == LS)
                                                    loc.linnum++;
                                            }
                                            p++;
                                            continue;
                                    }
                                    break;
                                }
                                p++;
                                if (p[-2] == '*' && p - 3 != t.ptr)
                                    break;
                            }
                            if (commentToken)
                            {
                                t.value = TOK.TOKcomment;
                                return;
                            }
                            else if (doDocComment && t.ptr[2] == '*' && p - 4 != t.ptr)
                            {   // if /** but not /**/
                                getDocComment(t, lastLine == linnum);
                            }
                            continue;

                        case '/':           // do // style comments
                            linnum = loc.linnum;
                            while (1)
                            {   byte c = *++p;
                                switch (c)
                                {
                                    case '\n':
                                        break;

                                    case '\r':
                                        if (p[1] == '\n')
                                            p++;
                                        break;

                                    case 0:
                                    case 0x1A:
                                        if (commentToken)
                                        {
                                            p = end;
                                            t.value = TOK.TOKcomment;
                                            return;
                                        }
                                        if (doDocComment && t.ptr[2] == '/')
                                            getDocComment(t, lastLine == linnum);
                                        p = end;
                                        t.value = TOK.TOKeof;
                                        return;

                                    default:
                                        if (c & 0x80)
                                        {   uint u = decodeUTF();
                                            if (u == PS || u == LS)
                                                break;
                                        }
                                        continue;
                                }
                                break;
                            }

                            if (commentToken)
                            {
                                p++;
                                loc.linnum++;
                                t.value = TOK.TOKcomment;
                                return;
                            }
                            if (doDocComment && t.ptr[2] == '/')
                                getDocComment(t, lastLine == linnum);

                            p++;
                            loc.linnum++;
                            continue;

                        case '+':
                        {   int nest;

                            linnum = loc.linnum;
                            p++;
                            nest = 1;
                            while (1)
                            {   byte c = *p;
                                switch (c)
                                {
                                    case '/':
                                        p++;
                                        if (*p == '+')
                                        {
                                            p++;
                                            nest++;
                                        }
                                        continue;

                                    case '+':
                                        p++;
                                        if (*p == '/')
                                        {
                                            p++;
                                            if (--nest == 0)
                                                break;
                                        }
                                        continue;

                                    case '\r':
                                        p++;
                                        if (*p != '\n')
                                            loc.linnum++;
                                        continue;

                                    case '\n':
                                        loc.linnum++;
                                        p++;
                                        continue;

                                    case 0:
                                    case 0x1A:
                                        error("unterminated /+ +/ comment");
                                        p = end;
                                        t.value = TOK.TOKeof;
                                        return;

                                    default:
                                        if (c & 0x80)
                                        {   uint u = decodeUTF();
                                            if (u == PS || u == LS)
                                                loc.linnum++;
                                        }
                                        p++;
                                        continue;
                                }
                                break;
                            }
                            if (commentToken)
                            {
                                t.value = TOK.TOKcomment;
                                return;
                            }
                            if (doDocComment && t.ptr[2] == '+' && p - 4 != t.ptr)
                            {   // if /++ but not /++/
                                getDocComment(t, lastLine == linnum);
                            }
                            continue;
                        }
                        default:
                            break;
                    }
                    //assert(0);
                    t.value = TOK.TOKdiv;
                    return;

                case '.':
                    p++;
                    if (isdigit(*p))
                    {   /* Note that we don't allow ._1 and ._ as being
                         * valid floating point numbers.
                         */
                        p--;
                        t.value = inreal(t);
                    }
                    else if (p[0] == '.')
                    {
                        if (p[1] == '.')
                        {   p += 2;
                            t.value = TOK.TOKdotdotdot;
                        }
                        else
                        {   p++;
                            t.value = TOK.TOKslice;
                        }
                    }
                    else
                        t.value = TOK.TOKdot;
                    return;

                case '&':
                    p++;
                    if (*p == '=')
                    {   p++;
                        t.value = TOK.TOKandass;
                    }
                    else if (*p == '&')
                    {   p++;
                        t.value = TOK.TOKandand;
                    }
                    else
                        t.value = TOK.TOKand;
                    return;

                case '|':
                    p++;
                    if (*p == '=')
                    {   p++;
                        t.value = TOK.TOKorass;
                    }
                    else if (*p == '|')
                    {   p++;
                        t.value = TOK.TOKoror;
                    }
                    else
                        t.value = TOK.TOKor;
                    return;

                case '-':
                    p++;
                    if (*p == '=')
                    {   p++;
                        t.value = TOK.TOKminass;
                    }
                    else if (*p == '-')
                    {   p++;
                        t.value = TOK.TOKminusminus;
                    }
                    else
                        t.value = TOK.TOKmin;
                    return;

                case '+':
                    p++;
                    if (*p == '=')
                    {   p++;
                        t.value = TOK.TOKaddass;
                    }
                    else if (*p == '+')
                    {   p++;
                        t.value = TOK.TOKplusplus;
                    }
                    else
                        t.value = TOK.TOKadd;
                    return;

                case '<':
                    p++;
                    if (*p == '=')
                    {   p++;
                        t.value = TOK.TOKle;                   // <=
                    }
                    else if (*p == '<')
                    {   p++;
                        if (*p == '=')
                        {   p++;
                            t.value = TOK.TOKshlass;           // <<=
                        }
                        else
                            t.value = TOK.TOKshl;              // <<
                    }
                    else if (*p == '>')
                    {   p++;
                        if (*p == '=')
                        {   p++;
                            t.value = TOK.TOKleg;              // <>=
                        }
                        else
                            t.value = TOK.TOKlg;               // <>
                    }
                    else
                        t.value = TOK.TOKlt;                   // <
                    return;

                case '>':
                    p++;
                    if (*p == '=')
                    {   p++;
                        t.value = TOK.TOKge;                   // >=
                    }
                    else if (*p == '>')
                    {   p++;
                        if (*p == '=')
                        {   p++;
                            t.value = TOK.TOKshrass;           // >>=
                        }
                        else if (*p == '>')
                        {   p++;
                            if (*p == '=')
                            {   p++;
                                t.value = TOK.TOKushrass;      // >>>=
                            }
                            else
                                t.value = TOK.TOKushr;         // >>>
                        }
                        else
                            t.value = TOK.TOKshr;              // >>
                    }
                    else
                        t.value = TOK.TOKgt;                   // >
                    return;

                case '!':
                    p++;
                    if (*p == '=')
                    {   p++;
                        t.value = TOK.TOKnotequal;         // !=
                    }
                    else if (*p == '<')
                    {   p++;
                        if (*p == '>')
                        {   p++;
                            if (*p == '=')
                            {   p++;
                                t.value = TOK.TOKunord; // !<>=
                            }
                            else
                                t.value = TOK.TOKue;   // !<>
                        }
                        else if (*p == '=')
                        {   p++;
                            t.value = TOK.TOKug;       // !<=
                        }
                        else
                            t.value = TOK.TOKuge;      // !<
                    }
                    else if (*p == '>')
                    {   p++;
                        if (*p == '=')
                        {   p++;
                            t.value = TOK.TOKul;       // !>=
                        }
                        else
                            t.value = TOK.TOKule;      // !>
                    }
                    else
                        t.value = TOK.TOKnot;          // !
                    return;

                case '=':
                    p++;
                    if (*p == '=')
                    {   p++;
                        t.value = TOK.TOKequal;            // ==
                    }
                    else if (*p == '>')
                    {   p++;
                        t.value = TOK.TOKgoesto;               // =>
                    }
                    else
                        t.value = TOK.TOKassign;               // =
                    return;

                case '~':
                    p++;
                    if (*p == '=')
                    {   p++;
                        t.value = TOK.TOKcatass;               // ~=
                    }
                    else
                        t.value = TOK.TOKtilde;                // ~
                    return;

                case '^':
                    p++;
                    if (*p == '^')
                    {   p++;
                        if (*p == '=')
                        {   p++;
                            t.value = TOK.TOKpowass;  // ^^=
                        }
                        else
                            t.value = TOK.TOKpow;     // ^^
                    }
                    else if (*p == '=')
                    {   p++;
                        t.value = TOK.TOKxorass;    // ^=
                    }
                    else
                        t.value = TOK.TOKxor;       // ^
                    return;

                case '(': p++; t.value = TOK.TOKlparen;    return;
                case ')': p++; t.value = TOK.TOKrparen;    return;
                case '[': p++; t.value = TOK.TOKlbracket;  return;
                case ']': p++; t.value = TOK.TOKrbracket;  return;
                case '{': p++; t.value = TOK.TOKlcurly;    return;
                case '}': p++; t.value = TOK.TOKrcurly;    return;
                case '?': p++; t.value = TOK.TOKquestion;  return;
                case ',': p++; t.value = TOK.TOKcomma;     return;
                case ';': p++; t.value = TOK.TOKsemicolon; return;
                case ':': p++; t.value = TOK.TOKcolon;     return;
                case '$': p++; t.value = TOK.TOKdollar;    return;
                case '@': p++; t.value = TOK.TOKat;        return;


                case '*':
                    p++;
                    if (*p == '=') { p++; t.value = TOK.TOKmulass; } else t.value = TOK.TOKmul;
                    return;
                case '%':
                    p++;
                    if (*p == '=') { p++; t.value = TOK.TOKmodass; } else t.value = TOK.TOKmod;
                    return;

                case '#':
                {
                    p++;
                    Token n;
                    scan(&n);
                    if (n.value == TOK.TOKidentifier && n.ident == Id.line)
                    {
                        poundLine();
                        continue;
                    }
                    else
                    {
                        t.value = TOK.TOKpound;
                        return;
                    }
                }

                default:
                {
                    uint c = *p;

                    if (c & 0x80)
                    {   c = decodeUTF();

                        // Check for start of unicode identifier
                        if (isAlpha(c))
                            goto case_ident;

                        if (c == PS || c == LS)
                        {
                            loc.linnum++;
                            p++;
                            continue;
                        }
                    }
                    if (c < 0x80 && isprint(c))
                        error("unsupported char '%c'", c);
                    else
                        error("unsupported char 0x%02x", c);
                    p++;
                    continue;
                }
            }
        }
    }

    Token *peek(Token *ct)
    {
        if (ct.next)
            return ct.next;
        else
        {
            Token *t = new Token();
            scan(t);
            ct.next = t;
            return t;
        }
    }

    /*********************************
     * tk is on the opening (.
     * Look ahead and return token that is past the closing ).
     */
    Token *peekPastParen(Token *tk)
    {
        //printf("peekPastParen()\n");
        int parens = 1;
        int curlynest = 0;
        while (1)
        {
            tk = peek(tk);
            //tk.print();
            switch (tk.value)
            {
                case TOK.TOKlparen:
                    parens++;
                    continue;

                case TOK.TOKrparen:
                    --parens;
                    if (parens)
                        continue;
                    tk = peek(tk);
                    break;

                case TOK.TOKlcurly:
                    curlynest++;
                    continue;

                case TOK.TOKrcurly:
                    if (--curlynest >= 0)
                        continue;
                    break;

                case TOK.TOKsemicolon:
                    if (curlynest)
                        continue;
                    break;

                case TOK.TOKeof:
                    break;

                default:
                    continue;
            }
            return tk;
        }
    }

    /*******************************************
     * Parse escape sequence.
     */
    uint escapeSequence()
    {   uint c = *p;

        int n;
        int ndigits;

        switch (c)
        {
            case '\'':
            case '"':
            case '?':
            case '\\':
            Lconsume:
                    p++;
                    break;

            case 'a':       c = 7;          goto Lconsume;
            case 'b':       c = 8;          goto Lconsume;
            case 'f':       c = 12;         goto Lconsume;
            case 'n':       c = 10;         goto Lconsume;
            case 'r':       c = 13;         goto Lconsume;
            case 't':       c = 9;          goto Lconsume;
            case 'v':       c = 11;         goto Lconsume;

            case 'u':
                    ndigits = 4;
                    goto Lhex;
            case 'U':
                    ndigits = 8;
                    goto Lhex;
            case 'x':
                    ndigits = 2;
            Lhex:
                    p++;
                    c = *p;
                    if (ishex(cast(byte)c))
                    {   uint v;

                        n = 0;
                        v = 0;
                        while (1)
                        {
                            if (isdigit(c))
                                c -= '0';
                            else if (islower(c))
                                c -= 'a' - 10;
                            else
                                c -= 'A' - 10;
                            v = v * 16 + c;
                            c = *++p;
                            if (++n == ndigits)
                                break;
                            if (!ishex(cast(byte)c))
                            {   error("escape hex sequence has %d hex digits instead of %d", n, ndigits);
                                break;
                            }
                        }
                        if (ndigits != 2 && !isValidDchar(v))
                        {   error("invalid UTF character \\U%08x", v);
                            v = '?';        // recover with valid UTF character
                        }
                        c = v;
                    }
                    else
                        error("undefined escape hex sequence \\%c\n",c);
                    break;

            case '&':                       // named character entity
                    for (byte *idstart = ++p; 1; p++)
                    {
                        switch (*p)
                        {
                            case ';':
                                c = HtmlNamedEntity(cast(char*)idstart, cast(int)(p - idstart));
                                if (c == ~0)
                                {
                                    error("unnamed character entity &%.*s;", (p - idstart), idstart);
                                    c = ' ';
                                }
                                p++;
                                break;

                            default:
                                if (isalpha(*p) ||
                                    (p != idstart + 1 && isdigit(*p)))
                                    continue;
                                error("unterminated named entity");
                                break;
                        }
                        break;
                    }
                    break;

            case 0:
            case 0x1A:                      // end of file
                    c = '\\';
                    break;

            default:
                    if (isoctal(cast(byte)c))
                    {   uint v;

                        n = 0;
                        v = 0;
                        do
                        {
                            v = v * 8 + (c - '0');
                            c = *++p;
                        } while (++n < 3 && isoctal(cast(byte)c));
                        c = v;
                        if (c > 0xFF)
                            error("0%03o is larger than a byte", c);
                    }
                    else
                        error("undefined escape sequence \\%c\n",c);
                    break;
        }
        return c;
    }

    TOK wysiwygStringConstant(Token *t, int tc)
    {
        Loc start = loc;

        p++;
        stringbuffer.reset();
        while (1)
        {
            uint c = *p++;
            switch (c)
            {
                case '\n':
                    loc.linnum++;
                    break;

                case '\r':
                    if (*p == '\n')
                        continue;   // ignore
                    c = '\n';       // treat EndOfLine as \n character
                    loc.linnum++;
                    break;

                case 0:
                case 0x1A:
                    error("unterminated string constant starting at %s", start.toChars());
                    t.ustring = cast(byte*)"".ptr;
                    t.len = 0;
                    t.postfix = 0;
                    return TOK.TOKstring;

                case '"':
                case '`':
                    if (c == tc)
                    {
                        t.len = cast(int)stringbuffer.offset;
                        stringbuffer.write(cast(byte)0);
                        t.ustring = cast(byte*)GC.malloc(stringbuffer.offset);
                        memcpy(t.ustring, cast(char*)stringbuffer.data.ptr, stringbuffer.offset);
                        stringPostfix(t);
                        return TOK.TOKstring;
                    }
                    break;

                default:
                    if (c & 0x80)
                    {   p--;
                        uint u = decodeUTF();
                        p++;
                        if (u == PS || u == LS)
                            loc.linnum++;
                        char[4] buf;
                        size_t l = encode(buf, u);
                        stringbuffer.write(buf[0 .. l]);
                        continue;
                    }
                    break;
            }
            stringbuffer.write(cast(byte)c);
        }
    }

    /**************************************
     * Lex hex strings:
     *      x"0A ae 34FE BD"
     */
    TOK hexStringConstant(Token *t)
    {
        uint c;
        Loc start = loc;
        uint n = 0;
        uint v;

        p++;
        stringbuffer.reset();
        while (1)
        {
            c = *p++;
            switch (c)
            {
                case ' ':
                case '\t':
                case '\v':
                case '\f':
                    continue;                       // skip white space

                case '\r':
                    if (*p == '\n')
                        continue;                   // ignore
                    // Treat isolated '\r' as if it were a '\n'
                    goto case; // fallthru
                case '\n':
                    loc.linnum++;
                    continue;

                case 0:
                case 0x1A:
                    error("unterminated string constant starting at %s", start.toChars());
                    t.ustring = cast(byte*)"".ptr;
                    t.len = 0;
                    t.postfix = 0;
                    return TOK.TOKstring;

                case '"':
                    if (n & 1)
                    {   error("odd number (%d) of hex characters in hex string", n);
                        stringbuffer.write(cast(byte)v);
                    }
                    t.len = cast(int)stringbuffer.offset;
                    stringbuffer.write(cast(byte)0);
                    t.ustring = cast(byte*)GC.malloc(stringbuffer.offset);
                    memcpy(t.ustring, cast(char*)stringbuffer.data.ptr, stringbuffer.offset);
                    stringPostfix(t);
                    return TOK.TOKstring;

                default:
                    if (c >= '0' && c <= '9')
                        c -= '0';
                    else if (c >= 'a' && c <= 'f')
                        c -= 'a' - 10;
                    else if (c >= 'A' && c <= 'F')
                        c -= 'A' - 10;
                    else if (c & 0x80)
                    {   p--;
                        uint u = decodeUTF();
                        p++;
                        if (u == PS || u == LS)
                            loc.linnum++;
                        else
                            error("non-hex character \\u%04x", u);
                    }
                    else
                        error("non-hex character '%c'", c);
                    if (n & 1)
                    {   v = (v << 4) | c;
                        stringbuffer.write(cast(byte)v);
                    }
                    else
                        v = c;
                    n++;
                    break;
            }
        }
        assert(0);
    }

    /**************************************
     * Lex delimited strings:
     *      q"(foo(xxx))"   // "foo(xxx)"
     *      q"[foo(]"       // "foo("
     *      q"/foo]/"       // "foo]"
     *      q"HERE
     *      foo
     *      HERE"           // "foo\n"
     * Input:
     *      p is on the "
     */
    TOK delimitedStringConstant(Token *t)
    {
        uint c;
        Loc start = loc;
        uint delimleft = 0;
        uint delimright = 0;
        uint nest = 1;
        uint nestcount;
        Identifier *hereid = null;
        uint blankrol = 0;
        uint startline = 0;

        p++;
        stringbuffer.reset();
        while (1)
        {
            c = *p++;
            //printf("c = '%c'\n", c);
            switch (c)
            {
                case '\n':
                Lnextline:
                    loc.linnum++;
                    startline = 1;
                    if (blankrol)
                    {   blankrol = 0;
                        continue;
                    }
                    if (hereid)
                    {
                        char[4] buf;
                        size_t l = encode(buf, c);
                        stringbuffer.write(buf[0 .. l]);
                        continue;
                    }
                    break;

                case '\r':
                    if (*p == '\n')
                        continue;   // ignore
                    c = '\n';       // treat EndOfLine as \n character
                    goto Lnextline;

                case 0:
                case 0x1A:
                    goto Lerror;

                default:
                    if (c & 0x80)
                    {   p--;
                        c = decodeUTF();
                        p++;
                        if (c == PS || c == LS)
                            goto Lnextline;
                    }
                    break;
            }
            if (delimleft == 0)
            {   delimleft = c;
                nest = 1;
                nestcount = 1;
                if (c == '(')
                    delimright = ')';
                else if (c == '{')
                    delimright = '}';
                else if (c == '[')
                    delimright = ']';
                else if (c == '<')
                    delimright = '>';
                else if (isalpha(c) || c == '_' || (c >= 0x80 && isAlpha(c)))
                {   // Start of identifier; must be a heredoc
                    Token t;
                    p--;
                    scan(&t);               // read in heredoc identifier
                    if (t.value != TOK.TOKidentifier)
                    {   error("identifier expected for heredoc, not %s", t.toChars());
                        delimright = c;
                    }
                    else
                    {   hereid = t.ident;
                        //printf("hereid = '%s'\n", hereid.toChars());
                        blankrol = 1;
                    }
                    nest = 0;
                }
                else
                {   delimright = c;
                    nest = 0;
                    if (isspace(c))
                        error("delimiter cannot be whitespace");
                }
            }
            else
            {
                if (blankrol)
                {   error("heredoc rest of line should be blank");
                    blankrol = 0;
                    continue;
                }
                if (nest == 1)
                {
                    if (c == delimleft)
                        nestcount++;
                    else if (c == delimright)
                    {   nestcount--;
                        if (nestcount == 0)
                            goto Ldone;
                    }
                }
                else if (c == delimright)
                    goto Ldone;
                if (startline && isalpha(c) && hereid)
                {   Token t;
                    byte *psave = p;
                    p--;
                    scan(&t);               // read in possible heredoc identifier
                    //printf("endid = '%s'\n", t.ident.toChars());
                    if (t.value == TOK.TOKidentifier && t.ident.equals(hereid))
                    {   /* should check that rest of line is blank
                         */
                        goto Ldone;
                    }
                    p = psave;
                }
                char[4] buf;
                size_t l = encode(buf, c);
                stringbuffer.write(buf[0 .. l]);
                startline = 0;
            }
        }

    Ldone:
        if (*p == '"')
            p++;
        else
            error("delimited string must end in %c\"", delimright);
        t.len = cast(int)stringbuffer.offset;
        stringbuffer.write(cast(byte)0);
        t.ustring = cast(byte*)GC.malloc(stringbuffer.offset);
        memcpy(t.ustring, cast(char*)stringbuffer.data.ptr, stringbuffer.offset);
        stringPostfix(t);
        return TOK.TOKstring;

    Lerror:
        error("unterminated string constant starting at %s", start.toChars());
        t.ustring = cast(byte*)"".ptr;
        t.len = 0;
        t.postfix = 0;
        return TOK.TOKstring;
    }

    /**************************************
     * Lex delimited strings:
     *      q{ foo(xxx) } // " foo(xxx) "
     *      q{foo(}       // "foo("
     *      q{{foo}"}"}   // "{foo}"}""
     * Input:
     *      p is on the q
     */
    TOK tokenStringConstant(Token *t)
    {
        uint nest = 1;
        Loc start = loc;
        byte *pstart = ++p;

        while (1)
        {   Token tok;

            scan(&tok);
            switch (tok.value)
            {
                case TOK.TOKlcurly:
                    nest++;
                    continue;

                case TOK.TOKrcurly:
                    if (--nest == 0)
                        goto Ldone;
                    continue;

                case TOK.TOKeof:
                    goto Lerror;

                default:
                    continue;
            }
        }

    Ldone:
        t.len = cast(int)(p - 1 - pstart);
        t.ustring = cast(byte*)GC.malloc(t.len + 1);
        memcpy(t.ustring, pstart, t.len);
        t.ustring[t.len] = 0;
        stringPostfix(t);
        return TOK.TOKstring;

    Lerror:
        error("unterminated token string constant starting at %s", start.toChars());
        t.ustring = cast(byte*)"".ptr;
        t.len = 0;
        t.postfix = 0;
        return TOK.TOKstring;
    }

    TOK escapeStringConstant(Token *t, int wide)
    {
        Loc start = loc;

        p++;
        stringbuffer.reset();
        while (1)
        {
            uint c = *p++;
            switch (c)
            {
                case '\\':
                    switch (*p)
                    {
                        case 'u':
                        case 'U':
                        case '&':
                        {
                            c = escapeSequence();
                            char[4] buf;
                            size_t l = encode(buf, c);
                            stringbuffer.write(buf[0 .. l]);
                            continue;
                        }

                        default:
                            c = escapeSequence();
                            break;
                    }
                    break;

                case '\n':
                    loc.linnum++;
                    break;

                case '\r':
                    if (*p == '\n')
                        continue;   // ignore
                    c = '\n';       // treat EndOfLine as \n character
                    loc.linnum++;
                    break;

                case '"':
                    t.len = cast(int)stringbuffer.offset;
                    stringbuffer.write(cast(byte)0);
                    t.ustring = cast(byte*)GC.malloc(stringbuffer.offset);
                    memcpy(t.ustring, cast(char*)stringbuffer.data.ptr, stringbuffer.offset);
                    stringPostfix(t);
                    return TOK.TOKstring;

                case 0:
                case 0x1A:
                    p--;
                    error("unterminated string constant starting at %s", start.toChars());
                    t.ustring = cast(byte*)"".ptr;
                    t.len = 0;
                    t.postfix = 0;
                    return TOK.TOKstring;

                default:
                    if (c & 0x80)
                    {
                        p--;
                        c = decodeUTF();
                        if (c == LS || c == PS)
                        {   c = '\n';
                            loc.linnum++;
                        }
                        p++;
                        char[4] buf;
                        size_t l = encode(buf, c);
                        stringbuffer.write(buf[0 .. l]);
                        continue;
                    }
                    break;
            }
            stringbuffer.write(cast(byte)c);
        }
    }

    TOK charConstant(Token *t, int wide)
    {
        TOK tk = TOK.TOKcharv;

        //printf("Lexer::charConstant\n");
        p++;
        uint c = *p++;
        switch (c)
        {
            case '\\':
                switch (*p)
                {
                    case 'u':
                        t.uns64value = escapeSequence();
                        tk = TOK.TOKwcharv;
                        break;

                    case 'U':
                    case '&':
                        t.uns64value = escapeSequence();
                        tk = TOK.TOKdcharv;
                        break;

                    default:
                        t.uns64value = escapeSequence();
                        break;
                }
                break;

            case '\n':
            L1:
                loc.linnum++;
                goto case; // fallthru
            case '\r':
            case 0:
            case 0x1A:
            case '\'':
                error("unterminated character constant");
                return tk;

            default:
                if (c & 0x80)
                {
                    p--;
                    c = decodeUTF();
                    p++;
                    if (c == LS || c == PS)
                        goto L1;
                    if (c < 0xD800 || (c >= 0xE000 && c < 0xFFFE))
                        tk = TOK.TOKwcharv;
                    else
                        tk = TOK.TOKdcharv;
                }
                t.uns64value = c;
                break;
        }

        if (*p != '\'')
        {   error("unterminated character constant");
            return tk;
        }
        p++;
        return tk;
    }

    /***************************************
     * Get postfix of string literal.
     */
    void stringPostfix(Token *t)
    {
        switch (*p)
        {
            case 'c':
            case 'w':
            case 'd':
                t.postfix = *p;
                p++;
                break;

            default:
                t.postfix = 0;
                break;
        }
    }

    /**************************************
     * Read in a number.
     * If it's an integer, store it in tok.TKutok.Vlong.
     *      integers can be decimal, octal or hex
     *      Handle the suffixes U, UL, LU, L, etc.
     * If it's double, store it in tok.TKutok.Vdouble.
     * Returns:
     *      TKnum
     *      TKdouble,...
     */
    TOK number(Token *t)
    {
        // We use a state machine to collect numbers
        enum STATE { STATE_initial, STATE_0, STATE_decimal, STATE_octal, STATE_octale,
            STATE_hex, STATE_binary, STATE_hex0, STATE_binary0,
            STATE_hexh, STATE_error }
        STATE state;

        enum FLAGS
        {
            FLAGS_none     = 0,
            FLAGS_decimal  = 1,             // decimal
            FLAGS_unsigned = 2,             // u or U suffix
            FLAGS_long     = 4,             // l or L suffix
        }
        FLAGS flags = FLAGS.FLAGS_decimal;

        uint c;
        byte *start;
        TOK result;

        //printf("Lexer::number()\n");
        state = STATE.STATE_initial;
        stringbuffer.reset();
        start = p;
        while (1)
        {
            c = *p;
            switch (state)
            {
                case STATE.STATE_initial:         // opening state
                    if (c == '0')
                        state = STATE.STATE_0;
                    else
                        state = STATE.STATE_decimal;
                    break;

                case STATE.STATE_0:
                    flags = cast(FLAGS) (flags & ~FLAGS.FLAGS_decimal);
                    switch (c)
                    {
                        case 'X':
                        case 'x':
                            state = STATE.STATE_hex0;
                            break;

                        case '.':
                            if (p[1] == '.')        // .. is a separate token
                                goto done;
                            if (isalpha(p[1]) || p[1] == '_')
                                goto done;
                            goto case; // fallthru
                        case 'i':
                        case 'f':
                        case 'F':
                            goto _real;
                        case 'B':
                        case 'b':
                            state = STATE.STATE_binary0;
                            break;

                        case '0': case '1': case '2': case '3':
                        case '4': case '5': case '6': case '7':
                            state = STATE.STATE_octal;
                            break;

                        case '_':
                            state = STATE.STATE_octal;
                            p++;
                            continue;

                        case 'L':
                            if (p[1] == 'i')
                                goto _real;
                            goto done;

                        default:
                            goto done;
                    }
                    break;

                case STATE.STATE_decimal:         // reading decimal number
                    if (!isdigit(c))
                    {
                        if (c == '_')               // ignore embedded _
                        {   p++;
                            continue;
                        }
                        if (c == '.' && p[1] != '.')
                        {
                            if (isalpha(p[1]) || p[1] == '_')
                                goto done;
                            goto _real;
                        }
                        else if (c == 'i' || c == 'f' || c == 'F' ||
                                 c == 'e' || c == 'E')
                        {
                _real:       // It's a real number. Back up and rescan as a real
                            p = start;
                            return inreal(t);
                        }
                        else if (c == 'L' && p[1] == 'i')
                            goto _real;
                        goto done;
                    }
                    break;

                case STATE.STATE_hex0:            // reading hex number
                case STATE.STATE_hex:
                    if (!ishex(cast(byte)c))
                    {
                        if (c == '_')               // ignore embedded _
                        {   p++;
                            continue;
                        }
                        if (c == '.' && p[1] != '.')
                            goto _real;
                        if (c == 'P' || c == 'p' || c == 'i')
                            goto _real;
                        if (state == STATE.STATE_hex0)
                            error("Hex digit expected, not '%c'", c);
                        goto done;
                    }
                    state = STATE.STATE_hex;
                    break;

                case STATE.STATE_octal:           // reading octal number
                case STATE.STATE_octale:          // reading octal number with non-octal digits
                    if (!isoctal(cast(byte)c))
                    {
                        if (c == '_')               // ignore embedded _
                        {   p++;
                            continue;
                        }
                        if (c == '.' && p[1] != '.')
                            goto _real;
                        if (c == 'i')
                            goto _real;
                        if (isdigit(c))
                        {
                            state = STATE.STATE_octale;
                        }
                        else
                            goto done;
                    }
                    break;

                case STATE.STATE_binary0:         // starting binary number
                case STATE.STATE_binary:          // reading binary number
                    if (c != '0' && c != '1')
                    {
                        if (c == '_')               // ignore embedded _
                        {   p++;
                            continue;
                        }
                        if (state == STATE.STATE_binary0)
                        {   error("binary digit expected");
                            state = STATE.STATE_error;
                            break;
                        }
                        else
                            goto done;
                    }
                    state = STATE.STATE_binary;
                    break;

                case STATE.STATE_error:           // for error recovery
                    if (!isdigit(c))        // scan until non-digit
                        goto done;
                    break;

                default:
                    assert(0);
            }
            stringbuffer.write(cast(byte)c);
            p++;
        }
    done:
        stringbuffer.write(cast(byte)0);          // terminate string
        if (state == STATE.STATE_octale)
            error("Octal digit expected");

        ulong n;                       // unsigned >=64 bit integer type

        if (stringbuffer.offset == 2 && (state == STATE.STATE_decimal || state == STATE.STATE_0))
            n = stringbuffer.data[0] - '0';
        else
        {
            // Convert string to integer
            errno = 0;
            n = strtoull(cast(char*)stringbuffer.data.ptr, null, 0);
            if (errno == ERANGE)
                error("integer overflow");
            if (n.sizeof > 8 &&
                n > 0xFFFFFFFFFFFFFFFFUL)  // if n needs more than 64 bits
                error("integer overflow");
        }

        // Parse trailing 'u', 'U', 'l' or 'L' in any combination
        const byte *psuffix = p;
        while (1)
        {   byte f;

            switch (*p)
            {   case 'U':
                case 'u':
                    f = FLAGS.FLAGS_unsigned;
                    goto L1;

                case 'l':
                    error("'l' suffix is deprecated, use 'L' instead");
                    goto case; // fallthru
                case 'L':
                    f = FLAGS.FLAGS_long;
                L1:
                    p++;
                    if (flags & f)
                        error("unrecognized token");
                    flags = cast(FLAGS) (flags | f);
                    continue;
                default:
                    break;
            }
            break;
        }

        if (state == STATE.STATE_octal && n >= 8 && !GLOBAL_USE_DEPRECATED)
            error("octal literals 0%llo%.*s are deprecated, use std.conv.octal!%llo%.*s instead",
                    n, p - psuffix, psuffix, n, p - psuffix, psuffix);

        switch (flags)
        {
            case FLAGS.FLAGS_none:
                /* Octal or Hexadecimal constant.
                 * First that fits: int, uint, long, ulong
                 */
                if (n & 0x8000000000000000L)
                        result = TOK.TOKuns64v;
                else if (n & 0xFFFFFFFF00000000L)
                        result = TOK.TOKint64v;
                else if (n & 0x80000000)
                        result = TOK.TOKuns32v;
                else
                        result = TOK.TOKint32v;
                break;

            case FLAGS.FLAGS_decimal:
                /* First that fits: int, long, long long
                 */
                if (n & 0x8000000000000000L)
                {       error("signed integer overflow");
                        result = TOK.TOKuns64v;
                }
                else if (n & 0xFFFFFFFF80000000L)
                        result = TOK.TOKint64v;
                else
                        result = TOK.TOKint32v;
                break;

            case FLAGS.FLAGS_unsigned:
            case FLAGS.FLAGS_decimal | FLAGS.FLAGS_unsigned:
                /* First that fits: uint, ulong
                 */
                if (n & 0xFFFFFFFF00000000L)
                        result = TOK.TOKuns64v;
                else
                        result = TOK.TOKuns32v;
                break;

            case FLAGS.FLAGS_decimal | FLAGS.FLAGS_long:
                if (n & 0x8000000000000000L)
                {       error("signed integer overflow");
                        result = TOK.TOKuns64v;
                }
                else
                        result = TOK.TOKint64v;
                break;

            case FLAGS.FLAGS_long:
                if (n & 0x8000000000000000L)
                        result = TOK.TOKuns64v;
                else
                        result = TOK.TOKint64v;
                break;

            case FLAGS.FLAGS_unsigned | FLAGS.FLAGS_long:
            case FLAGS.FLAGS_decimal | FLAGS.FLAGS_unsigned | FLAGS.FLAGS_long:
                result = TOK.TOKuns64v;
                break;

            default:
                version(DEBUG) printf("%x\n",flags);
                assert(0);
        }
        t.uns64value = n;
        return result;
    }

    /**************************************
     * Read in characters, converting them to real.
     * Bugs:
     *      Exponent overflow not detected.
     *      Too much requested precision is not detected.
     */
    TOK inreal(Token *t)
    in
    {
        assert(*p == '.' || isdigit(*p));
    }
    out (result)
    {
        switch (result)
        {
            case TOK.TOKfloat32v:
            case TOK.TOKfloat64v:
            case TOK.TOKfloat80v:
            case TOK.TOKimaginary32v:
            case TOK.TOKimaginary64v:
            case TOK.TOKimaginary80v:
                break;

            default:
                assert(0);
        }
    }
    body
    {
        int dblstate;
        uint c;
        char hex;                   // is this a hexadecimal-floating-constant?
        TOK result;

        //printf("Lexer::inreal()\n");
        stringbuffer.reset();
        dblstate = 0;
        hex = 0;
    Lnext:
        while (1)
        {
            // Get next char from input
            c = *p++;
            //printf("dblstate = %d, c = '%c'\n", dblstate, c);
            while (1)
            {
                switch (dblstate)
                {
                    case 0:                 // opening state
                        if (c == '0')
                            dblstate = 9;
                        else if (c == '.')
                            dblstate = 3;
                        else
                            dblstate = 1;
                        break;

                    case 9:
                        dblstate = 1;
                        if (c == 'X' || c == 'x')
                        {   hex++;
                            break;
                        }
                        goto case; // fallthru
                    case 1:                 // digits to left of .
                    case 3:                 // digits to right of .
                    case 7:                 // continuing exponent digits
                        if (!isdigit(c) && !(hex && isxdigit(c)))
                        {
                            if (c == '_')
                                goto Lnext; // ignore embedded '_'
                            dblstate++;
                            continue;
                        }
                        break;

                    case 2:                 // no more digits to left of .
                        if (c == '.')
                        {   dblstate++;
                            break;
                        }
                        goto case; // fallthru
                    case 4:                 // no more digits to right of .
                        if ((c == 'E' || c == 'e') ||
                            hex && (c == 'P' || c == 'p'))
                        {   dblstate = 5;
                            hex = 0;        // exponent is always decimal
                            break;
                        }
                        if (hex)
                            error("binary-exponent-part required");
                        goto done;

                    case 5:                 // looking immediately to right of E
                        dblstate++;
                        if (c == '-' || c == '+')
                            break;
                        goto case; // fallthru
                    case 6:                 // 1st exponent digit expected
                        if (!isdigit(c))
                            error("exponent expected");
                        dblstate++;
                        break;

                    case 8:                 // past end of exponent digits
                        goto done;
                }
                break;
            }
            stringbuffer.write(cast(byte)c);
        }
    done:
        p--;

        stringbuffer.write(cast(byte)0);

        t.float80value = strtold(cast(char*)stringbuffer.data.ptr, null);
        errno = 0;
        switch (*p)
        {
            case 'F':
            case 'f':
                {   // Only interested in errno return
                    double d = strtof(cast(char*)stringbuffer.data.ptr, null);
                    // Assign to d to keep gcc warnings at bay,
                    // but then CppCheck complains that d is never used.
                }
                result = TOK.TOKfloat32v;
                p++;
                break;

            default:
                /* Should do our own strtod(), since dmc and linux gcc
                 * accept 2.22507e-308, while apple gcc will only take
                 * 2.22508e-308. Not sure who is right.
                 */
                {   // Only interested in errno return
                    double d = strtod(cast(char*)stringbuffer.data.ptr, null);
                    // Assign to d to keep gcc warnings at bay
                    // but then CppCheck complains that d is never used.
                }
                result = TOK.TOKfloat64v;
                break;

            case 'l':
                if (!GLOBAL_USE_DEPRECATED)
                    error("'l' suffix is deprecated, use 'L' instead");
                goto case; // fallthru
            case 'L':
                result = TOK.TOKfloat80v;
                p++;
                break;
        }
        if (*p == 'i' || *p == 'I')
        {
            if (!GLOBAL_USE_DEPRECATED && *p == 'I')
                error("'I' suffix is deprecated, use 'i' instead");
            p++;
            switch (result)
            {
                case TOK.TOKfloat32v:
                    result = TOK.TOKimaginary32v;
                    break;
                case TOK.TOKfloat64v:
                    result = TOK.TOKimaginary64v;
                    break;
                case TOK.TOKfloat80v:
                    result = TOK.TOKimaginary80v;
                    break;
            }
        }
        if (errno == ERANGE)
            error("number is not representable");
        return result;
    }

    void error(string format, ...)
    {
        throw new Exception(format);
version(none) {
        va_list ap;
        va_start(ap, format);
        verror(tokenLoc(), format, ap);
        va_end(ap);
}
    }

    void error(Loc loc, string format, ...)
    {
        throw new Exception(format);
version(none) {
        va_list ap;
        va_start(ap, format);
        verror(loc, format, ap);
        va_end(ap);
}
    }

    /*********************************************
     * parse:
     *      #line linnum [filespec]
     */
    void poundLine()
    {
        Token tok;
        int linnum;
        char *filespec = null;
        Loc loc = this.loc;

        scan(&tok);
        if (tok.value == TOK.TOKint32v || tok.value == TOK.TOKint64v)
        {   linnum = cast(int)(tok.uns64value - 1);
            if (linnum != tok.uns64value - 1)
                error("line number out of range");
        }
        else
            goto Lerr;

        while (1)
        {
            switch (*p)
            {
                case 0:
                case 0x1A:
                case '\n':
                Lnewline:
                    this.loc.linnum = linnum;
                    if (filespec)
                        this.loc.filename = cast(string)filespec[0 .. strlen(filespec)];
                    return;

                case '\r':
                    p++;
                    if (*p != '\n')
                    {   p--;
                        goto Lnewline;
                    }
                    continue;

                case ' ':
                case '\t':
                case '\v':
                case '\f':
                    p++;
                    continue;                       // skip white space

                case '_':
                    if (mod && memcmp(p, "__FILE__".ptr, 8) == 0)
                    {
                        p += 8;
                        filespec = strdup((loc.filename ? loc.filename : mod).ptr);
                        continue;
                    }
                    goto Lerr;

                case '"':
                    if (filespec)
                        goto Lerr;
                    stringbuffer.reset();
                    p++;
                    while (1)
                    {   uint c;

                        c = *p;
                        switch (c)
                        {
                            case '\n':
                            case '\r':
                            case 0:
                            case 0x1A:
                                goto Lerr;

                            case '"':
                                stringbuffer.write(cast(byte)0);
                                filespec = strdup(cast(char*)stringbuffer.data.ptr);
                                p++;
                                break;

                            default:
                                if (c & 0x80)
                                {   uint u = decodeUTF();
                                    if (u == PS || u == LS)
                                        goto Lerr;
                                }
                                stringbuffer.write(cast(byte)c);
                                p++;
                                continue;
                        }
                        break;
                    }
                    continue;

                default:
                    if (*p & 0x80)
                    {   uint u = decodeUTF();
                        if (u == PS || u == LS)
                            goto Lnewline;
                    }
                    goto Lerr;
            }
        }

    Lerr:
        error(loc, "#line integer [\"filespec\"]\\n expected");
    }

    /********************************************
     * Decode UTF character.
     * Issue error messages for invalid sequences.
     * Return decoded character, advance p to last character in UTF sequence.
     */
    uint decodeUTF()
    {
        dchar u;
        byte *s = p;
        size_t len;

        byte c = *s;
        assert(c & 0x80);

        // Check length of remaining string up to 6 UTF-8 characters
        for (len = 1; len < 6 && s[len]; len++) {}

        size_t idx = 0;
        try
            dchar u = decode(cast(char[])s[0 .. len], idx); //utf_decodeChar(s, len, &idx, &u);
        catch(UTFException e)
            error("%s", e.toString());
        finally
            p += idx - 1;

        return u;
    }

    /***************************************************
     * Parse doc comment embedded between t.ptr and p.
     * Remove trailing blanks and tabs from lines.
     * Replace all newlines with \n.
     * Remove leading comment character from each line.
     * Decide if it's a lineComment or a blockComment.
     * Append to previous one for this token.
     */
    void getDocComment(Token *t, uint lineComment)
    {
        /* ct tells us which kind of comment it is: '/', '*', or '+'
         */
        byte ct = t.ptr[2];

        /* Start of comment text skips over / * *, / + +, or / / /
         */
        byte *q = t.ptr + 3;      // start of comment text

        byte *qend = p;
        if (ct == '*' || ct == '+')
            qend -= 2;

        /* Scan over initial row of ****'s or ++++'s or ////'s
         */
        for (; q < qend; q++)
        {
            if (*q != ct)
                break;
        }

        /* Remove trailing row of ****'s or ++++'s
         */
        if (ct != '/')
        {
            for (; q < qend; qend--)
            {
                if (qend[-1] != ct)
                    break;
            }
        }

        /* Comment is now [q .. qend].
         * Canonicalize it into buf[].
         */
        OutBuffer buf = new OutBuffer();
        scope(exit) delete buf;

        int linestart = 0;

        for (; q < qend; q++)
        {
            byte c = *q;

            switch (c)
            {
                case '*':
                case '+':
                    if (linestart && c == ct)
                    {   linestart = 0;
                        /* Trim preceding whitespace up to preceding \n
                         */
                        while (buf.offset && (buf.data[buf.offset - 1] == ' ' || buf.data[buf.offset - 1] == '\t'))
                            buf.offset--;
                        continue;
                    }
                    break;

                case ' ':
                case '\t':
                    break;

                case '\r':
                    if (q[1] == '\n')
                        continue;           // skip the \r
                    goto Lnewline;

                default:
                    if (c == 226)
                    {
                        // If LS or PS
                        if (q[1] == 128 &&
                            (q[2] == 168 || q[2] == 169))
                        {
                            q += 2;
                            goto Lnewline;
                        }
                    }
                    linestart = 0;
                    break;

                Lnewline:
                    c = '\n';               // replace all newlines with \n
                    goto case; // fallthru
                case '\n':
                    linestart = 1;

                    /* Trim trailing whitespace
                     */
                    while (buf.offset && (buf.data[buf.offset - 1] == ' ' || buf.data[buf.offset - 1] == '\t'))
                        buf.offset--;

                    break;
            }
            buf.write(cast(byte)c);
        }

        // Always end with a newline
        if (!buf.offset || buf.data[buf.offset - 1] != '\n')
            buf.write('\n');

        buf.write(cast(byte)0);

        // It's a line comment if the start of the doc comment comes
        // after other non-whitespace on the same line.
        byte** dc = (lineComment && anyToken)
                             ? &t.lineComment
                             : &t.blockComment;

        // Combine with previous doc comment, if any
        if (*dc)
            *dc = combineComments(*dc, cast(byte*)buf.data.ptr);
        else
        {
            *dc = cast(byte*)buf.toBytes().ptr;
            buf.reset();
        }
    }

    /**********************************
     * Determine if string is a valid Identifier.
     * Placed here because of commonality with Lexer functionality.
     * Returns:
     *      0       invalid
     */
    static int isValidIdentifier(char *p)
    {
        if (!p || !*p)
            goto Linvalid;

        if (*p >= '0' && *p <= '9')         // beware of isdigit() on signed chars
            goto Linvalid;

        try
        {
            size_t len = strlen(p);
            size_t idx = 0;

            while (p[idx])
            {
                dchar dc = decode(cast(char[])p[0 .. len], idx);
                if (!((dc >= 0x80 && isAlpha(dc)) || isalnum(dc) || dc == '_'))
                    goto Linvalid;
            }
        }
        catch(UTFException e)
            goto Linvalid;

        return 1;

    Linvalid:
        return 0;
    }

    /********************************************
     * Combine two document comments into one,
     * separated by a newline.
     */
    static byte *combineComments(byte *c1, byte *c2)
    {
        //printf("Lexer::combineComments('%s', '%s')\n", c1, c2);

        byte *c = c2;

        if (c1)
        {
            c = c1;
            if (c2)
            {
                size_t len1 = strlen(cast(char*)c1);
                size_t len2 = strlen(cast(char*)c2);

                c = cast(byte*)GC.malloc(len1 + 1 + len2 + 1);
                memcpy(c, c1, len1);
                if (len1 && c1[len1 - 1] != '\n')
                {
                    c[len1] = '\n';
                    len1++;
                }
                memcpy(c + len1, c2, len2);
                c[len1 + len2] = 0;
            }
        }
        return c;
    }


    /*******************************************
     * Search actual location of current token
     * even when infinite look-ahead was done.
     */
    Loc tokenLoc()
    {
        Loc result = this.loc;
        Token* last = &token;
        while (last.next)
            last = last.next;

        byte* start = token.ptr;
        byte* stop = last.ptr;

        for (byte* p = start; p < stop; ++p)
        {
            switch (*p)
            {
                case '\n':
                    result.linnum--;
                    break;
                case '\r':
                    if (p[1] != '\n')
                        result.linnum--;
                    break;
                default:
                    break;
            }
        }
        return result;
    }
}


unittest
{
    //import core.stdc.stdio : printf;

    //printf("unittest_lexer()\n");

    /* Not much here, just trying things out.
     */
    string text = "int";
    Lexer lex1 = Lexer(null, cast(byte*)text.ptr, 0, cast(uint)text.length, 0, 0);
    TOK tok;

    tok = lex1.nextToken();
    //printf("tok == %s, %d, %d\n", Token.toChars(tok), tok, TOK.TOKint32);
    assert(tok == TOK.TOKint32);

    tok = lex1.nextToken();
    //printf("tok == %s, %d, %d\n", Token.toChars(tok), tok, TOK.TOKeof);
    assert(tok == TOK.TOKeof);

    tok = lex1.nextToken();
    //printf("tok == %s, %d, %d\n", Token.toChars(tok), tok, TOK.TOKeof);
    assert(tok == TOK.TOKeof);
}

/********************************************
 * Do our own char maps
 */

static byte cmtable[256];

enum CMoctal  = 0x1;
enum CMhex    = 0x2;
enum CMidchar = 0x4;

byte isoctal (byte c) { return cmtable[c] & CMoctal; }
byte ishex   (byte c) { return cmtable[c] & CMhex; }
byte isidchar(byte c) { return cmtable[c] & CMidchar; }

void init_charmap()
{
    foreach (c; 0 .. 256)
    {
        if ('0' <= c && c <= '7')
            cmtable[c] |= CMoctal;
        if (isdigit(c) || ('a' <= c && c <= 'f') || ('A' <= c && c <= 'F'))
            cmtable[c] |= CMhex;
        if (isalnum(c) || c == '_')
            cmtable[c] |= CMidchar;
    }
}
