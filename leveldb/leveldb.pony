/* Pony interface to the LevelDB key-value database from Google.

Currently this uses the "C" binding to LevelDB, which does not support
the following:
  . getters for the option types
  . custom comparators that implement key shortening
  . custom iter, db, env, cache implementations using just the C bindings
*/

/*
  Errors are represented by a null-terminated c string.  NULL
  means no error.  All operations that can raise an error are passed
  a "char** errptr" as the last argument.  One of the following must
  be true on entry:
     *errptr == NULL
     *errptr points to a malloc()ed null-terminated error message
       (On Windows, *errptr must have been malloc()-ed by this library.)
  On success, a leveldb routine leaves *errptr unchanged.
  On failure, leveldb frees the old value of *errptr and
  set *errptr to a malloc()ed error message.

  Bools have the type unsigned char (0 == false; rest == true)

  All of the pointer arguments must be non-NULL.
*/
  
// LevelDB is available from https://github.com/google/leveldb.git
use "lib:leveldb"

// First we translate the LevelDB C API calls into Pony FFIs.
// These came from include/c.h in the LevelDB source files.
use @leveldb_open[Pointer[U8] tag]( ropts: Pointer[U8] tag,
    name: Pointer[U8] tag,
    errptr: Pointer[Pointer[U8]] )
use @leveldb_close[None]( db: Pointer[U8] tag )
use @leveldb_put[None]( db: Pointer[U8] tag,
    wopts: Pointer[U8],
    key: Pointer[U8] tag, keylen: USize,
    value: Pointer[U8] tag, valuelen: USize,
    errptr: Pointer[Pointer[U8]] )
use @leveldb_delete[None]( db: Pointer[U8] tag,
    wopts: Pointer[U8],
    key: Pointer[U8] tag, keylen: USize,
    errptr: Pointer[Pointer[U8]] )

/* extern void leveldb_write(
    leveldb_t* db,
    const leveldb_writeoptions_t* options,
    leveldb_writebatch_t* batch,
    char** errptr); */
use @leveldb_write[None]( db: Pointer[U8],
    opts: Pointer[U8], batch: Pointer[U8], errptr: Pointer[U8] )

/* Returns NULL if not found.  A malloc()ed array otherwise.
   Stores the length of the array in *vallen. */
use @leveldb_get[Pointer[U8]]( db: Pointer[U8] tag,
   ropts: Pointer[U8],
   key: Pointer[U8] tag, keylen: USize,
   valuelen: Pointer[USize],
   errptr: Pointer[Pointer[U8]] )

/* extern leveldb_iterator_t* leveldb_create_iterator(
    leveldb_t* db,
    const leveldb_readoptions_t* options); */
use @leveldb_create_iterator[Pointer[U8]]( db: Pointer[U8],
   ropts: Pointer[U8] )
      
/* extern const leveldb_snapshot_t* leveldb_create_snapshot(
    leveldb_t* db); */

/* extern void leveldb_release_snapshot(
    leveldb_t* db,
    const leveldb_snapshot_t* snapshot); */

/* Returns NULL if property name is unknown.
   Else returns a pointer to a malloc()-ed null-terminated value. */
/* extern char* leveldb_property_value(
    leveldb_t* db,
    const char* propname); */

/* extern void leveldb_approximate_sizes(
    leveldb_t* db,
    int num_ranges,
    const char* const* range_start_key, const size_t* range_start_key_len,
    const char* const* range_limit_key, const size_t* range_limit_key_len,
    uint64_t* sizes); */

/* extern void leveldb_compact_range(
    leveldb_t* db,
    const char* start_key, size_t start_key_len,
    const char* limit_key, size_t limit_key_len); */

/* Management operations */

/* extern void leveldb_destroy_db(
    const leveldb_options_t* options,
    const char* name,
    char** errptr); */

/* extern void leveldb_repair_db(
    const leveldb_options_t* options,
    const char* name,
    char** errptr); */

/* Iterator */

