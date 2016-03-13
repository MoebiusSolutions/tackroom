use "debug"
use @mdb_dbi_close[None]( env: Pointer[MDBenv], dbi: Pointer[MDBdbi] )
use @mdb_stat[Stat]( txn: Pointer[MDBtxn], dbi: Pointer[MDBdbi], dbstat: MDBstat )
use @mdb_put[Stat]( txn: Pointer[MDBtxn] tag,
      dbi: Pointer[MDBdbi] tag,
      key: MDBValue, data: MDBValue,
      flags: FlagMask )
use @mdb_del[Stat]( txn: Pointer[MDBtxn] tag, dbi: Pointer[MDBdbi] tag,
      key: MDBValue, data: _OptionalData )
use @mdb_dbi_flags[Stat]( txn: Pointer[MDBtxn],
      dbi: Pointer[MDBdbi],
      flags: Pointer[U32] )
use @mdb_get[Stat]( txn: Pointer[MDBtxn],
      dbi: Pointer[MDBdbi] tag,
      key: MDBValue,
      data: MDBValue )
use @mdb_cursor_dbi[Pointer[MDBdbi]]( cur: Pointer[MDBcur] )
use @mdb_cursor_open[Stat]( txn: Pointer[MDBtxn], dbi: Pointer[MDBdbi],
	cur: Pointer[Pointer[MDBcur]] )
use @mdb_drop[Stat]( txn: Pointer[MDBtxn], dbi: Pointer[MDBdbi], del: U32 )

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

  fun ref drop( del: Bool = false ) ? =>
    """
    Empty or delete+close a database.
    See dbi.close() for restrictions about closing the DB handle.
    Paramater is 'false' to empty the DB, true to delete it from the
    environment and close the DB handle.
    """
    let err = @mdb_drop( _mdbtxn, _mdbdbi, if del then 1 else 0 end )
    _env.report_error( err )

    fun ref apply( key: MDBdata ): Array[U8] ? =>
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
    var data: MDBValue = MDBValue.create()
    var keybuf = MDBValue.create( key )
    let err = @mdb_get( _mdbtxn, _mdbdbi, keybuf, data)
    _env.report_error( err )
    data.array()

  fun ref update( key: MDBdata, value: MDBdata, flag: FlagMask = 0 ) ? =>
    """
    Store items into a database.
    This function stores key/data pairs in the database. The default behavior
    is to enter the new key/data pair, replacing any previously existing key
    if duplicates are disallowed, or adding a duplicate data item if
    duplicates are allowed (DUPSORT).
    """
    var keydesc = MDBValue.create(key)
    var valdesc = MDBValue.create(value)

    let err = @mdb_put( _mdbtxn, _mdbdbi,
         keydesc, valdesc, flag )
    _env.report_error( err )

  fun ref delete( key: MDBdata, data: (MDBdata | None) = None ) ? =>
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
    var keydesc = MDBValue.create(key)
    match data
    | None =>
        let err = @mdb_del( _mdbtxn, _mdbdbi,
            keydesc, _OptionalData.none())
	_env.report_error( err )
    | let d: MDBdata =>
	var valdesc = MDBValue.create(d)
	let err = @mdb_del( _mdbtxn, _mdbdbi,
		keydesc, _OptionalData.create(valdesc) )
	_env.report_error( err )
    end

  fun ref cursor(): MDBCursor ? =>
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

  // These functions return record sequence queries that will return
  // all or a selected subset of a databse, using the Pony iterator notation.
  fun ref all(): MDBSequence ? => MDBSequence.create( this, None )
  fun ref group( start: MDBdata ): MDBSequence ? =>
    MDBSequence.create( this, start )
  fun ref partial( start: MDBdata): MDBSequence ? =>
    MDBSequence.create( this, start, true )

class MDBSequence
  """
  The guts of the three kinds of iterators.  This implements the logic
  of the query.
  """
  var first: Bool = true
  let curs: MDBCursor
  let start: (MDBdata | None)
  let partial: Bool
  var nextkey: Array[U8] = Array[U8]
  var nextval: Array[U8] = Array[U8]

  new create( dbi: MDBDatabase,
	  start': (MDBdata | None) = None,
	  partial': Bool = false ) ? =>
    curs = dbi.cursor()
    start = match start'
	| None => None
	else
	  MDBConvert.array( start' )
	end
    partial = partial'

  // These three methods generate the actual iterator that Pony will use.
  // They will call back here to get the data.
  fun ref pairs(): MDBPairIter  => MDBPairIter.create( this )
  fun ref keys(): MDBKeyIter    => MDBKeyIter.create( this )
  fun ref values(): MDBValIter  => MDBValIter.create(this )

  fun ref has_next(): Bool =>
    """
    Determine whether the next record to be fetched actually exists,
    according to the query criteria.  In LMDB the only way to find
    this out is to actually try to fetch the data.  Luckily, this
    is very fast.
    """
    try
      (nextkey,nextval) =
      if first then
        // First time thru, get the first record of the desired series,
        // and clear the first-time flag.
        first = false
        match start
	  | let skey: MDBdata => curs.seek( skey, partial )
	  else
           curs( MDBop.first() )
	  end
      else
        // Subsequent times, get the next record in that series.
        match start
          | let skey: MDBdata =>
	      if partial then
                curs( MDBop.next() )
	      else
	        curs( MDBop.next_dup() )
	      end
	  else curs( MDBop.next() )
        end
       end

      // If doing partial key range, the initial part of the retreived
      // key has to match the starting key fragment.
      if partial then
        _initial_match( start, nextkey )
      else true end
    else
      false
    end

  fun ref _initial_match( a1: (MDBdata | None), a2: Array[U8] ): Bool =>
    """
    True only if initial substring of a2 matches all of a1.
    """
    match a1
    | let leading: Array[U8] =>
	if leading.size() > a2.size() then return false end
	var i: USize = 0
	while i < leading.size() do
	  try if leading(i) != a2(i) then return false end else return false end
	  i=i+1
        end
      true
      else false end
	      
  fun ref next(): (Array[U8],Array[U8]) =>
    """
    Return the next record in the series.  This was actually just fetched.
    """
    (nextkey, nextval)

  fun ref dispose() => curs.close()
	
class MDBPairIter is Iterator[(Array[U8],Array[U8])]
  """
  Iterator that returns both keys and values
  """
  let query: MDBSequence
  new create( query': MDBSequence ) =>
    query = query'

  fun ref has_next(): Bool => query.has_next()
  fun ref next(): (Array[U8],Array[U8]) => (query.nextkey, query.nextval)
  fun ref dispose() => query.dispose()

class MDBValIter is Iterator[MDBdata]
  """
  Iterator that returns just the values
  """
  let query: MDBSequence
  new create( query': MDBSequence ) =>
    query = query'

  fun ref has_next(): Bool => query.has_next()
  fun ref next(): Array[U8] => query.nextval
  fun ref dispose() => query.dispose()

class MDBKeyIter is Iterator[MDBdata]
  """
  Iterator that returns just the keys
  """
  let query: MDBSequence
  new create( query': MDBSequence ) =>
    query = query'

  fun ref has_next(): Bool => query.has_next()
  fun ref next(): Array[U8] => query.nextkey
  fun ref dispose() => query.dispose()
