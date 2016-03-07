// Library major version 0.9.70
// The release date of this library version "December 19, 2015"

use @mdb_strerror[Pointer[U8]]( err: USize )
use @mdb_env_create[USize]( env: Pointer[Pointer[U8]] )
use @mdb_version( Pointer[USize], Pointer[USize], Pointer[USize] )
use @mdb_env_stat[None]( mdb: Pointer[MDB_env],
	stat: Pointer[Poiter[MDB_stat]] )
use @mdb_env_open[USize]( env: Pointer[U8] tag,
    path: Pointer[U8], flags: USize, mode: USize )
use @mdb_env_copy[USize]( env: Pointer[MDB_env], path: Pointer[U8] )
use @mdb_env_copy2[USize]( env: Pointer[MDB_env], path: Pointer[U8], flags: USize )
use @mdb_env_stat( env: Pointer[U8], stat: Pointer[U8] )
use @mdb_env_info[USize]( env: Pointer[MDB_env] tag,
    stat: Pointer[MDB_info] )
use @mdb_env_sync[USize]( env: Pointer[MDB_env], force )
use @mdb_env_close[None]( env: Pointer[MDB_env] )
use @mdb_env_set_flags[USize]( env: Pointer[MDB_env], flags: USize, onoff: USize)
use @mdb_env_get_flags[USize]( env: Pointer[MDB_env], flags: Pointer[USize] )
use @mdb_env_get_path[USize]( env: Pointer[MDB_env], path: Pointer[Pointer[U8]] )
use @mdb_env_set_mapsize[USize]( env:Pointer[MDB_env], size: USize )
use @mdb_env_set_maxreaders[USize]( env: Pointer[MDB_env], count: USize )
use @mdb_env_get_maxreaders[USize]( env: Pointer[MDB_env] )
use @mdb_env_set_maxdbs[USize]( env: Pointer[MDB_env], count: USize )
use @mdb_env_get_maxkeysize[USize]( enc: Pointer[MDB_env] );
use @mdb_env_set_userctx[USize]( env: Pointer[MDB_env], ctx: Pointer[Any] )
use @mdb_env_get_userctx[ Pointer[Any] ]( env: Pointer[MDB_env] )

use @mdb_txn_begin[USize]( env: Pointer[MDB_env], parent: Pointer[MDB_txn],
   flags: USize, txn: Pointer[Pointer[MDB_txn]] )
use @mdb_txn_id[USize]( txn: Pointer[MDB_txn] )   
use @mdb_txn_commit( txn: Pointer[MDB_txn] )
use @mdb_txn_abort[None]( txn: Pointer[MDB_txn] )

use @mdb_dbi_open( Pointer[MDB_txn],
	name: Pointer[U8],
	flags: USize,
	dbi: Pointer[Pointer[MDB_dbi]] )
use @mdb_cursor_dbi[Pointer[MDB_dbi]]( Pointer[MDB_cur] )
use @mdb_cursor_get[USize]( curs: Pointer[MDB_cur],
   key: Pointer[MDB_value], data: Pointer[MDB_value],
   op: MDB_cursor_op )
use @mdb_cursor_put( cursor: Pointer[MDB_cur],
    key: Pointer[MDB_value], data: Pointer[MDB_value],
    flags: USize = 0 )
use @mdb_cursor_del( mdb: Pointer[U8], flags: USize )
use @mdb_cursor_count[USize]( mdb: Pointer[U8], count: Pointer[USize] )

// Opaque structures for actual LMDB handles.
primitive MDB_env
primitive MDB_txn
primitive MDB_dbi
primitive MDB_cur

/** Generic structure used for passing keys and data in and out
 * of the database.
 *
 * Values returned from the database are valid only until a subsequent
 * update operation, or the end of the transaction. Do not modify or
 * free them, they commonly point into the database itself.
 *
 * Key sizes must be between 1 and #mdb_env_get_maxkeysize() inclusive.
 * The same applies to data sizes in databases with the #MDB_DUPSORT flag.
 * Other data items can in theory be from 0 to 0xffffffff bytes long.
 */
class MDB_val
  var size: USize = 0
  var data: Pointer[U8]
  new apply( data': Pointer[U8], size': USize ) =>
    size = size'
    data = data'
  new create() => None
	    
//  Flags on creating an environment
primitive MDB_env_flag
  fun fixedmap() => 0x01   // mmap at a fixed address (experimental)
  fun nosubdir() => 0x400  // no environment directory
  fun nosync() => 0x10000  // don't fsync after commit
  fun rdonly() => 0x20000  
  fun nometasync() => 0x40000  // don't fsync metapage after commit
  fun writemap() => 0x80000  // use writable mmap
  fun mapasync() => 0x100000 // use asynchronous msync when #MDB_WRITEMAP is used
  fun notls() => 0x200000    // tie reader locktable slots to #MDB_txn
		// objects instead of to threads
  fun nolock() => 0x400000   // don't do any locking,
	  // caller must manage their own locks */
  fun nordahead() => 0x800000 // don't do readahead (no effect on Windows)
  fun nomeminit() => 0x1000000 // don't initialize malloc'd memory before writing to datafile

