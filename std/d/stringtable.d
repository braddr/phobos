module std.d.stringtable;

import core.memory;

import core.stdc.string: memcmp, memcpy;

// StringValue is a variable-length structure as indicated by the last array
// member with unspecified size.  It has neither proper c'tors nor a factory
// method because the only thing which should be creating these is StringTable.
struct StringValue
{
    union
    {
        void *ptrvalue;
        char *str;
    };
private:
    uint length;

    char lstring[0];

public:
    uint len() const { return length; }
    const char *toDchars() const { return cast(char*)&lstring; }

private:
    @disable this();  // not constructible

    // This is more like a placement new c'tor
    void alloc(const char *p, uint l)
    {
        length = l;
        char* ptr = cast(char*)&lstring;
        ptr[l] = 0;
        memcpy(ptr, p, length * char.sizeof);
    }
}

struct StringTable
{
private:
    StringEntry **table;
    uint count;
    uint tabledim;

public:
    void init(uint size = 37)
    {
        table = cast(StringEntry **)GC.calloc(size * (StringEntry *).sizeof);
        tabledim = size;
        count = 0;
    }

    // can't be the dtor since memory might have already been released
    void reset()
    {
        // Zero out dangling pointers to help garbage collector.
        // Should zero out StringEntry's too.
        for (uint i = 0; i < count; i++)
            table[i] = null;

        table = null;
        tabledim = 0;
    }

    StringValue *lookup(const char *s, uint len)
    {
        StringEntry *se = *search(s, len);
        if (se)
            return &se.value;
        else
            return null;
    }

    StringValue *insert(const char *s, uint len)
    {
        StringEntry **pse = search(s, len);
        StringEntry *se   = *pse;
        if (se)
            return null;            // error: already in table
        else
        {
            se = StringEntry.alloc(s, len);
            *pse = se;
        }
        return &se.value;
    }

    StringValue *update(const char *s, uint len)
    {
        StringEntry **pse = search(s, len);
        StringEntry *se   = *pse;
        if (!se)                    // not in table: so create new entry
        {
            se = StringEntry.alloc(s, len);
            *pse = se;
        }
        return &se.value;
    }

private:
    StringEntry **search(const char *s, uint len)
    {
        //printf("StringTable.search(%p,%d)\n",s,len);

        hash_t hash = calcHash(s,len);
        uint u = hash % tabledim;
        StringEntry **se = &table[u];
        //printf("\thash = %d, u = %d\n",hash,u);
        while (*se)
        {
            sizediff_t cmp = cast(sizediff_t)(*se).hash - cast(sizediff_t)hash;
            if (cmp == 0)
            {
                cmp = (*se).value.len() - len;
                if (cmp == 0)
                {
                    cmp = memcmp(s,(*se).value.toDchars(),len);
                    if (cmp == 0)
                        break;
                }
            }
            if (cmp < 0)
                se = &(*se).left;
            else
                se = &(*se).right;
        }
        //printf("\treturn %p, %p\n",se, (*se));
        return se;
    }
}

hash_t calcHash(const(char)* str, size_t len)
{
    hash_t hash = 0;

    while (1)
    {
        switch (len)
        {
            case 0:
                return hash;

            case 1:
                hash *= 37;
                hash += *cast(const byte *)str;
                return hash;

            case 2:
                hash *= 37;
version(LittleEndian)
                hash += *cast(const ushort *)str;
else
                hash += str[0] * 256 + str[1];

                return hash;

            case 3:
                hash *= 37;
version(LittleEndian)
                hash += (*cast(const ushort *)str << 8) + (cast(const byte *)str)[2];
else
                hash += (str[0] * 256 + str[1]) * 256 + str[2];

                return hash;

            default:
                hash *= 37;
version(LittleEndian)
                hash += *cast(const int *)str;
else
                hash += ((str[0] * 256 + str[1]) * 256 + str[2]) * 256 + str[3];

                str += 4;
                len -= 4;
                break;
        }
    }
}

struct StringEntry
{
    StringEntry *left;
    StringEntry *right;
    hash_t hash;

    StringValue value;

    static StringEntry *alloc(const char *s, uint len)
    {
        StringEntry *se = cast(StringEntry *)GC.calloc(StringEntry.sizeof + len + 1);
        se.value.alloc(s, len);
        se.hash = calcHash(s, len);
        return se;
    }
}

