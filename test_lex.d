module test_lex;

import std.algorithm;
import std.file;
import std.range;
import std.stdio;

import std.d.lexer;
import std.d.stringtable;
import std.d.token;

void lex(StringTable table, string filename)
{
    byte[] contents = cast(byte[])read(filename);
    contents ~= 0;
    //writeln("filename; ", filename, ", length; ", contents.length);
    auto l = Lexer(table, filename, cast(byte*)contents.ptr, 0, cast(uint)contents.length, 0, 0);

    do
        l.nextToken();
    while (l.token.value != TOK.TOKeof);
}

void main()
{
    StringTable table = createAndPopulatedStringTable();

    auto dFiles = filter!`endsWith(a.name,".d")`(dirEntries("std", SpanMode.depth));
    foreach(d; dFiles)
    {
        lex(table, d.name);
    }

    //foreach (i; 1 .. 10)
    //    lex("std/xml.d");
}
