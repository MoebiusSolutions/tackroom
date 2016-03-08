// Library major version 0.9.70
// The release date of this library version "December 19, 2015"

use "lib:lmdb"  // Link against the lmdb library.

// A whole lot of FFI calls

use @mdb_strerror[Pointer[U8]]( err: Stat )
use @mdb_env_create[Stat]( env: Pointer[Pointer[U8]] )
use @mdb_version[None]( major: Pointer[Stat], minor: Pointer[Stat], patch: Pointer[Stat] )
use @mdb_env_stat[None]( mdb: Pointer[MDBenv],
	stat: Pointer[Pointer[MDBstat]] )
use @mdb_env_open[Stat]( env: Pointer[U8] tag,
    path: Pointer[U8], flags: USize, mode: USize )
use @mdb_env_copy[Stat]( env: Pointer[MDBenv], path: Pointer[U8] )
use @mdb_env_copy2[Stat]( env: Pointer[MDBenv], path: Pointer[U8], flags: FlagMask )
use @mdb_env_stat[None]( env: Pointer[U8], stat: Pointer[U8] )
use @mdb_env_info[Stat]( env: Pointer[MDBenv] tag, stat: Pointer[MDBinfo] )
use @mdb_env_sync[Stat]( env: Pointer[MDBenv], force: FlagMask )
use @mdb_env_close[None]( env: Pointer[MDBenv] )
use @mdb_env_set_flags[Stat]( env: Pointer[MDBenv], flags: FlagMask, onoff: U32)
use @mdb_env_get_flags[Stat]( env: Pointer[MDBenv], flags: Pointer[FlagMask] )
use @mdb_env_get_path[Stat]( env: Pointer[MDBenv], path: Pointer[Pointer[U8]] )
use @mdb_env_set_mapsize[Stat]( env:Pointer[MDBenv], size: USize )
use @mdb_env_set_maxreaders[Stat]( env: Pointer[MDBenv], count: U32 )
use @mdb_env_get_maxreaders[Stat]( env: Pointer[MDBenv] )
use @mdb_env_set_maxdbs[Stat]( env: Pointer[MDBenv], count: U32 )
use @mdb_env_get_maxkeysize[Stat]( enc: Pointer[MDBenv] )
use @mdb_env_set_userctx[Stat]( env: Pointer[MDBenv], ctx: Pointer[Any] )
use @mdb_env_get_userctx[ Pointer[Any] ]( env: Pointer[MDBenv] )
use @mdb_txn_begin[Stat]( env: Pointer[MDBenv],
    parent: Pointer[MDBenv], flags: FlagMask, txn: Pointer[Pointer[MDBtxn]] )

type Stat is I32
type FlagMask is U32

// Opaque structures for actual LMDB handles.
primitive MDBenv  // The overall LMDB Environment
primitive MDBtxn  // A transaction within the environment
primitive MDBdbi  // A database within the environment
primitive MDBcur  // A cursor for sequential operations

//  Flags on creating an environment
primitive MDBenvflag
  fun fixedmap(): FlagMask => 0x01   // mmap at a fixed address (experimental)
  fun nosubdir(): FlagMask => 0x400  // no environment directory
  fun nosync(): FlagMask => 0x10000  // don't fsync after commit
  fun rdonly(): FlagMask => 0x20000  
  fun nometasync(): FlagMask => 0x40000  // don't fsync metapage after commit
  fun writemap(): FlagMask => 0x80000  // use writable mmap
  fun mapasync(): FlagMask => 0x100000 // use asynchronous msync when WRITEMAP is used
  fun notls(): FlagMask => 0x200000    // tie reader locktable slots to txn
		// objects instead of to threads
  fun nolock(): FlagMask => 0x400000   // don't do any locking,
	  // caller must manage their own locks */
  fun nordahead(): FlagMask => 0x800000 // don't do readahead (no effect on Windows)
  fun nomeminit(): FlagMask => 0x1000000 // don't initialize malloc'd memory before writing to datafile

// Flags on copy operations
primitive MDBcopyflag
  fun compact(): FlagMask => 0x01  // Omit free space from copy, and renumber all
	                 // pages sequentially.

// Environment statistics
class MDBstat
  """
  Some interesting statistics about the Environment or Database.
  """
  var psize: USize = 0    // Page size
  var depth: USize = 0    // Deepest B-tree
  var bpages: USize = 0   // Non-leaf page count
  var lpages: USize = 0   // Leaf page count
  var opages: USize = 0   // Overflow page count
  var entries: USize = 0  // Total record count
  new create() => None

// Environment info
class MDBinfo
  """
  Information specific to the Environment
  """
  var mapaddr: Pointer[U8] = Pointer[U8]() // Address of map, if fixed
  var mapsize: USize = 0     // Size of mapped area
  var last_pgno: USize = 0   // ID of last used page
  var last_txid: USize = 0   // ID of last commited transaction
  var maxreaders: USize = 0  // Max reader slots
  var numreaders: USize = 0  // Number of used slots
  new create() => None