// Flags on opening a database.  These can be combined.
primitive MDB_open_flag
  fun reversekey() => 0x02   // use reverse string keys */
  fun dupsort() => 0x04     // use sorted duplicates */
  fun integerkey() => 0x08  // numeric keys in native byte order: either unsigned int or size_t.
  fun dupfixed() => 0x10   // with #MDB_DUPSORT, sorted dup items have fixed size
  fun integerdup() => 0x20 // with #MDB_DUPSORT, dups are #MDB_INTEGERKEY-style integers */
  fun reversedup() => 0x40 // with #MDB_DUPSORT, use reverse string dups */
  fun create() => 0x40000  // create DB if not already existing */

// Flags on write operations.
primitive MDB_put_flag
  fun nooverwrite() => 0x10 // For put: Don't write if the key already exists.
  fun nodupdata() => 0x20 // Only for #MDB_DUPSORT:
      // For put: don't write if the key and data pair already exist.<br>
      // For mdb_cursor_del: remove all duplicate data items.
  fun current() => 0x40 // For mdb_cursor_put: overwrite the current key/data pair
  fun reserve() => 0x10000 // For put: Just reserve space for data,
		// don't copy it. Return a pointer to the reserved space.
  fun append() => 0x20000 //  Data is being appended, don't split full pages.
  fun appenddup() => 0x40000 // Duplicate data is being appended, don't split full pages.
  fun multiple() => 0x80000 // Store multiple data items in one call. Only for #MDB_DUPFIXED.

// Flags on copy operations
primitive MDB_copy_flag
  fun compact() => 0x01  // Omit free space from copy, and renumber all
	                 // pages sequentially.

// Op-codes for cursor operations.			 
primitive MDB_cursor_op
  fun first(): USize => 0           // Position at first key/data item
  fun first_dup(): USize => 1       // Position at first data item of current key.
  fun get_both(): USize => 2
  fun get_both_range(): USize => 3
  fun get_current(): USize => 4
  fun get_multiple(): USize => 5
  fun last(): USize => 6
  fun last_dup(): USize => 7
  fun next(): USize => 8
  fun next_dup(): USize => 9
  fun next_multiple => 10
  fun next_nodup(): USize => 11
  fun prev(): USize => 12
  fun prev_dup(): USize => 13
  fun set(): USize => 14
  fun set_key(): USize => 15
  fun set_range(): USize => 16
  fun prev_multiple(): USize => 17

// Environment statistics
class MDB_stat
  var psize: USize = 0
  var depth: USize = 0
  var bpages: USize = 0
  var lpages: USize = 0
  var opages: USize = 0
  var entries: USize = 0
  new create( mdb: Pointer[U8] tag ) =>
    @mdb_env_stat( mdb, addressof this )

// Environment info
class MDB_envinfo
  var mapaddr: Pointer[U8] = Pointer[U8]() // Address of map, if fixed
  var mapsize: USize = 0     // Size of mapped area
  var last_pgno: USize = 0   // ID of last used page
  var last_txid: USize = 0   // ID of last commited transaction
  var maxreaders: USize = 0  // Max reader slots
  var numreaders: USize = 0  // Number of used slots
  new create() => None

// Get LMDB version
class MDB_version
  var major: USize = 0
  var minor: USize = 0
  var patch: USize = 0
  new create() =>
    @mdb_version( addressof major, addressof minor, addressof patch )

  fun ref errstr(): String =>
    String.from_cstring( @mdb_errstr( _errcode ) )

class MDBEnvironment
  """
  The LMDB Environment consists of a single (large) region of virtual memory
  that is mapped file.   All LMDB operations take place within this Environment.
  """
  var _mdbenv: Pointer[MDB_env]

  new create() =>
    let errcode = @mdb_env_create( addressof _mdbenv )

  fun ref open( path: String, flags: USize, mode: USize ) =>
    """
    Open the environment.  This corresponds to a single mapped file which
    can contain one or more databases.
    """
    @mdb_env_open( _mdbenv, path.cstring(), flags, mode )
		
  fun ref copy( path: String, flags: USize = 0 ) =>
    """
    Make a copy of the entire environment.  This can be used to
    create backups.
    """
    let err = (if flags == 0 then
      @mdb_env_copy( _mdbenv, path.cstring() )
    else
      @mdb_env_copy( _mdbenv, path.cstring(), flags )
    end)

 /* @brief Copy an LMDB environment to the specified file descriptor.
 *
 * This function may be used to make a backup of an existing environment.
 * No lockfile is created, since it gets recreated at need.
 * @note This call can trigger significant file size growth if run in
 * parallel with write transactions, because it employs a read-only
 * transaction. See long-lived transactions under @ref caveats_sec.
 * @param[in] env An environment handle returned by #mdb_env_create(). It
 * must have already been opened successfully.
 * @param[in] fd The filedescriptor to write the copy to. It must
 * have already been opened for Write access.
 * @return A non-zero error value on failure and 0 on success.
 */
