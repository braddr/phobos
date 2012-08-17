module test_lex;

import std.algorithm;
import std.file;
import std.range;
import std.stdio;

import std.d.lexer;
import std.d.token;

void lex(string filename)
{
    byte[] contents = cast(byte[])read(filename);
    contents ~= 0;
    writeln("filename; ", filename, ", length; ", contents.length);
    auto l = Lexer(filename, cast(byte*)contents.ptr, 0, cast(uint)contents.length, 0, 0);

    do
        l.nextToken();
    while (l.token.value != TOK.TOKeof);
}

void main()
{
    auto dFiles = filter!`endsWith(a.name,".d")`(dirEntries("std", SpanMode.depth));
    foreach(d; dFiles)
    {
        lex(d.name);
    }

    //foreach (i; 1 .. 10)
    //    lex("std/xml.d");
}