/* extern void leveldb_iter_destroy(leveldb_iterator_t*); */
use @leveldb_iter_destroy[None]( iter: Pointer[U8] tag )
/* extern unsigned char leveldb_iter_valid(const leveldb_iterator_t*); */
/* extern void leveldb_iter_seek_to_first(leveldb_iterator_t*); */
/* extern void leveldb_iter_seek_to_last(leveldb_iterator_t*); */
/* extern void leveldb_iter_seek(leveldb_iterator_t*, const char* k, size_t klen); */
// extern void leveldb_iter_next(leveldb_iterator_t*);
use @leveldb_iter_next[None]( iter: Pointer[U8] tag )
// extern void leveldb_iter_prev(leveldb_iterator_t*);
// extern const char* leveldb_iter_key(const leveldb_iterator_t*, size_t* klen);
use @leveldb_iter_key[Pointer[U8] val]( iter: Pointer[U8] tag )
// extern const char* leveldb_iter_value(const leveldb_iterator_t*, size_t* vlen);
use @leveldb_iter_value[Pointer[U8] val]( iter: Pointer[U8] tag )

// extern void leveldb_iter_get_error(const leveldb_iterator_t*, char** errptr);
use @leveldb_iter_get_error[None]( iter: Pointer[U8] tag,
    errptr: Pointer[Pointer[U8]] )

/* Write batch */

/* extern leveldb_writebatch_t* leveldb_writebatch_create(); */
/* extern void leveldb_writebatch_destroy(leveldb_writebatch_t*); */
/* extern void leveldb_writebatch_clear(leveldb_writebatch_t*); */
/* extern void leveldb_writebatch_put(
    leveldb_writebatch_t*,
    const char* key, size_t klen,
    const char* val, size_t vlen); */
/* extern void leveldb_writebatch_delete(
    leveldb_writebatch_t*,
    const char* key, size_t klen); */
/* extern void leveldb_writebatch_iterate(
    leveldb_writebatch_t*,
    void* state,
    void (*put)(void*, const char* k, size_t klen, const char* v, size_t vlen),
    void (*deleted)(void*, const char* k, size_t klen)); */

/* Options */

/* extern leveldb_options_t* leveldb_options_create(); */
use @leveldb_options_create[Pointer[U8]]()
/* extern void leveldb_options_destroy(leveldb_options_t*); */
use @leveldb_options_destroy[None]( opt: Pointer[U8] )
/* extern void leveldb_options_set_comparator(
    leveldb_options_t*,
    leveldb_comparator_t*); */
/* extern void leveldb_options_set_filter_policy(
    leveldb_options_t*,
    leveldb_filterpolicy_t*); */
/* extern void leveldb_options_set_create_if_missing(
leveldb_options_t*, unsigned char); */
use @leveldb_options_set_create_if_missing[None]( opt: Pointer[U8], flag: U8 )
/* extern void leveldb_options_set_error_if_exists(
    leveldb_options_t*, unsigned char); */
use @leveldb_options_set_error_if_exists[None]( opt: Pointer[U8], flag: U8 )
/* extern void leveldb_options_set_paranoid_checks(
    leveldb_options_t*, unsigned char); */
/* extern void leveldb_options_set_env(leveldb_options_t*, leveldb_env_t*); */
/* extern void leveldb_options_set_info_log(leveldb_options_t*, leveldb_logger_t*); */
/* extern void leveldb_options_set_write_buffer_size(leveldb_options_t*, size_t); */
/* extern void leveldb_options_set_max_open_files(leveldb_options_t*, int); */
/* extern void leveldb_options_set_cache(leveldb_options_t*, leveldb_cache_t*); */
/* extern void leveldb_options_set_block_size(leveldb_options_t*, size_t); */
/* extern void leveldb_options_set_block_restart_interval(leveldb_options_t*, int); */

use @strlen[USize]( ptr: Pointer[U8] )
/*
enum {
  leveldb_no_compression = 0,
  leveldb_snappy_compression = 1
  };
  */
/* extern void leveldb_options_set_compression(leveldb_options_t*, int); */

/* Comparator */

/* extern leveldb_comparator_t* leveldb_comparator_create(
    void* state,
    void (*destructor)(void*),
    int (*compare)(
        void*,
        const char* a, size_t alen,
        const char* b, size_t blen),
    const char* (*name)(void*)); */
/* extern void leveldb_comparator_destroy(leveldb_comparator_t*); */

/* Filter policy */

