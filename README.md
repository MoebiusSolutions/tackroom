# Pony interface to databases

This package contains interfaces to a few simple databases.

* LMDB (Lightning Memory Mapped Database) is an open source high-performance
memory-mapped B-tree key-value database written by
[Symas Corporation](symas.com/lmdb).  Online documentation is
[here](http://symas.com/mdb/doc/), though the Pony wrapper simplifies
most of it.
Source is available at [https://github.com/LMDB/lmdb.git](https://github.com/LMDB/lmdb.git).

* LevelDB is an open source key-value database written by Google
and source is available at [https://github.com/google/leveldb.git](https://github.com/google/leveldb.git)  

    LevelDB is a simple key-value store with no added features like
secondary indices, distribution, etc.  Keys and values can be
any byte sequences.

## LMDB Usage

The LMDB interface supports these functions:

* Full-database, duplicate-key group, and partial key match scans
* Use of Pony iterator notation for clean query code
* Access to all lower level LMDB cursor operations
* Transactions
* Multiple 'databases' in one file.  (actually separate B-trees - think of them as tables)
* Use of Array[U8], String, or U32 types as keys and data inputs
* Supports Pony 'sugar' notation for simple insert and retreival

See the file lmdb/test.pony for examples.

## LevelDB Usage

See the file leveldb/test.pony

## To do

* More of the management interface
* Index tables