// int  mdb_env_copyfd(MDB_env *env, mdb_filehandle_t fd);

// int  mdb_env_copy2(MDB_env *env, const char *path, unsigned int flags);

/* @brief Copy an LMDB environment to the specified file descriptor,
 *	with options.
 *
 * This function may be used to make a backup of an existing environment.
 * No lockfile is created, since it gets recreated at need. See
 * #mdb_env_copy2() for further details.
 * @note This call can trigger significant file size growth if run in
 * parallel with write transactions, because it employs a read-only
 * transaction. See long-lived transactions under @ref caveats_sec.
 * @param[in] env An environment handle returned by #mdb_env_create(). It
 * must have already been opened successfully.
 * @param[in] fd The filedescriptor to write the copy to. It must
 * have already been opened for Write access.
 * @param[in] flags Special options for this operation.
 * See #mdb_env_copy2() for options.
 * @return A non-zero error value on failure and 0 on success.
 */
// int  mdb_env_copyfd2(MDB_env *env, mdb_filehandle_t fd, unsigned int flags);

/* @brief Return statistics about the LMDB environment.
 *
 * @param[in] env An environment handle returned by #mdb_env_create()
 * @param[out] stat The address of an #MDB_stat structure
 * 	where the statistics will be copied
 */
//int  mdb_env_stat(MDB_env *env, MDB_stat *stat);

  fun ref info(): MDBinfo =>
    let info: MDBinfo = MDBinfo.create()
    @mdb_env_info( _mdbenv, addressof info )
    info

  fun ref flush( force: Bool = false ) =>
    let err = @mdb_env_sync( _mdbenv, force )

  fun ref close() =>
    @mdb_env_close( _mdbenv )

  fun ref set_flags( flags: USize, set: Bool ) =>
    """
    Set or clear environment flags after it has been created.
    """
    if set then
      @mdb_env_set_flags( _mdbenv, flags 1 )
    else
      @mdb_env_set_flags( _mdbenv, flags, 0 )
    end

  fun ref get_flags(): USize =>
    var flags: USize = 0
    let err = @mdb_env_get_flags( _mdbenv, addressof flags )
    flags

  fun ref get_path(): String =>
    """
    Get the file system path where the environment is stored.
    """
    var sptr: Pointer[U8] = Pointer[U8]()
    let err = @mdb_env_get_path( _mdbenv, addressof sptr )
    // We have to copy the string because it is in the mapped area.
    String.copy_cstring( sptr )

  fun ref set_mapsize( size: USize ) =>
    """
    Set the size of the memory map to use for this environment.
    The size should be a multiple of the OS page size. The default is
    10485760 bytes. The size of the memory map is also the maximum size
    of the database. The value should be chosen as large as possible,
    to accommodate future growth of the database.
    This function should be called after create and before open.
    """
    let err = @mdb_env_set_mapsize( _mdbenv, size )

  fun ref set_maxslots( count: USize ) =>
    """
    Set the maximum number of threads/reader slots for the environment.
    This defines the number of slots in the lock table that is used to
    track readers in the the environment. The default is 126.
    Starting a read-only transaction normally ties a lock table slot to the
    current thread until the environment closes or the thread exits. If
    MDB_NOTLS is in use, #mdb_txn_begin() instead ties the slot to the
    MDB_txn object until it or the #MDB_env object is destroyed.
    This function may only be called after create() and before open().
    """
    let err = @mdb_env_set_maxreaders( _mdbenv, count )

  fun ref slots() =>
    """
    Get the maximum number of threads/reader slots for the environment.
    """
    var count: USize = 0
    let err = @mdb_env_get_maxreaders( _mdbenv, addressof count )
    count

  fun ref set_maxdb( count: USize ) =>
    """
    Set the maximum number of named databases for the environment.
    This function is only needed if multiple databases will be used in the
    environment. Simpler applications that use the environment as a single
    unnamed database can ignore this option.
    This function may only be called after create and before open.
    Currently a moderate number of slots are cheap but a huge number gets
    expensive: 7-120 words per transaction, and every DB open does a
    linear search of the opened slots.
    """
    let err = @mdb_env_set_maxdbs( _mdbenv, count )

  fun ref maxkeysize(): USize =>
    """
    Get the maximum size of keys and #MDB_DUPSORT data we can write.
    This depends on the compile-time constant #MDB_MAXKEYSIZE. Default 511.
    """
    @mdb_env_get_maxkeysize( _mdbenv )

  fun ref set_appinfo( info: Pointer[Any] ) =>
    """
    Set application information associated with the Evironment.
    """
    let err = @mdb_env_set_userctx( _mdbenv, info )

  fun ref get_appinfo(): Pointer[Any] =>
    """
    Get the application information associated with the #MDB_env.
    """
    @mdb_env_get_userctx( _mdbenv )

  fun ref begin( flags: USize,
    parent: (MDBTransaction | None) = None ): MDBTransaction =>
    """
    Create a transaction within this environment.
    """
    var txnhdl: MDB_txn = 0
    let err = (match parent
      | None =>
	  @mdb_txn_begin( _mdbenv, Pointer[U8](), flags, addressof txnhdl )
      | let p: MDBTransaction =>
          @mdb_txn_begin( _mdbenv, parent.handle(), flags, addressof txnhdl )
    end)
	
    MDBTransaction.create( this, txnhdl )
    
