use @mdb_cursor_get[USize]( curs: Pointer[MDB_cur],
   key: Pointer[MDB_value], data: Pointer[MDB_value],
   op: MDB_cursor_op )
use @mdb_cursor_put[USize]( cursor: Pointer[MDB_cur],
    key: Pointer[MDB_value], data: Pointer[MDB_value],
    flags: USize )
use @mdb_cursor_del[USize]( mdb: Pointer[U8], flags: USize )
use @mdb_cursor_count[USize]( mdb: Pointer[U8], count: Pointer[USize] )
use @mdb_cursor_close[None]( cur: Pointer[MDBcur] )
use @mdb_cursor_get[USize]( curs: Pointer[MDBcur],
    key: Pointer[MDBval], data: Pointer[MDBval], op: USize )

class MDBCursor
  let _cur: Pointer[MDB_cur]
  new create( cursor: Pointer[MDB_cur] ) =>
    _cur = cur

  fun ref close() =>
    """
    Close a cursor handle.
    The cursor handle will be freed and must not be used again after this call.
    Its transaction must still be live if it is a write-transaction.
     """
     @mdb_cursor_close( _cur )

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

int  mdb_cursor_renew(MDB_txn *txn, MDB_cursor *cursor);
*/

  fun ref apply( key: String, op: USize ): String =>
    """
    Retrieve by cursor.
    This function retrieves key/data pairs from the database.
    The address and length
    of the key are returned in the object to which \b key refers (except for the
    case of the #MDB_SET option, in which the \b key object is unchanged), and
    the address and length of the data are returned in the object to which \b data
    refers.
    See MDBTransaction.get() for restrictions on using the output values.
     """
     let key = MDBval.create()
     let data = MDBval.create()
     let err = @mdb_cursor_get( _cur, addressof key, addressof data, op )
     (key.string(), data.string())
    
  fun ref update( key: String, data: String, flags: USize = 0 ) =>
    """
    Store by cursor.
 *
 * This function stores key/data pairs into the database.
 * The cursor is positioned at the new item, or on failure usually near it.
 * @note Earlier documentation incorrectly said errors would leave the
 * state of the cursor unchanged.
 * @param[in] cursor A cursor handle returned by #mdb_cursor_open()
 * @param[in] key The key operated on.
 * @param[in] data The data operated on.
 * @param[in] flags Options for this operation. This parameter
 * must be set to 0 or one of the values described here.
 * <ul>
 * <li>#MDB_CURRENT - replace the item at the current cursor position.
 *	The \b key parameter must still be provided, and must match it.
 *	If using sorted duplicates (#MDB_DUPSORT) the data item must still
 *	sort into the same place. This is intended to be used when the
 *	new data is the same size as the old. Otherwise it will simply
 *	perform a delete of the old record followed by an insert.
 *<li>#MDB_NODUPDATA - enter the new key/data pair only if it does not
 *	already appear in the database. This flag may only be specified
 *	if the database was opened with #MDB_DUPSORT. The function will
 *	return #MDB_KEYEXIST if the key/data pair already appears in the
 *	database.
 *<li>#MDB_NOOVERWRITE - enter the new key/data pair only if the key
 *	does not already appear in the database. The function will return
 *	#MDB_KEYEXIST if the key already appears in the database, even if
 *	the database supports duplicates (#MDB_DUPSORT).
 *<li>#MDB_RESERVE - reserve space for data of the given size, but
 *	don't copy the given data. Instead, return a pointer to the
 *	reserved space, which the caller can fill in later - before
 *	the next update operation or the transaction ends. This saves
 *	an extra memcpy if the data is being generated later. This flag
 *	must not be specified if the database was opened with #MDB_DUPSORT.
 *<li>#MDB_APPEND - append the given key/data pair to the end of the
 *	database. No key comparisons are performed. This option allows
 *	fast bulk loading when keys are already known to be in the
 *	correct order. Loading unsorted keys with this flag will cause
 *	a #MDB_KEYEXIST error.
 *<li>#MDB_APPENDDUP - as above, but for sorted dup data.
 *<li>#MDB_MULTIPLE - store multiple contiguous data elements in a
 *	single request. This flag may only be specified if the database
 *	was opened with #MDB_DUPFIXED. The \b data argument must be an
 *	array of two MDB_vals. The mv_size of the first MDB_val must be
 *	the size of a single data element. The mv_data of the first MDB_val
 *	must point to the beginning of the array of contiguous data elements.
 *	The mv_size of the second MDB_val must be the count of the number
 *	of data elements to store. On return this field will be set to
 *	the count of the number of elements actually written. The mv_data
 *	of the second MDB_val is unused.
 * </ul>
     """
     let err = @mdb_cursor_put( _cur,
         MDB_value.from_string(key),
         MDB_value.from_string(data),
	 flags )
//int  mdb_cursor_put(MDB_cursor *cursor, MDB_val *key, MDB_val *data, unsigned int flags);
				
/** @brief Delete current key/data pair
 *
 * This function deletes the key/data pair to which the cursor refers.
 * @param[in] cursor A cursor handle returned by #mdb_cursor_open()
 * @param[in] flags Options for this operation. This parameter
 * must be set to 0 or one of the values described here.
 * <ul>
 *	<li>#MDB_NODUPDATA - delete all of the data items for the current key.
 *	This flag may only be specified if the database was opened with #MDB_DUPSORT.
 * </ul>
 * @return A non-zero error value on failure and 0 on success. Some possible
 * errors are:
 * <ul>
 *	<li>EACCES - an attempt was made to write in a read-only transaction.
 *	<li>EINVAL - an invalid parameter was specified.
 * </ul>
 */
//int  mdb_cursor_del(MDB_cursor *cursor, unsigned int flags);

/** @brief Return count of duplicates for current key.
 *
 * This call is only valid on databases that support sorted duplicate
 * data items #MDB_DUPSORT.
 * @param[in] cursor A cursor handle returned by #mdb_cursor_open()
 * @param[out] countp Address where the count will be stored
 * @return A non-zero error value on failure and 0 on success. Some possible
 * errors are:
 * <ul>
 *	<li>EINVAL - cursor is not initialized, or an invalid parameter was specified.
 * </ul>
 */
//int  mdb_cursor_count(MDB_cursor *cursor, mdb_size_t *countp);
