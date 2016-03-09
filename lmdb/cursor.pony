use @mdb_cursor_get[Stat]( curs: Pointer[MDBcur],
   key: MDBValReceive, data: MDBValReceive, op: U32 )
use @mdb_cursor_put[Stat]( cursor: Pointer[MDBcur],
    key: MDBValSend, data: MDBValSend, flags: FlagMask)
use @mdb_cursor_del[Stat]( cur: Pointer[MDBcur], flags: FlagMask )
use @mdb_cursor_count[Stat]( cur: Pointer[MDBcur], count: Pointer[U32] )
use @mdb_cursor_close[None]( cur: Pointer[MDBcur] )

// Op-codes for cursor operations.			 
primitive MDBcursorop
  fun first(): U32 => 0           // Position at first key/data item
  fun first_dup(): U32 => 1       // Position at first data item of current key.
  fun get_both(): U32 => 2        // Seek to first key/data for DUPSORT
  fun get_both_range(): U32 => 3  // Seek to key, nearest data for DUPSORT
  fun get_current(): U32 => 4     // Return current position data
  fun get_multiple(): U32 => 5    // Return key and up to a page of dups.
					// Move to prepare for NEXT_MULTIPLE
  fun last(): U32 => 6            // Seek to last item
  fun last_dup(): U32 => 7        // Seek to last of current dup group
  fun next(): U32 => 8            // Seek to next record
  fun next_dup(): U32 => 9        // Seek to next in dup group
  fun next_multiple(): U32 => 10  // Key and up to a page of dups.
  fun next_nodup(): U32 => 11     // Seek to next unique key
  fun prev(): U32 => 12           // Seek backwards one record
  fun prev_dup(): U32 => 13       // Seek backwards in same dup group
  fun prev_nodup(): U32 => 14     // Seek last item of previous key
  fun set(): U32 => 15            // Seek to key, no fetch
  fun set_key(): U32 => 16        // Seek to key, fetch
  fun set_range(): U32 => 17      // Seek to first greater key
  fun prev_multiple(): U32 => 18  // Seek previous page

class MDBCursor
  let _mdbcur: Pointer[MDBcur]
  let _env: MDBEnvironment
  new create( env: MDBEnvironment, cursor: Pointer[MDBcur] ) =>
    _mdbcur = cursor
    _env = env

  fun ref close() =>
    """
    Close a cursor handle.
    The cursor handle will be freed and must not be used again after this call.
    Its transaction must still be live if it is a write-transaction.
    """
    @mdb_cursor_close( _mdbcur )

/* @brief Renew a cursor handle.
 *
 * A cursor is associated with a specific transaction and database.
 * Cursors that are only used in read-only
 * transactions may be re-used, to avoid unnecessary malloc/free overhead.
 * The cursor may be associated with a new read-only transaction, and
 * referencing the same database handle as it was created with.
 * This may be done whether the previous transaction is live or dead.
 * @param[in] txn A transaction handle returned by #mdb_txn_begin()
 * @param[in] cursor A cursor handle returned by #mdb_cursor_open()
 * @return A non-zero error value on failure and 0 on success. Some possible
 * errors are:
 * <ul>
 *	<li>EINVAL - an invalid parameter was specified.
 * </ul>

int  mdb_cursor_renew(MDB_txn *txn, MDBcursor *cursor);
*/

  fun ref apply( op: U32 ): (MDBdata, MDBdata) =>
    """
    Retrieve by cursor.
    This function retrieves key/data pairs from the database.
    The address and length of the key are returned in the object to
    which \b key refers (except for the case of the SET option, in which
    the \b key object is unchanged), and the address and length of the
    data are returned in the object to which \b data refers.
    See MDBTransaction.get() for restrictions on using the output values.
     """
     var keyp = MDBValReceive.create()
     var datap = MDBValReceive.create()
     let err = @mdb_cursor_get( _mdbcur, keyp, datap, op )
     (MDBUtil.to_a(keyp), MDBUtil.to_a(datap))
    
  fun ref update( key: MDBdata, data: MDBdata, flags: FlagMask = 0 ) =>
    """
    Store by cursor.
    This function stores key/data pairs into the database.
    The cursor is positioned at the new item, or on failure usually near it.
    """
    var keyp = MDBUtil.from_a(key)
    var datap = MDBUtil.from_a(data)
    let err = @mdb_cursor_put( _mdbcur, keyp, datap, flags )

  fun ref delete( flags: FlagMask = 0 ) =>
    """
    Delete current key/data pair
    This function deletes the key/data pair to which the cursor refers.
    Flag NODUPDATA - delete all of the data items for the current key.
    This flag may only be specified if the database was opened with DUPSORT.
    """
    let err = @mdb_cursor_del( _mdbcur, flags )

  fun ref dupcount(): U32 =>
    """
    Count of duplicates for current key.
    This call is only valid on databases that support sorted duplicate
    data items DUPSORT.
    """
    var count: U32 = 0
    let err = @mdb_cursor_count( _mdbcur, addressof count )
    count
