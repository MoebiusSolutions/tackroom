use "debug"

use @mdb_dbi_close[None]( env: Pointer[MDBenv], dbi: Pointer[MDBdbi] )
use @mdb_stat[Stat]( txn: Pointer[MDBtxn], dbi: Pointer[MDBdbi], dbstat: MDBstat )
use @mdb_put[Stat]( txn: Pointer[MDBtxn] tag,
      dbi: Pointer[MDBdbi] tag,
      key: MDBValSend, data: MDBValSend,
      flags: FlagMask )
use @mdb_del[Stat]( txn: Pointer[MDBtxn] tag, dbi: Pointer[MDBdbi] tag,
      key: MDBValSend, data: (MDBValSend | Pointer[U8]) )
use @mdb_dbi_flags[Stat]( txn: Pointer[MDBtxn],
      dbi: Pointer[MDBdbi],
      flags: Pointer[U32] )
use @mdb_get[Stat]( txn: Pointer[MDBtxn],
      dbi: Pointer[MDBdbi] tag,
      key: MDBValSend,
      data: MDBValReceive )
use @mdb_cursor_dbi[Pointer[MDBdbi]]( cur: Pointer[MDBcur] )
use @mdb_cursor_open[Stat]( txn: Pointer[MDBtxn], dbi: Pointer[MDBdbi],
	cur: Pointer[Pointer[MDBcur]] )

// Flags on opening a database.  These can be combined.
primitive MDBopenflag
  fun reversekey(): FlagMask => 0x02   // use reverse string keys
  fun dupsort(): FlagMask => 0x04     // use sorted duplicates
  fun integerkey(): FlagMask => 0x08  // numeric keys in native byte order: either unsigned int or size_t.
  fun dupfixed(): FlagMask => 0x10   // with #MDB_DUPSORT, sorted dup items have fixed size
  fun integerdup(): FlagMask => 0x20 // with #MDB_DUPSORT, dups are #MDB_INTEGERKEY-style integers
  fun reversedup(): FlagMask => 0x40 // with #MDB_DUPSORT, use reverse string dups
  fun create(): FlagMask => 0x40000  // create DB if not already existing

// Flags on write operations.
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

// Data in and out is expressed as arrays of bytes rather then Strings
// because Strings have an extra zero byte at the end, and have slightly
// different semantics.
type MDBdata is Array[U8]
primitive MDBUtil
  """
  Functions to convert between Array[U8] and the LMDB descriptor format.
  Contributed by jemc.
  """
  fun tag null_ptr[A](): Pointer[A] iso^ =>
    @pony_alloc[Pointer[A] iso^](@pony_ctx[Pointer[None] iso](), USize(0))
  
  fun tag from_a(a: Array[U8] box): MDBValSend =>
    MDBValSend(a.size(), a.cstring())
  
  fun tag to_a(mv: MDBValReceive): Array[U8] =>
    """
    Create a Pony Array[U8] from the database information.  We copy the
    data because LMDB gave us a pointer directly into the mapped memory
    area, which can change out from under us when the transaction ends.
    """
    Array[U8].from_cstring(mv.data, mv.size).clone()

struct box MDBValSend
  """
  Generic structure used for passing keys and data INTO the database.

  Key sizes must be between 1 and env.maxkeysize() inclusive.
  The same applies to data sizes in databases with the DUPSORT flag.
  Other data items can in theory be from 0 to 0xffffffff bytes long.
  """
  let size: USize
  let data: Pointer[U8] tag
  new box create(size': USize, data': Pointer[U8] tag) =>
    size = size'; data = data'

struct ref MDBValReceive
  """
  Generic structure used for passing keys and data OUT of the database.

  Values returned from the database are valid only until a subsequent
  update operation, or the end of the transaction, so we copy any
  returned data into Pony-space.
  The fields will be overwritten by LMDB so we just initialize them
  to zero for now.
  """
  var size: USize = 0
  var data: Pointer[U8] ref = MDBUtil.null_ptr[U8]()