class MDBTransaction
  """
  The transaction handle may be discarded using abort() or commit().
  A transaction and its cursors must only be used by a single
  thread, and a thread may only have a single transaction at a time.
  If #MDB_NOTLS is in use, this does not apply to read-only transactions.
  Cursors may not span transactions.
  """
  let _txn: MDB_txn
  let _env: MDBEnvironment
  new create( env: MDBEnvironment, txn: MDB_txn ) =>
    _txn = txn
    _env = env

  fun ref handle(): MDB_txn => _txn

  fun ref id(): USize =>
    """
    Return the transaction's ID.
    This returns the identifier associated with this transaction. For a
    read-only transaction, this corresponds to the snapshot being read;
    concurrent readers will frequently have the same transaction ID.
    """
    @mdb_txn_id( _txn )

  fun ref commit() =>
    """
    Commit all the operations of a transaction into the database.
    The transaction handle is freed. It and its cursors must not be used
    again after this call, except with #mdb_cursor_renew().
    Earlier documentation incorrectly said all cursors would be freed.
    Only write-transactions free cursors.
    """
    let err = @mdb_txn_commit( _txn )

  fun ref abort() =>
    """
    Abandon all the operations of the transaction instead of saving them.
    The transaction handle is freed. It and its cursors must not be used
    again after this call, except with #mdb_cursor_renew().
    Earlier documentation incorrectly said all cursors would be freed.
    Only write-transactions free cursors.
    """
    @mdb_txn_abort( _txn )

/* @brief Reset a read-only transaction.
 *
 * Abort the transaction like #mdb_txn_abort(), but keep the transaction
 * handle. #mdb_txn_renew() may reuse the handle. This saves allocation
 * overhead if the process will start a new read-only transaction soon,
 * and also locking overhead if #MDB_NOTLS is in use. The reader table
 * lock is released, but the table slot stays tied to its thread or
 * #MDB_txn. Use mdb_txn_abort() to discard a reset handle, and to free
 * its lock table slot if MDB_NOTLS is in use.
 * Cursors opened within the transaction must not be used
 * again after this call, except with #mdb_cursor_renew().
 * Reader locks generally don't interfere with writers, but they keep old
 * versions of database pages allocated. Thus they prevent the old pages
 * from being reused when writers commit new data, and so under heavy load
 * the database size may grow much more rapidly than otherwise.
 * @param[in] txn A transaction handle returned by #mdb_txn_begin()
 */
void mdb_txn_reset(MDB_txn *txn);

/* @brief Renew a read-only transaction.
 *
 * This acquires a new reader lock for a transaction handle that had been
 * released by #mdb_txn_reset(). It must be called before a reset transaction
 * may be used again.
 * @param[in] txn A transaction handle returned by #mdb_txn_begin()
 * @return A non-zero error value on failure and 0 on success. Some possible
 * errors are:
 * <ul>
 *	<li>#MDB_PANIC - a fatal error occurred earlier and the environment
 *		must be shut down.
 *	<li>EINVAL - an invalid parameter was specified.
 * </ul>
 */
int  mdb_txn_renew(MDB_txn *txn);

/** Compat with version <= 0.9.4, avoid clash with libmdb from MDB Tools project */
#define mdb_open(txn,name,flags,dbi)	mdb_dbi_open(txn,name,flags,dbi)
/** Compat with version <= 0.9.4, avoid clash with libmdb from MDB Tools project */
#define mdb_close(env,dbi)				mdb_dbi_close(env,dbi)

