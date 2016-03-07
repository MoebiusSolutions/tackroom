// Library major version 0.9.70
// The release date of this library version "December 19, 2015"

use "lib:lmdb"
use @mdb_strerror[Pointer[U8]]( err: USize )
use @mdb_env_create[USize]( env: Pointer[Pointer[U8]] )
use @mdb_version[None]( major: Pointer[USize], minor: Pointer[USize], patch: Pointer[USize] )
use @mdb_env_stat[None]( mdb: Pointer[MDBenv],
	stat: Pointer[Pointer[MDBstat]] )
use @mdb_env_open[USize]( env: Pointer[U8] tag,
    path: Pointer[U8], flags: USize, mode: USize )
use @mdb_env_copy[USize]( env: Pointer[MDBenv], path: Pointer[U8] )
use @mdb_env_copy2[USize]( env: Pointer[MDBenv], path: Pointer[U8], flags: USize )
use @mdb_env_stat[None]( env: Pointer[U8], stat: Pointer[U8] )
use @mdb_env_info[USize]( env: Pointer[MDBenv] tag,
    stat: Pointer[MDBinfo] )
use @mdb_env_sync[USize]( env: Pointer[MDBenv], force: USize )
use @mdb_env_close[None]( env: Pointer[MDBenv] )
use @mdb_env_set_flags[USize]( env: Pointer[MDBenv], flags: USize, onoff: USize)
use @mdb_env_get_flags[USize]( env: Pointer[MDBenv], flags: Pointer[USize] )
use @mdb_env_get_path[USize]( env: Pointer[MDBenv], path: Pointer[Pointer[U8]] )
use @mdb_env_set_mapsize[USize]( env:Pointer[MDBenv], size: USize )
use @mdb_env_set_maxreaders[USize]( env: Pointer[MDBenv], count: USize )
use @mdb_env_get_maxreaders[USize]( env: Pointer[MDBenv] )
use @mdb_env_set_maxdbs[USize]( env: Pointer[MDBenv], count: USize )
use @mdb_env_get_maxkeysize[USize]( enc: Pointer[MDBenv] )
use @mdb_env_set_userctx[USize]( env: Pointer[MDBenv], ctx: Pointer[Any] )
use @mdb_env_get_userctx[ Pointer[Any] ]( env: Pointer[MDBenv] )

// Opaque structures for actual LMDB handles.
primitive MDBenv  // The overall LMDB Environment
primitive MDBtxn  // A transaction within the environment
primitive MDBdbi  // A database within the environment
primitive MDBcur  // A cursor for sequential operations

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
class MDBval
  var size: USize = 0
  var data: Pointer[U8]
  new apply( data': Pointer[U8], size': USize ) =>
    size = size'
    data = data'
  new create() => None
  new from_string( s: String ) =>
    size = s.size()
    data = s.cstring()
  fun ref string(): String =>
    String.from_cstring( data, size )	  
	  
//  Flags on creating an environment
primitive MDBenvflag
  fun fixedmap() => 0x01   // mmap at a fixed address (experimental)
  fun nosubdir() => 0x400  // no environment directory
  fun nosync() => 0x10000  // don't fsync after commit
  fun rdonly() => 0x20000  
  fun nometasync() => 0x40000  // don't fsync metapage after commit
  fun writemap() => 0x80000  // use writable mmap
  fun mapasync() => 0x100000 // use asynchronous msync when WRITEMAP is used
  fun notls() => 0x200000    // tie reader locktable slots to txn
		// objects instead of to threads
  fun nolock() => 0x400000   // don't do any locking,
	  // caller must manage their own locks */
  fun nordahead() => 0x800000 // don't do readahead (no effect on Windows)
  fun nomeminit() => 0x1000000 // don't initialize malloc'd memory before writing to datafile

// Flags on copy operations
primitive MDBcopyflag
  fun compact() => 0x01  // Omit free space from copy, and renumber all
	                 // pages sequentially.

// Op-codes for cursor operations.			 
primitive MDBcursorop
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
  fun next_multiple(): USize => 10
  fun next_nodup(): USize => 11
  fun prev(): USize => 12
  fun prev_dup(): USize => 13
  fun set(): USize => 14
  fun set_key(): USize => 15
  fun set_range(): USize => 16
  fun prev_multiple(): USize => 17

// Environment statistics
class MDBstat
  var psize: USize = 0
  var depth: USize = 0
  var bpages: USize = 0
  var lpages: USize = 0
  var opages: USize = 0
  var entries: USize = 0
  new create() => None

// Environment info
class MDBinfo
  var mapaddr: Pointer[U8] = Pointer[U8]() // Address of map, if fixed
  var mapsize: USize = 0     // Size of mapped area
  var last_pgno: USize = 0   // ID of last used page
  var last_txid: USize = 0   // ID of last commited transaction
  var maxreaders: USize = 0  // Max reader slots
  var numreaders: USize = 0  // Number of used slots
  new create() => None

// Get LMDB version
class MDBVersion
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
  that is mapped to a file.   All LMDB operations take place within
  this Environment.
  """
  var _mdbenv: Pointer[MDBenv]

  new create() =>
    let errcode = @mdb_env_create( addressof _mdbenv )

  fun ref open( path: String, flags: USize, mode: USize ) =>
    """
    Open the environment.  This corresponds to a single mapped file which
    can contain one or more "databases".
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
// int  mdb_env_copyfd(MDBenv *env, mdb_filehandle_t fd);

// int  mdb_env_copy2(MDBenv *env, const char *path, unsigned int flags);

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
// int  mdb_env_copyfd2(MDBenv *env, mdb_filehandle_t fd, unsigned int flags);

  fun ref info(): MDBinfo =>
    let infop: MDBinfo = MDBinfo.create()
    @mdb_env_info( _mdbenv, addressof infop )
    infop

  fun ref stats(): MDBstat =>
    """
    Return statistics about the environment
    """
    let statp: MDBstat = MDBstat.create()
    @mdb_env_stat( _mdbenv, addressof statp )
    statp

  fun ref flush( force: Bool = false ) =>
    let err = @mdb_env_sync( _mdbenv, force )

  fun ref close() =>
    @mdb_env_close( _mdbenv )

  fun ref set_flags( flags: USize, set: Bool ) =>
    """
    Set or clear environment flags after it has been created.
    """
    if set then
      @mdb_env_set_flags( _mdbenv, flags, 1 )
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
    10,485,760 bytes. The size of the memory map is also the maximum size
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
    MDBtxn object until it or the #MDBenv object is destroyed.
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
    Get the maximum size of keys and DUPSORT data we can write.
    This depends on the compile-time constant #MDB_MAXKEYSIZE. Default 511.
    """
    @mdb_env_get_maxkeysize( _mdbenv )

  fun ref set_appinfo( infop: Pointer[Any] ) =>
    """
    Set application information associated with the Environment.
    """
    let err = @mdb_env_set_userctx( _mdbenv, infop )

  fun ref get_appinfo(): Pointer[Any] =>
    """
    Get the application information associated with the #MDBenv.
    """
    @mdb_env_get_userctx( _mdbenv )

  fun ref begin( flags: USize,
    parent: (MDBTransaction | None) = None ): MDBTransaction =>
    """
    Start a transaction within this environment.
    """
    var txnhdl: MDBtxn = 0
    let err = (match parent
      | None =>
	  @mdb_txn_begin( _mdbenv, Pointer[U8](), flags, addressof txnhdl )
      | let p: MDBTransaction =>
          @mdb_txn_begin( _mdbenv, parent.handle(), flags, addressof txnhdl )
    end)
	
    MDBTransaction.create( this, txnhdl )
