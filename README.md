# Pony interface to databases

This package contains interfaces to a few simple databases.

* LevelDB is an open source key-value database written by Google
and source is available at https://github.com/google/leveldb.git  

    LevelDB is a simple key-value store with no added features like
secondary indices, distribution, etc.  Keys and values can be
any byte sequences.

* LMDB (Lightning Memory Mapped Database) is an open source high-performance
memory-mapped B-tree key-value database written by Symas Corporation.
Source is available at https://github.com/LMDB/lmdb.git.

## LevelDB Usage

See the file leveldb/test.pony

## LMDB Usage

See the file lmdb/test.pony

## To do

* Array[U8] to String conversions and reverse
* Memory management, copying strings, freeing things
* Range retreivals using iterators.
* More of the management interface
* Index tables