/* @brief Open a database in the environment.
 *
 * A database handle denotes the name and parameters of a database,
 * independently of whether such a database exists.
 * The database handle may be discarded by calling #mdb_dbi_close().
 * The old database handle is returned if the database was already open.
 * The handle may only be closed once.
 *
 * The database handle will be private to the current transaction until
 * the transaction is successfully committed. If the transaction is
 * aborted the handle will be closed automatically.
 * After a successful commit the handle will reside in the shared
 * environment, and may be used by other transactions.
 *
 * This function must not be called from multiple concurrent
 * transactions in the same process. A transaction that uses
 * this function must finish (either commit or abort) before
 * any other transaction in the process may use this function.
 *
 * To use named databases (with name != NULL), #mdb_env_set_maxdbs()
 * must be called before opening the environment.  Database names are
 * keys in the unnamed database, and may be read but not written.
 *
 * @param[in] txn A transaction handle returned by #mdb_txn_begin()
 * @param[in] name The name of the database to open. If only a single
 * 	database is needed in the environment, this value may be NULL.
 * @param[in] flags Special options for this database. This parameter
 * must be set to 0 or by bitwise OR'ing together one or more of the
 * values described here.
 * <ul>
 *	<li>#MDB_REVERSEKEY
 *		Keys are strings to be compared in reverse order, from the end
 *		of the strings to the beginning. By default, Keys are treated as strings and
 *		compared from beginning to end.
 *	<li>#MDB_DUPSORT
 *		Duplicate keys may be used in the database. (Or, from another perspective,
 *		keys may have multiple data items, stored in sorted order.) By default
 *		keys must be unique and may have only a single data item.
 *	<li>#MDB_INTEGERKEY
 *		Keys are binary integers in native byte order, either unsigned int
 *		or size_t, and will be sorted as such.
 *		The keys must all be of the same size.
 *	<li>#MDB_DUPFIXED
 *		This flag may only be used in combination with #MDB_DUPSORT. This option
 *		tells the library that the data items for this database are all the same
 *		size, which allows further optimizations in storage and retrieval. When
 *		all data items are the same size, the #MDB_GET_MULTIPLE and #MDB_NEXT_MULTIPLE
 *		cursor operations may be used to retrieve multiple items at once.
 *	<li>#MDB_INTEGERDUP
 *		This option specifies that duplicate data items are binary integers,
 *		similar to #MDB_INTEGERKEY keys.
 *	<li>#MDB_REVERSEDUP
 *		This option specifies that duplicate data items should be compared as
 *		strings in reverse order.
 *	<li>#MDB_CREATE
 *		Create the named database if it doesn't exist. This option is not
 *		allowed in a read-only transaction or a read-only environment.
 * </ul>
 * @param[out] dbi Address where the new #MDB_dbi handle will be stored
 * @return A non-zero error value on failure and 0 on success. Some possible
 * errors are:
 * <ul>
 *	<li>#MDB_NOTFOUND - the specified database doesn't exist in the environment
 *		and #MDB_CREATE was not specified.
 *	<li>#MDB_DBS_FULL - too many databases have been opened. See #mdb_env_set_maxdbs().
 * </ul>
 */
//int  mdb_dbi_open(MDB_txn *txn, const char *name, unsigned int flags, MDB_dbi *dbi);

/* @brief Retrieve statistics for a database.
 *
 * @param[in] txn A transaction handle returned by #mdb_txn_begin()
 * @param[in] dbi A database handle returned by #mdb_dbi_open()
 * @param[out] stat The address of an #MDB_stat structure
 * 	where the statistics will be copied
 * @return A non-zero error value on failure and 0 on success. Some possible
 * errors are:
 * <ul>
 *	<li>EINVAL - an invalid parameter was specified.
 * </ul>
 */
int  mdb_stat(MDB_txn *txn, MDB_dbi dbi, MDB_stat *stat);

/* @brief Retrieve the DB flags for a database handle.
 *
 * @param[in] txn A transaction handle returned by #mdb_txn_begin()
 * @param[in] dbi A database handle returned by #mdb_dbi_open()
 * @param[out] flags Address where the flags will be returned.
 * @return A non-zero error value on failure and 0 on success.
 */
int mdb_dbi_flags(MDB_txn *txn, MDB_dbi dbi, unsigned int *flags);

/* @brief Close a database handle. Normally unnecessary. Use with care:
 *
 * This call is not mutex protected. Handles should only be closed by
 * a single thread, and only if no other threads are going to reference
 * the database handle or one of its cursors any further. Do not close
 * a handle if an existing transaction has modified its database.
 * Doing so can cause misbehavior from database corruption to errors
 * like MDB_BAD_VALSIZE (since the DB name is gone).
 *
 * Closing a database handle is not necessary, but lets #mdb_dbi_open()
 * reuse the handle value.  Usually it's better to set a bigger
 * #mdb_env_set_maxdbs(), unless that value would be large.
 *
 * @param[in] env An environment handle returned by #mdb_env_create()
 * @param[in] dbi A database handle returned by #mdb_dbi_open()
 */
void mdb_dbi_close(MDB_env *env, MDB_dbi dbi);

/* @brief Empty or delete+close a database.
 *
 * See #mdb_dbi_close() for restrictions about closing the DB handle.
 * @param[in] txn A transaction handle returned by #mdb_txn_begin()
 * @param[in] dbi A database handle returned by #mdb_dbi_open()
 * @param[in] del 0 to empty the DB, 1 to delete it from the
 * environment and close the DB handle.
 * @return A non-zero error value on failure and 0 on success.
 */
int  mdb_drop(MDB_txn *txn, MDB_dbi dbi, int del);

