module rawfile;

import std.traits : isDynamicArray;
import std.stdio : writeln;


/** */
struct RawFile
{
    string path;


    /** */
    void save( T )( ref T data )
    {
        // read T fields
        //   each field to ubyte
        //     string to [ size_t, ubyte[ FIXED ] ]
        //     ulong  to ubyte[8]
        //     uint   to ubyte[4]
        //     ushort to ubyte[2]
        //     ubyte  to ubyte[1]
        //     struct to ubyte[] recursive

        import std.file : write;

        ubyte[] rawBytes;
        rawBytes = .save( data, rawBytes );

        write( path, rawBytes );
    }


    /** */
    void load( T )( ref T wanted )
    {
        import std.file : read;

        auto rawBytes = cast( ubyte[] ) read( path );

        .load( wanted, rawBytes );
    }
}


// dynamic array, string, int[], struct[]
/** */
ubyte[] save( T )( ref T data, ref ubyte[] bytes )
    if ( isDynamicArray!T )
{
    typeof( data.length ) length = data.length; // in bytes for string, in T for T[]

    // length of string
    bytes = .save( length, bytes );

    // has data
    if ( length > 0 )
    {    
        alias TElement = typeof( data[0] );

        bytes.reserve( bytes.length + length * TElement.sizeof );

        // string, scalar[]
        static
        if ( is( T == string ) || __traits( isScalar, TElement ) )
        {    
            // bytes of string
            bytes ~= ( cast( ubyte* ) data.ptr )[ 0 .. length * TElement.sizeof ];
        }

        else // struct[]
        static
        if ( is( TElement == struct ) )
        {
            // save each element
            foreach ( ref element; data )
            {
                bytes = .save( element, bytes );
            }
        }

        else 
        {
            assert( 0, "unsupported" );
        }
    }

    return bytes;
}


// dynamic array, string, int[], struct[]
/** */
void load( T )( ref T data, ref ubyte[] bytes )
    if ( isDynamicArray!T )
{
    import std.range : popFrontN;

    import std.array : replaceInPlace;

    alias TElement = typeof( data[0] );

    // length of string
    typeof( data.length ) length;
    .load( length, bytes );

    // length in bytes
    auto lengthInBytes = length * TElement.sizeof;

    // string data
    if ( length > 0 )
    {
        // string || scalar[]
        static
        if ( is( T == string ) || __traits( isScalar, TElement ) )
        {
            // bytes of string || bytes of scalar type
            data = ( cast( T ) bytes )[ 0 .. length ];
            bytes.popFrontN( lengthInBytes );
        }

        else // struct[]
        static
        if ( is( TElement == struct ) )
        {
            data.length = length;

            foreach ( ref element; data )
            {
                .load( element, bytes );
            }
        }

        else 
        {
            assert( 0, "unsupported" );
        }    
    }
}


// ubyte, byte, ushort, short, uint, int, ulong, long, char, bool, float, void*, enum, int4
/** */
ubyte[] save( T )( ref T data, ref ubyte[] bytes )
    if ( __traits( isScalar, T ) )
{
    bytes.reserve( bytes.length + T.sizeof );

    // byte
    bytes ~= ( cast( ubyte* ) &data )[ 0 .. T.sizeof ];

    return bytes;
}


// ubyte, byte, ushort, short, uint, int, ulong, long, char, bool, float, void*, enum, int4
/** */
void load( T )( ref T data, ref ubyte[] bytes )
    if ( __traits( isScalar, T ) )
{
    import std.range  : popFrontN;

    // byte
    data = * ( cast( T* ) ( bytes[ 0 .. T.sizeof ].ptr ) );
    bytes.popFrontN( T.sizeof );
}


// struct
/** */
ubyte[] save( T )( ref T data, ref ubyte[] bytes )
    if ( is( T == struct ) )
{
    import std.traits : FieldNameTuple;

    bytes.reserve( bytes.length + T.sizeof );

    // feilds
    static
    foreach ( field; FieldNameTuple!T )
    {
        bytes = .save( __traits( getMember, data, field ), bytes );
    }

    return bytes;
}


