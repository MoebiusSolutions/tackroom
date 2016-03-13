/* These flags can be specified when first creating an environment,
   and some can also be used when starting a transaction.
*/
primitive MDBenvflag
  fun fixedmap(): FlagMask => 0x01   // mmap at a fixed address (experimental)
  fun nosubdir(): FlagMask => 0x400  // no environment directory
  fun nosync(): FlagMask => 0x10000  // don't fsync after commit
  fun rdonly(): FlagMask => 0x20000  // No modifications allowed
  fun nometasync(): FlagMask => 0x40000  // don't fsync metapage after commit
  fun writemap(): FlagMask => 0x80000  // use writable mmap
  fun mapasync(): FlagMask => 0x100000 // use async msync when WRITEMAP is used
  fun notls(): FlagMask => 0x200000    // tie reader locktable slots to txn
		// objects instead of to threads
  fun nolock(): FlagMask => 0x400000   // don't do any locking,
	  // caller must manage their own locks */
  fun nordahead(): FlagMask => 0x800000 // don't do readahead (no effect on Windows)
  fun nomeminit(): FlagMask => 0x1000000 // don't initialize malloc'd memory before writing to datafile

/* This flag is only used on COPY operations.
*/
primitive MDBcopyflag
  fun compact(): FlagMask => 0x01  // Omit free space from copy,
				// and renumber all pages sequentially.

/* These flags can be specified when opening a database.
*/
primitive MDBopenflag
  fun reversekey(): FlagMask => 0x02   // use reverse string keys
  fun dupsort(): FlagMask => 0x04     // use sorted duplicates
  fun integerkey(): FlagMask => 0x08  // numeric keys in native byte order: either unsigned int or size_t.
  fun dupfixed(): FlagMask => 0x10   // with DUPSORT, sorted dup items have fixed size
  fun integerdup(): FlagMask => 0x20 // with DUPSORT, dups are INTEGERKEY-style integers
  fun reversedup(): FlagMask => 0x40 // with DUPSORT, use reverse string dups
  fun createdb(): FlagMask => 0x40000  // create DB if not already existing

/* These flags can be specified on 'write' operations.
*/
primitive MDBputflag
  fun nooverwrite(): FlagMask => 0x10 // For put: Don't write if the key already exists.
  fun nodupdata(): FlagMask => 0x20 // Only for #MDB_DUPSORT:
      // For put: don't write if the key and data pair already exist.
      // For mdb_cursor_del: remove all duplicate data items.
  fun current(): FlagMask => 0x40 // For mdb_cursor_put: overwrite the current key/data pair
  fun reserve(): FlagMask => 0x10000 // For put: Just reserve space for data,
		// don't copy it. Return a pointer to the reserved space.
  fun append(): FlagMask => 0x20000 //  Data is being appended, don't split full pages.
  fun appenddup(): FlagMask => 0x40000 // Duplicate data is being appended, don't split full pages.
  fun multiple(): FlagMask => 0x80000 // Store multiple data items in one call. Only for #MDB_DUPFIXED.

