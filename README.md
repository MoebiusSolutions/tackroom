# Pony interface to databases

This package contains interfaces to a few simple databases.

* LevelDB is an open source key-value database written by Google
and source is available at https://github.com/google/leveldb.git  

    LevelDB is a simple key-value store with no added features like
secondary indices, distribution, etc.  Keys and values can be
any byte sequences.

* LMDB (Lightning Memory Mapped Database) is an open source high-performance memory-mapped B-tree key-value database
written by Symas Corporation.  Source is available at https://github.com/LMDB/lmdb.git.

## LevelDB Usage

Basic functionality is working.  Development continues to fill out functionality in the area of cursors.

* Open a database, creating one if it does not exist.  LevelDB databases are file system *directories*.  An optional second parameter is a **Bool** to enable synchronous writes (default *false*).
```
     let db = LevelDB.create( "dirpath" )
```

* Open a database but error if it does not exist.
```
     let db = LevelDB.open( "dirpath" )
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

* Fetch the most recent error text.  It will be a null string if there was no error.
```
      let msg = db.errtxt
```

## LMDB Usage

Under development.

## To do

* Memory management, copying strings, freeing things
* Range retreivals using iterators.
* Use ByteSeq instead of String where possible for binary transparency
* More of the management interface
* Index tables