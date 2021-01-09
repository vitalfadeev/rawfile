# rawfile
Serialize / deserialize struct | scalar type | string to raw bytes

```
///
unittest
{
    // string
    string s = "AB";
    
    auto raw = s.save();
    assert( raw == [ 2, 0, 0, 0, 0, 0, 0, 0, 'A', 'B' ] );
    s.load( raw );
    assert( s == "AB" );

    // ubyte
    ubyte theByte = 7;

    raw = theByte.save();
    assert( raw == [ 7 ] );
    theByte.load( raw );
    assert( theByte == 7 );

    // struct
    struct Struct
    {
        ubyte byteField;
    }

    Struct theStruct = Struct( 7 );

    raw = theStruct.save();
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

    raw = theStruct2.save();
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

    raw = symbolFile.save();
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

    raw = symbolFiles.save();
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
```