class MDBVersion
  """
  LMDB software version number.
  """
  var major: USize = 0
  var minor: USize = 0
  var patch: USize = 0
  new create() =>
    @mdb_version( addressof major, addressof minor, addressof patch )

class MDBEnvironment
  """
  The LMDB Environment consists of a single (large) region of virtual memory
  that is mapped to a file.   All LMDB operations take place within
  this Environment.
  """
  var _mdbenv: Pointer[MDBenv]
  let _notifier: MDBNotify

  new create( note: (MDBNotify | None) = None ) =>
    """
    Create a new MDBEnvironment context.  This does not open any files
    yet;  that happens in open().
    """
    // The Notifier is optional.  If none is supplied, we create a dummy.
    _notifier = (match note
        | None => MDBNotify.create()
        | let n: MDBNotify => n
        end)
    let err = @mdb_env_create( addressof _mdbenv )
    report_error( err )

  fun ref open( path: String, flags: FlagMask, mode: U32 ) =>
    """
    Open the environment, associating it with a backing file.  This
    will contain one or more "databases".
    """
    let err = @mdb_env_open( _mdbenv, path.cstring(), flags, mode )
    report_error( err )
 
  fun ref copy( path: String, flags: FlagMask = 0 ) =>
    """
    Make a copy of the entire environment.  This can be used to
    create backups.
    """
    let err = if flags == 0 then
      @mdb_env_copy( _mdbenv, path.cstring() )
    else
      @mdb_env_copy( _mdbenv, path.cstring(), flags )
    end
    report_error( err )

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
    """
    Insure that the underlying file is up to date.
    """
    report_error( @mdb_env_sync( _mdbenv, force ))

  fun ref close() =>
    @mdb_env_close( _mdbenv )

  fun ref set_flags( flags: FlagMask, set: Bool ) =>
    """
    Set or clear environment flags after it has been created.
    """
    if set then
      @mdb_env_set_flags( _mdbenv, flags, 1 )
    else
      @mdb_env_set_flags( _mdbenv, flags, 0 )
    end

  fun ref get_flags(): USize =>
    """
    Get current Environment flags
    """
    var flags: USize = 0
    report_error( @mdb_env_get_flags( _mdbenv, addressof flags ))
    flags

  fun ref get_path(): String =>
    """
    Get the file system path where the environment is stored.
    """
    var sptr: Pointer[U8] = Pointer[U8]()
    report_error( @mdb_env_get_path( _mdbenv, addressof sptr ))
    // We have to copy the string because it is in the mapped area.
    String.copy_cstring( sptr )

  fun ref set_mapsize( size: USize ) =>
    """
    Set the size of the memory map to use for this environment.
    The size should be a multiple of the OS page size. The default is
    10,485,760 bytes (2560 pages). The size of the memory map is also
    the maximum size of the database. The value should be chosen as
    large as possible, to accommodate future growth of the database.
    This function should be called after create and before open.
    """
    report_error( @mdb_env_set_mapsize( _mdbenv, size ))

  fun ref set_maxslots( count: U32 ) =>
    """
    Set the maximum number of threads/reader slots for the environment.
    This defines the number of slots in the lock table that is used to
    track readers in the the environment. The default is 126.
    Starting a read-only transaction normally ties a lock table slot to the
    current thread until the environment closes or the thread exits. If
    NOTLS is in use, env.begin() instead ties the slot to the
    MDBtxn object until it or the MDBenv object is destroyed.
    This function may only be called after create() and before open().
    """
    report_error( @mdb_env_set_maxreaders( _mdbenv, count ))

  fun ref slots() =>
    """
    Get the maximum number of threads/reader slots for the environment.
    """
    var count: USize = 0
    report_error( @mdb_env_get_maxreaders( _mdbenv, addressof count ))
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
    report_error( @mdb_env_set_maxdbs( _mdbenv, count ))

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
    report_error( @mdb_env_set_userctx( _mdbenv, infop ))

  fun ref get_appinfo(): Pointer[Any] =>
    """
    Get the application information associated with the #MDBenv.
    """
    @mdb_env_get_userctx( _mdbenv )

  fun ref begin( flags: FlagMask,
    parent: (MDBTransaction | None) = None ): MDBTransaction =>
    """
    Start a transaction within this environment.
    """
    var txnhdl: MDBtxn = 0
    let err = match parent
      | None =>
	  @mdb_txn_begin( _mdbenv, Pointer[U8](), flags, addressof txnhdl )
      | let p: MDBTransaction =>
          @mdb_txn_begin( _mdbenv, parent.handle(), flags, addressof txnhdl )
      else USize(0) end
    report_error( err )
	
    MDBTransaction.create( this, txnhdl )

  fun ref report_error( code: Stat ) =>
    if code == 0 then return end		
    let msg = String.from_cstring( @mdb_errstr( code ) )
    _notifier.fail( this, code, consume msg )
 
  fun ref getenv(): Pointer[MDBenv] =>
    _mdbenv
		
