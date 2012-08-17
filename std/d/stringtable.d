module std.d.stringtable;

import core.memory;

import core.stdc.string: memcmp, memcpy;

// StringValue is a variable-length structure as indicated by the last array
// member with unspecified size.  It has neither proper c'tors nor a factory
// method because the only thing which should be creating these is StringTable.
struct StringValue
{
    void *ptrvalue;

private:
    size_t length_;

    immutable(char) lstring[0];

public:
    size_t len() const { return length_; }
    string toString() const { return (cast(immutable(char)*)&lstring)[0 .. length_]; }

private:
    @disable this();  // not constructible

    // This is more like a placement new c'tor
    void alloc(const(char[]) s)
    {
        length_ = s.length;
        char* ptr = cast(char*)&lstring;
        ptr[s.length] = 0;
        memcpy(ptr, s.ptr, s.length);
    }
}

// NOTE: holds a StringValue as a member, and since StringValue is a variable
// length struct, we must add more space.
struct StringEntry
{
    StringEntry *left;
    StringEntry *right;
    hash_t hash;

    StringValue value;

private:
    static StringEntry *alloc(const(char[]) s)
    {
        //printf("StringEntry.alloc\n");
        StringEntry *se = cast(StringEntry *)GC.calloc(StringEntry.sizeof + s.length + 1);
        se.value.alloc(s);
        se.hash = calcHash(s);
        return se;
    }
}

struct StringTable
{
private:
    StringEntry **table;
    size_t tabledim; // total size of the table, for bucket mod

public:
    void init(size_t size = 37)
    {
        table = cast(StringEntry **)GC.calloc(size * (StringEntry *).sizeof);
        tabledim = size;
    }

    // can't be the dtor since memory might have already been released
    void reset()
    {
        // Zero out dangling pointers to help garbage collector.
        // Should zero out StringEntry's too.
        foreach (size_t i; 0 .. tabledim)
            table[i] = null;

        table = null;
        tabledim = 0;
    }

    StringValue *lookup(const(char[]) s)
    {
        StringEntry *se = *search(s);
        if (se)
            return &se.value;
        else
            return null;
    }

    StringValue *insert(const(char[]) s)
    {
        StringEntry **pse = search(s);
        StringEntry *se   = *pse;
        if (se)
            return null;            // error: already in table
        else
        {
            se = StringEntry.alloc(s);
            *pse = se;
        }
        return &se.value;
    }

    StringValue *update(const(char[]) s)
    {
        StringEntry **pse = search(s);
        StringEntry *se   = *pse;
        if (!se)                    // not in table: so create new entry
        {
            se = StringEntry.alloc(s);
            *pse = se;
        }
        return &se.value;
    }

private:
    StringEntry **search(const(char[]) s)
    {
        //printf("StringTable.search(%p - %.*s, %d)\n", s.ptr, s.length, s.ptr, s.length);

        hash_t hash = calcHash(s);
        size_t u = hash % tabledim;
        StringEntry **se = &table[u];
        //printf("\thash = %zd, u = %zd\n", hash, u);
        while (*se)
        {
            sizediff_t cmp = cast(sizediff_t)(*se).hash - cast(sizediff_t)hash;
            if (cmp == 0)
            {
                cmp = (*se).value.len() - s.length;
                if (cmp == 0)
                {
                    cmp = memcmp(s.ptr, (*se).value.toString().ptr, s.length);
                    if (cmp == 0)
                        break;
                }
            }
            if (cmp < 0)
                se = &(*se).left;
            else
                se = &(*se).right;
        }
        //printf("\treturn %p, %p\n", se, (*se));
        return se;
    }
}

hash_t calcHash(const(char[]) str)
{
    return calcHash(str.ptr, str.length);
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