/* extern leveldb_filterpolicy_t* leveldb_filterpolicy_create(
    void* state,
    void (*destructor)(void*),
    char* (*create_filter)(
        void*,
        const char* const* key_array, const size_t* key_length_array,
        int num_keys,
        size_t* filter_length),
    unsigned char (*key_may_match)(
        void*,
        const char* key, size_t length,
        const char* filter, size_t filter_length),
    const char* (*name)(void*)); */
/* extern void leveldb_filterpolicy_destroy(leveldb_filterpolicy_t*); */

/* extern leveldb_filterpolicy_t* leveldb_filterpolicy_create_bloom(
    int bits_per_key); */

/* Read options */

/* extern leveldb_readoptions_t* leveldb_readoptions_create(); */
/* extern void leveldb_readoptions_destroy(leveldb_readoptions_t*); */
/* extern void leveldb_readoptions_set_verify_checksums(
    leveldb_readoptions_t*,
    unsigned char); */
/* extern void leveldb_readoptions_set_fill_cache(
    leveldb_readoptions_t*, unsigned char); */
/* extern void leveldb_readoptions_set_snapshot(
    leveldb_readoptions_t*,
    const leveldb_snapshot_t*); */

/* Write options */

/* extern leveldb_writeoptions_t* leveldb_writeoptions_create(); */
use @leveldb_writeoptions_create[Pointer[U8]]()
/* extern void leveldb_writeoptions_destroy(leveldb_writeoptions_t*); */
use @leveldb_writeoptions_destroy[None]( opts: Pointer[U8] tag )
/* extern void leveldb_writeoptions_set_sync(
    leveldb_writeoptions_t*, unsigned char); */
use @leveldb_writeoptions_set_sync[None]( opts: Pointer[U8] tag, flag: U8)

/* Cache */

/* extern leveldb_cache_t* leveldb_cache_create_lru(size_t capacity); */
/* extern void leveldb_cache_destroy(leveldb_cache_t* cache); */

/* Env */

/* extern leveldb_env_t* leveldb_create_default_env(); */
/* extern void leveldb_env_destroy(leveldb_env_t*); */

/* Utility */

/* Calls free(ptr).
   REQUIRES: ptr was malloc()-ed and returned by one of the routines
   in this file.  Note that in certain cases (typically on Windows), you
   may need to call this routine instead of free(ptr) to dispose of
   malloc()-ed memory returned by this library. */
/* extern void leveldb_free(void* ptr); */
use @leveldb_free[None]( ptr: Pointer[U8] )

/* Return the major and minor version number for this release. */
use @leveldb_major_version[USize]()
use @leveldb_minor_version[USize]()

