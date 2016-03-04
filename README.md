Pony interface to LevelDB
=========================

LevelDB is an open source key-value database written by Google.
It is available at https://github.com/google/leveldb.git

LevelDB is a simple key-value store with no added features like
secondary indices, distribution, etc.  Keys and values can be
any byte sequences.

To do
-----

* Memory management, copying strings, freeing things
* Use ByteSeq instead of String where possible for binary transparency
* More of the management interface
* Index tables