/* @brief Set a custom key comparison function for a database.
 *
 * The comparison function is called whenever it is necessary to compare a
 * key specified by the application with a key currently stored in the database.
 * If no comparison function is specified, and no special key flags were specified
 * with #mdb_dbi_open(), the keys are compared lexically, with shorter keys collating
 * before longer keys.
 * @warning This function must be called before any data access functions are used,
 * otherwise data corruption may occur. The same comparison function must be used by every
 * program accessing the database, every time the database is used.
 * @param[in] txn A transaction handle returned by #mdb_txn_begin()
 * @param[in] dbi A database handle returned by #mdb_dbi_open()
 * @param[in] cmp A #MDB_cmp_func function
 * @return A non-zero error value on failure and 0 on success. Some possible
 * errors are:
 * <ul>
 *	<li>EINVAL - an invalid parameter was specified.
 * </ul>
 */
int  mdb_set_compare(MDB_txn *txn, MDB_dbi dbi, MDB_cmp_func *cmp);

/* @brief Set a custom data comparison function for a #MDB_DUPSORT database.
 *
 * This comparison function is called whenever it is necessary to compare a data
 * item specified by the application with a data item currently stored in the database.
 * This function only takes effect if the database was opened with the #MDB_DUPSORT
 * flag.
 * If no comparison function is specified, and no special key flags were specified
 * with #mdb_dbi_open(), the data items are compared lexically, with shorter items collating
 * before longer items.
 * @warning This function must be called before any data access functions are used,
 * otherwise data corruption may occur. The same comparison function must be used by every
 * program accessing the database, every time the database is used.
 * @param[in] txn A transaction handle returned by #mdb_txn_begin()
 * @param[in] dbi A database handle returned by #mdb_dbi_open()
 * @param[in] cmp A #MDB_cmp_func function
 * @return A non-zero error value on failure and 0 on success. Some possible
 * errors are:
 * <ul>
 *	<li>EINVAL - an invalid parameter was specified.
 * </ul>
 */
int  mdb_set_dupsort(MDB_txn *txn, MDB_dbi dbi, MDB_cmp_func *cmp);

/* @brief Set a relocation function for a #MDB_FIXEDMAP database.
 *
 * @todo The relocation function is called whenever it is necessary to move the data
 * of an item to a different position in the database (e.g. through tree
 * balancing operations, shifts as a result of adds or deletes, etc.). It is
 * intended to allow address/position-dependent data items to be stored in
 * a database in an environment opened with the #MDB_FIXEDMAP option.
 * Currently the relocation feature is unimplemented and setting
 * this function has no effect.
 * @param[in] txn A transaction handle returned by #mdb_txn_begin()
 * @param[in] dbi A database handle returned by #mdb_dbi_open()
 * @param[in] rel A #MDB_rel_func function
 * @return A non-zero error value on failure and 0 on success. Some possible
 * errors are:
 * <ul>
 *	<li>EINVAL - an invalid parameter was specified.
 * </ul>
 */
int  mdb_set_relfunc(MDB_txn *txn, MDB_dbi dbi, MDB_rel_func *rel);

/* @brief Set a context pointer for a #MDB_FIXEDMAP database's relocation function.
 *
 * See #mdb_set_relfunc and #MDB_rel_func for more details.
 * @param[in] txn A transaction handle returned by #mdb_txn_begin()
 * @param[in] dbi A database handle returned by #mdb_dbi_open()
 * @param[in] ctx An arbitrary pointer for whatever the application needs.
 * It will be passed to the callback function set by #mdb_set_relfunc
 * as its \b relctx parameter whenever the callback is invoked.
 * @return A non-zero error value on failure and 0 on success. Some possible
 * errors are:
 * <ul>
 *	<li>EINVAL - an invalid parameter was specified.
 * </ul>
 */
int  mdb_set_relctx(MDB_txn *txn, MDB_dbi dbi, void *ctx);

/* @brief Get items from a database.
 *
 * This function retrieves key/data pairs from the database. The address
 * and length of the data associated with the specified \b key are returned
 * in the structure to which \b data refers.
 * If the database supports duplicate keys (#MDB_DUPSORT) then the
 * first data item for the key will be returned. Retrieval of other
 * items requires the use of #mdb_cursor_get().
 *
 * @note The memory pointed to by the returned values is owned by the
 * database. The caller need not dispose of the memory, and may not
 * modify it in any way. For values returned in a read-only transaction
 * any modification attempts will cause a SIGSEGV.
 * @note Values returned from the database are valid only until a
 * subsequent update operation, or the end of the transaction.
 * @param[in] txn A transaction handle returned by #mdb_txn_begin()
 * @param[in] dbi A database handle returned by #mdb_dbi_open()
 * @param[in] key The key to search for in the database
 * @param[out] data The data corresponding to the key
 * @return A non-zero error value on failure and 0 on success. Some possible
 * errors are:
 * <ul>
 *	<li>#MDB_NOTFOUND - the key was not in the database.
 *	<li>EINVAL - an invalid parameter was specified.
 * </ul>
 */