class LDBvalue is Iterator[String]
  let _cursor: LDBcursor
  new create( cursor': LDBcursor ) =>
    _cursor = cursor'

  fun ref has_next(): Bool => _cursor.has_next()
  fun ref next(): String ? =>
    _cursor.next()
    _cursor.get_value()

class LDBkey is Iterator[String]
  let _cursor: LDBcursor
  new create( cursor': LDBcursor ) =>
    _cursor = cursor'

  fun ref has_next(): Bool => _cursor.has_next()
  fun ref next(): String ? =>
    _cursor.next()
    _cursor.get_key()

class LDBpair is Iterator[(String,String)]
  let _cursor: LDBcursor
  new create( cursor': LDBcursor ) =>
    _cursor = cursor'

  fun ref has_next(): Bool => _cursor.has_next()
  fun ref next(): (String,String) ? =>
    _cursor.next()
    (_cursor.get_key(),_cursor.get_value())

class LDBcursor
  let _db: LevelDB
  let _iter: Pointer[U8] tag
  var _errptr: Pointer[U8]

  new create( db': LevelDB, iter': Pointer[U8] ) =>
    _db = db'
    _iter = iter'
    _errptr = Pointer[U8].create()

  fun ref pairs():  LDBpair => LDBpair( this )
  fun ref keys():   LDBkey =>  LDBkey( this )
  fun ref values(): LDBvalue => LDBvalue( this )
  fun ref close() =>
    @leveldb_iter_destroy( _iter )

  fun ref has_next(): Bool => true

  fun ref next() ? =>
    """
    Advance the iterator to the next record.  This will throw an error
    if there is no next record.  LevelDB does not provide a peek-ahead
    so has_next always returns 'true' and we do the real test here.
    """
    @leveldb_iter_next( _iter )
    _errptr = Pointer[U8].create()
    @leveldb_iter_get_error( _iter, addressof _errptr )
    if not _errptr.is_null() then error end	  

  fun get_value(): String =>
    """
    Fetch the value stored at the current iterator location
    """
    let ptr = @leveldb_iter_value( _iter )
    recover val
      String.copy_cstring(ptr)
    end

  fun ref get_key(): String =>
    """
    Fetch the key stored at the current iterator location
    """
    let ptr = @leveldb_iter_key( _iter )
    recover val
      String.copy_cstring(ptr)
    end

class LevelDB
  """
  Represents an open connection to a LevelDB database.
  """
  let _dbhandle: Pointer[U8] tag
  var errtxt: String ref
  var errptr: Pointer[U8]
  let _syncwrite: Bool
  new create( name: String, sync: Bool = false ) =>
    """
    Create a new LevelDB database or open an existing one.
    """
    _syncwrite = sync
    errptr = Pointer[U8].create()
    let opts = @leveldb_options_create()
    @leveldb_options_set_create_if_missing( opts, U8(1) )

    _dbhandle = @leveldb_open( opts, name.cstring(), addressof errptr)
    @leveldb_options_destroy( opts )

    errtxt = if errptr.is_null() then
       String.create()
    else
       String.from_cstring( errptr )
    end

    //if not errptr.is_null() then error end

  new open( name: String, sync: Bool = false ) =>
    """
    Open an existing LevelDB database.  Error if not found.
    """
    _syncwrite = sync
    errptr = Pointer[U8].create()
    let opts = @leveldb_options_create()
    _dbhandle = @leveldb_open( opts, name.cstring(), addressof errptr )
    @leveldb_options_destroy( opts )
    errtxt = if errptr.is_null() then
       String.create()
    else
       String.from_cstring( errptr )
    end
 
  fun ref update( key: ByteSeq, value: ByteSeq ) ? =>
    """
    Write operations are 'update' so that Pony syntactic sugar will work
    for statements like 
	    db( key ) = value
    """
    errptr = Pointer[U8].create()
    // The the synchronized write option.
    let opts = @leveldb_writeoptions_create()
    @leveldb_writeoptions_set_sync( opts,
        (if _syncwrite then 1 else 0 end) )

    @leveldb_put( _dbhandle, opts,
		key.cstring(), key.size(),
		value.cstring(), value.size(),
		addressof errptr)
    @leveldb_writeoptions_destroy( opts )
    if not errptr.is_null() then error end

  fun ref apply( key: ByteSeq ): String ref ? =>
    """
    Fetch a single record, given the key.  This throws an error under
    two conditions:  (1) the record is not there, (2) some other problem
    ocurred.
    """
    // Initialize output fields
    var vlen: USize = 0
    errptr = Pointer[U8].create()
    // No options for now.
    let opts = @leveldb_options_create()
    let result = @leveldb_get( _dbhandle, opts, key.cstring(), key.size(),
    addressof vlen, addressof errptr)
    // Free the options structure
    @leveldb_options_destroy( opts )
    // Check for errors
    chkerror( errptr )
    // result is null if record not found
    if result.is_null() then
      error
    else
      // Create a String for the buffer that was returned.  LevelDB did
      // a 'malloc' of this data - hopefully Pony will GC it properly.
      // If not, try String.copy_cstring.
      //Array[U8].from_cstring( result, vlen )
      String.from_cstring( result, vlen )
    end

  fun ref chkerror( err: Pointer[U8] ) ? =>
    if not err.is_null() then
      @leveldb_free( err )
      error
    end

  fun ref error_val(): String ref^ ? =>
	  if errptr.is_null() then error
  else
	  String.copy_cstring( errptr )
  end
  

  fun ref delete( key: String ) ? =>
    """
    Remove the record with the specified key.
    """
    errptr = Pointer[U8].create()
    // No options for now.
    let opts = @leveldb_options_create()
    @leveldb_delete( _dbhandle, opts,
        key.cstring(), key.size(),
        addressof errptr )
    @leveldb_options_destroy( opts )
    chkerror( errptr )
    
  fun ref close() =>
    """
    Close the database connection.
    """
    @leveldb_close( _dbhandle )
		