/** */
void load( T )( ref T data, ref ubyte[] bytes )
    if ( is( T == struct ) )
{
    import std.traits : FieldNameTuple;

    // feilds
    static
    foreach ( field; FieldNameTuple!T )
    {
        .load( __traits( getMember, data,  field ), bytes );
    }
}


///
unittest
{
    // string
    string s = "AB";
    
    ubyte[] raw;
    raw = s.save( raw );
    assert( raw == [ 2, 0, 0, 0, 0, 0, 0, 0, 'A', 'B' ] );
    s.load( raw );
    assert( s == "AB" );

    // ubyte
    ubyte theByte = 7;

    raw = theByte.save( raw );
    assert( raw == [ 7 ] );
    theByte.load( raw );
    assert( theByte == 7 );

    // struct
    struct Struct
    {
        ubyte byteField;
    }

    Struct theStruct = Struct( 7 );

    raw = theStruct.save( raw );
    assert( raw == [ 7 ] );
    theStruct.load( raw );
    assert( theStruct.byteField == 7 );

    // struct 2
    struct Struct2
    {
        ubyte  byteField;
        string stringField;
    }

    Struct2 theStruct2 = Struct2( 7, "AB" );

    raw = theStruct2.save( raw );
    assert( raw == [ 7, 2, 0, 0, 0, 0, 0, 0, 0, 'A', 'B' ] );
    theStruct2.load( raw );
    assert( theStruct2.byteField == 7 );
    assert( theStruct2.stringField == "AB" );

    // struct 3
    struct SymbolFile
    {
        size_t n;
        string path;
        ulong  mtime;
    }

    SymbolFile symbolFile = SymbolFile( 7, "AB", 0xFF000000 );

    raw = symbolFile.save( raw );
    assert( raw == [ 
        7, 0, 0, 0, 0, 0, 0, 0, 
        2, 0, 0, 0, 0, 0, 0, 0, 'A', 'B', 
        0, 0, 0, 255, 0, 0, 0, 0 
        ] );
    symbolFile.load( raw );
    assert( symbolFile.n == 7 );
    assert( symbolFile.path == "AB" );
    assert( symbolFile.mtime == 0xFF000000 );

    // array of struct
    struct SymbolFiles
    {
        SymbolFile[] files;
        alias files this;
    }

    SymbolFiles symbolFiles = 
        SymbolFiles( [
            SymbolFile( 7, "AB", 0xFF000000 )
        ] );

    raw = symbolFiles.save( raw );
    assert( raw == [ 
        1, 0, 0, 0, 0, 0, 0, 0, 
        7, 0, 0, 0, 0, 0, 0, 0, 
        2, 0, 0, 0, 0, 0, 0, 0, 'A', 'B', 
        0, 0, 0, 255, 0, 0, 0, 0 
        ] );
    symbolFiles.load( raw );
    assert( symbolFiles.files.length == 1 );
    assert( symbolFiles.files[ 0 ].n == 7 );
    assert( symbolFiles.files[ 0 ].path == "AB" );
}


/// 
unittest
{
    struct SymbolFile
    {
        size_t n;
        string path;
        ulong  mtime;
    }

    struct SymbolFiles
    {
        SymbolFile[] files;
        alias files this;
    }

    auto first = 
        SymbolFiles( [
            SymbolFile( 7, "AB", 0xFF000000 )
        ] );

    auto rf = RawFile( r".rawfile.dat" );
    rf.save( first );

    SymbolFiles second;
    rf.load( second );
    assert( second.files.length   == first.files.length );
    assert( second.files[0].n     == first.files[0].n );
    assert( second.files[0].path  == first.files[0].path );
    assert( second.files[0].mtime == first.files[0].mtime );
}