int  mdb_get(MDB_txn *txn, MDB_dbi dbi, MDB_val *key, MDB_val *data);

/* @brief Store items into a database.
 *
 * This function stores key/data pairs in the database. The default behavior
 * is to enter the new key/data pair, replacing any previously existing key
 * if duplicates are disallowed, or adding a duplicate data item if
 * duplicates are allowed (#MDB_DUPSORT).
 * @param[in] txn A transaction handle returned by #mdb_txn_begin()
 * @param[in] dbi A database handle returned by #mdb_dbi_open()
 * @param[in] key The key to store in the database
 * @param[in,out] data The data to store
 * @param[in] flags Special options for this operation. This parameter
 * must be set to 0 or by bitwise OR'ing together one or more of the
 * values described here.
 * <ul>
 *	<li>#MDB_NODUPDATA - enter the new key/data pair only if it does not
 *		already appear in the database. This flag may only be specified
 *		if the database was opened with #MDB_DUPSORT. The function will
 *		return #MDB_KEYEXIST if the key/data pair already appears in the
 *		database.
 *	<li>#MDB_NOOVERWRITE - enter the new key/data pair only if the key
 *		does not already appear in the database. The function will return
 *		#MDB_KEYEXIST if the key already appears in the database, even if
 *		the database supports duplicates (#MDB_DUPSORT). The \b data
 *		parameter will be set to point to the existing item.
 *	<li>#MDB_RESERVE - reserve space for data of the given size, but
 *		don't copy the given data. Instead, return a pointer to the
 *		reserved space, which the caller can fill in later - before
 *		the next update operation or the transaction ends. This saves
 *		an extra memcpy if the data is being generated later.
 *		LMDB does nothing else with this memory, the caller is expected
 *		to modify all of the space requested. This flag must not be
 *		specified if the database was opened with #MDB_DUPSORT.
 *	<li>#MDB_APPEND - append the given key/data pair to the end of the
 *		database. This option allows fast bulk loading when keys are
 *		already known to be in the correct order. Loading unsorted keys
 *		with this flag will cause a #MDB_KEYEXIST error.
 *	<li>#MDB_APPENDDUP - as above, but for sorted dup data.
 * </ul>
 * @return A non-zero error value on failure and 0 on success. Some possible
 * errors are:
 * <ul>
 *	<li>#MDB_MAP_FULL - the database is full, see #mdb_env_set_mapsize().
 *	<li>#MDB_TXN_FULL - the transaction has too many dirty pages.
 *	<li>EACCES - an attempt was made to write in a read-only transaction.
 *	<li>EINVAL - an invalid parameter was specified.
 * </ul>
 */
int  mdb_put(MDB_txn *txn, MDB_dbi dbi, MDB_val *key, MDB_val *data,
			    unsigned int flags);

/* @brief Delete items from a database.
 *
 * This function removes key/data pairs from the database.
 * If the database does not support sorted duplicate data items
 * (#MDB_DUPSORT) the data parameter is ignored.
 * If the database supports sorted duplicates and the data parameter
 * is NULL, all of the duplicate data items for the key will be
 * deleted. Otherwise, if the data parameter is non-NULL
 * only the matching data item will be deleted.
 * This function will return #MDB_NOTFOUND if the specified key/data
 * pair is not in the database.
 * @param[in] txn A transaction handle returned by #mdb_txn_begin()
 * @param[in] dbi A database handle returned by #mdb_dbi_open()
 * @param[in] key The key to delete from the database
 * @param[in] data The data to delete
 * @return A non-zero error value on failure and 0 on success. Some possible
 * errors are:
 * <ul>
 *	<li>EACCES - an attempt was made to write in a read-only transaction.
 *	<li>EINVAL - an invalid parameter was specified.
 * </ul>
 */
int  mdb_del(MDB_txn *txn, MDB_dbi dbi, MDB_val *key, MDB_val *data);

/* @brief Create a cursor handle.
 *
 * A cursor is associated with a specific transaction and database.
 * A cursor cannot be used when its database handle is closed.  Nor
 * when its transaction has ended, except with #mdb_cursor_renew().
 * It can be discarded with #mdb_cursor_close().
 * A cursor in a write-transaction can be closed before its transaction
 * ends, and will otherwise be closed when its transaction ends.
 * A cursor in a read-only transaction must be closed explicitly, before
 * or after its transaction ends. It can be reused with
 * #mdb_cursor_renew() before finally closing it.
 * @note Earlier documentation said that cursors in every transaction
 * were closed when the transaction committed or aborted.
 * @param[in] txn A transaction handle returned by #mdb_txn_begin()
 * @param[in] dbi A database handle returned by #mdb_dbi_open()
 * @param[out] cursor Address where the new #MDB_cursor handle will be stored
 * @return A non-zero error value on failure and 0 on success. Some possible
 * errors are:
 * <ul>
 *	<li>EINVAL - an invalid parameter was specified.
 * </ul>
 */
