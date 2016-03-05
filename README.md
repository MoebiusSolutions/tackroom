Pony interface to LevelDB
=========================

LevelDB is an open source key-value database written by Google.
It is available at https://github.com/google/leveldb.git

LevelDB is a simple key-value store with no added features like
secondary indices, distribution, etc.  Keys and values can be
any byte sequences.

Usage
-----

* Open a database.  LevelDB databases are file system *directories*.  
```
     let db = LevelDB( "dirpath" )
```

* Write a record.
```
     db( key ) = value
```

* Fetch a record.  Throws error if not found.
```
     let value = db( key )
```

* Close the database.
```
      db.close()
```

To do
-----

* Memory management, copying strings, freeing things
* Use ByteSeq instead of String where possible for binary transparency
* More of the management interface
* Index tables