class MDBDatabase
  """
  An LMDB "database" is a separate B-tree within the MDBEnvironment.
  The MDBEnvironment maps to a single file in the file system and there
  can be one or more B-trees within it.
  """
  let _env: MDBEnvironment
  let _mdbenv: Pointer[MDBenv]
  let _mdbtxn: Pointer[MDBtxn]
  let _mdbdbi: Pointer[MDBdbi]

  new create( env: MDBEnvironment,
	  txn: Pointer[MDBtxn], dbi: Pointer[MDBdbi] ) =>
    _env = env
    _mdbenv = env.getenv()
    _mdbtxn = txn
    _mdbdbi = dbi

  fun ref stats(): MDBstat =>
    """
    Retrieve statistics for a database.
    """
    var dbstats = MDBstat.create()
    let err = @mdb_stat( _mdbtxn, _mdbdbi, dbstats )
    dbstats

  fun ref flags(): FlagMask =>
    """
    Retrieve the DB flags for a database handle.
    """
    var flagp: FlagMask = 0
    let err = @mdb_dbi_flags( _mdbtxn, _mdbdbi, addressof flagp )
    flagp
 
  fun ref close() =>
    """
    Close a database handle. Normally unnecessary. Use with care:
    This call is not mutex protected. Handles should only be closed by
    a single thread, and only if no other threads are going to reference
    the database handle or one of its cursors any further. Do not close
    a handle if an existing transaction has modified its database.
    Doing so can cause misbehavior from database corruption to errors
    like MDB_BAD_VALSIZE (since the DB name is gone).

    Closing a database handle is not necessary, but lets #mdb_dbi_open()
    reuse the handle value.  Usually it's better to set a bigger
    env.set_maxdbs(), unless that value would be large.
    """
    @mdb_dbi_close( _mdbenv, _mdbdbi )

/* @brief Empty or delete+close a database.
 *
 * See #mdb_dbi_close() for restrictions about closing the DB handle.
 * @param[in] txn A transaction handle returned by #mdb_mdbtxn_begin()
 * @param[in] dbi A database handle returned by #mdb_dbi_open()
 * @param[in] del 0 to empty the DB, 1 to delete it from the
 * environment and close the DB handle.
 * @return A non-zero error value on failure and 0 on success.
 */
//int  mdb_drop(MDB_mdbtxn *txn, Mdb_dbi dbi, int del);

  fun ref apply( key: Array[U8] ): Array[U8] =>
    """
    This function retrieves key/data pairs from the database.
    If the database supports duplicate keys (#MDB_DUPSORT) then the
    first data item for the key will be returned. Retrieval of other
    items requires the use of cursor.get().
    The memory pointed to by the returned values is owned by the
    database. The caller need not dispose of the memory, and may not
    modify it in any way. For values returned in a read-only transaction
    any modification attempts will cause a SIGSEGV.
     """
    var data: MDBValReceive = MDBValReceive.create()
    var keybuf = MDBUtil.from_a(key)
    let err = @mdb_get( _mdbtxn, _mdbdbi, keybuf, data)
    _env.report_error( err )
     MDBUtil.to_a( data )

  fun ref update( key: MDBdata, value: MDBdata, flag: FlagMask = 0 ) =>
    """
    Store items into a database.
    This function stores key/data pairs in the database. The default behavior
    is to enter the new key/data pair, replacing any previously existing key
    if duplicates are disallowed, or adding a duplicate data item if
    duplicates are allowed (DUPSORT).
    """
    var keydesc = MDBUtil.from_a( key )
    var valdesc = MDBUtil.from_a( value )
    Debug.out("DBI update Keylen "+keydesc.size.string())
    Debug.out("DBI update Datlen "+valdesc.size.string())

    let err = @mdb_put( _mdbtxn, _mdbdbi,
         keydesc, valdesc, flag )
    _env.report_error( err )

  fun ref delete( key: MDBdata, data: (MDBdata | None) = None ) =>
    """
    This function removes key/data pairs from the database.
    If the database does not support sorted duplicate data items
    (DUPSORT) the data parameter is ignored.
    If the database supports sorted duplicates and the data parameter
    is NULL, all of the duplicate data items for the key will be
    deleted. Otherwise, if the data parameter is not None
    only the matching data item will be deleted.
    This function will return NOTFOUND if the specified key/data
    pair is not in the database.
    """
    var keydesc = MDBUtil.from_a(key)
    match data
    | None =>
	let err = @mdb_del( _mdbtxn, _mdbdbi, keydesc, Pointer[U8].create() )
	_env.report_error( err )
    | let d: Array[U8] =>
	var valdesc = MDBUtil.from_a( d )
	let err = @mdb_del( _mdbtxn, _mdbdbi, keydesc, valdesc )
	_env.report_error( err )
    end

  fun ref cursor(): MDBCursor =>
    """
    Create a cursor handle.
    A cursor is associated with a specific transaction and database.
    A cursor cannot be used when its database handle is closed.  Nor
    when its transaction has ended, except with #mdb_cursor_renew().
    It can be discarded with #mdb_cursor_close().
    A cursor in a write-transaction can be closed before its transaction
    ends, and will otherwise be closed when its transaction ends.
    A cursor in a read-only transaction must be closed explicitly, before
    or after its transaction ends. It can be reused with
    cursor.renew() before finally closing it. 
    """
    var cur = Pointer[MDBcur].create()
    let err = @mdb_cursor_open( _mdbtxn, _mdbdbi, addressof cur )
    _env.report_error( err )
    MDBCursor.create( _env, cur )