int  mdb_cursor_open(MDB_txn *txn, MDB_dbi dbi, MDB_cursor **cursor);

/* @brief Close a cursor handle.
 *
 * The cursor handle will be freed and must not be used again after this call.
 * Its transaction must still be live if it is a write-transaction.
 * @param[in] cursor A cursor handle returned by #mdb_cursor_open()
 */
void mdb_cursor_close(MDB_cursor *cursor);

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
 */
int  mdb_cursor_renew(MDB_txn *txn, MDB_cursor *cursor);

/* @brief Return the cursor's transaction handle.
 *
 * @param[in] cursor A cursor handle returned by #mdb_cursor_open()
 */
MDB_txn *mdb_cursor_txn(MDB_cursor *cursor);

/* @brief Return the cursor's database handle.
 *
 * @param[in] cursor A cursor handle returned by #mdb_cursor_open()
 */
//MDB_dbi mdb_cursor_dbi(MDB_cursor *cursor);

/* @brief Retrieve by cursor.
 *
 * This function retrieves key/data pairs from the database. The address and length
 * of the key are returned in the object to which \b key refers (except for the
 * case of the #MDB_SET option, in which the \b key object is unchanged), and
 * the address and length of the data are returned in the object to which \b data
 * refers.
 * See #mdb_get() for restrictions on using the output values.
 * @param[in] cursor A cursor handle returned by #mdb_cursor_open()
 * @param[in,out] key The key for a retrieved item
 * @param[in,out] data The data of a retrieved item
 * @param[in] op A cursor operation #MDB_cursor_op
 * @return A non-zero error value on failure and 0 on success. Some possible
 * errors are:
 * <ul>
 *	<li>#MDB_NOTFOUND - no matching key found.
 *	<li>EINVAL - an invalid parameter was specified.
 * </ul>
 */
//int  mdb_cursor_get(MDB_cursor *cursor, MDB_val *key, MDB_val *data, MDB_cursor_op op);
			    
/* @brief Store by cursor.
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
 * @return A non-zero error value on failure and 0 on success. Some possible
 * errors are:
 * <ul>
 *	<li>#MDB_MAP_FULL - the database is full, see #mdb_env_set_mapsize().
 *	<li>#MDB_TXN_FULL - the transaction has too many dirty pages.
 *	<li>EACCES - an attempt was made to write in a read-only transaction.
 *	<li>EINVAL - an invalid parameter was specified.
 * </ul>
 */
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

/* @brief Compare two data items according to a particular database.
 *
 * This returns a comparison as if the two data items were keys in the
 * specified database.
 * @param[in] txn A transaction handle returned by #mdb_txn_begin()
 * @param[in] dbi A database handle returned by #mdb_dbi_open()
 * @param[in] a The first item to compare
 * @param[in] b The second item to compare
 * @return < 0 if a < b, 0 if a == b, > 0 if a > b
 */
//int  mdb_cmp(MDB_txn *txn, MDB_dbi dbi, const MDB_val *a, const MDB_val *b);

/* @brief Compare two data items according to a particular database.
 *
 * This returns a comparison as if the two items were data items of
 * the specified database. The database must have the #MDB_DUPSORT flag.
 * @param[in] txn A transaction handle returned by #mdb_txn_begin()
 * @param[in] dbi A database handle returned by #mdb_dbi_open()
 * @param[in] a The first item to compare
 * @param[in] b The second item to compare
 * @return < 0 if a < b, 0 if a == b, > 0 if a > b
 */
int  mdb_dcmp(MDB_txn *txn, MDB_dbi dbi, const MDB_val *a, const MDB_val *b);

/* @brief A callback function used to print a message from the library.
 *
 * @param[in] msg The string to be printed.
 * @param[in] ctx An arbitrary context pointer for the callback.
 * @return < 0 on failure, >= 0 on success.
 */
typedef int (MDB_msg_func)(const char *msg, void *ctx);

/* @brief Dump the entries in the reader lock table.
 *
 * @param[in] env An environment handle returned by #mdb_env_create()
 * @param[in] func A #MDB_msg_func function
 * @param[in] ctx Anything the message function needs
 * @return < 0 on failure, >= 0 on success.
 */
int	mdb_reader_list(MDB_env *env, MDB_msg_func *func, void *ctx);

/* @brief Check for stale entries in the reader lock table.
 *
 * @param[in] env An environment handle returned by #mdb_env_create()
 * @param[out] dead Number of stale slots that were cleared
 * @return 0 on success, non-zero on failure.
 */
int	mdb_reader_check(MDB_env *env, int *dead);
/**	@} */

/** @page tools LMDB Command Line Tools
	The following describes the command line tools that are available for LMDB.
	\li \ref mdb_copy_1
	\li \ref mdb_dump_1
	\li \ref mdb_load_1
	\li \ref mdb_stat_1
*/
