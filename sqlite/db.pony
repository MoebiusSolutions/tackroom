/*
   Interface to the SQLITE3 relational database.
*/
use "lib:sqlite3"

use @sqlite3_open_v2[U32]( name: Pointer[U8] tag,
	db: Pointer[Pointer[_PPdb]], flags: U32, vfs: Pointer[U8] )
use @sqlite3_close_v2[U32]( db: Pointer[_PPdb] )
use @sqlite3_prepare_v2[U32]( db: Pointer[_PPdb], sql: Pointer[U8] tag,
	maxlen: U32, stmt: Pointer[Pointer[_PPstmt]],
	extra: Pointer[Pointer[U8]] )
use @sqlite3_column_count[U32]( stmt: Pointer[_PPstmt] )
use @sqlite3_column_name[Pointer[U8]]( stmt: Pointer[_PPstmt], column: U32 )
use @sqlite3_column_type[U32]( stmt: Pointer[_PPstmt], column: U32 )
use @sqlite3_column_double[F64]( handle: Pointer[_PPstmt], column: U32 )
use @sqlite3_column_text[Pointer[U8]]( handle: Pointer[_PPstmt], column: U32 )
use @sqlite3_column_int[U64]( handle: Pointer[_PPstmt], column: U32 )
use @sqlite3_step[U32]( stmt: Pointer[_PPstmt] )
use @sqlite3_column_bytes[U32]( stmt: Pointer[_PPstmt], column: U32 )
use @sqlite3_column_blob[Pointer[U8]]( stmt: Pointer[_PPstmt], column: U32 )
use @sqlite3_bind_text[U32]( stmt: Pointer[_PPstmt], column: U32,
	data: Pointer[U8] tag, size: USize )
use @sqlite3_bind_blob[U32]( stmt: Pointer[_PPstmt],column: U32,
	data: Pointer[U8] tag, size: USize )
use @sqlite3_bind_int[U32]( stmt: Pointer[_PPstmt], column: U32, data: U64 )
use @sqlite3_bind_double[U32]( stmt: Pointer[_PPstmt], column: U32, data: F64 )
use @sqlite3_finalize[U32]( stmt: Pointer[_PPstmt] )
primitive _PPdb
primitive _PPstmt

class SqliteDB
  var handle: Pointer[_PPdb] = Pointer[_PPdb].create()
  let _notify: (None | SQLNotify)
  
  new create( notify: (SQLNotify | None), name: String, flags: U32 = 0 ) =>
    _notify = notify
    let err = @sqlite3_open_v2( name.cstring(),  addressof handle,
	  flags, Pointer[U8].create() )
    _report(err)

  fun ref _report( code: U32 ) =>
    if code == 0 then return end
    match _notify
      | let n: SQLNotify => n.fail(code, "oops")
    end

  fun ref close() =>
    @sqlite3_close_v2( handle )

  fun ref prepare( sql: String ): SqliteStmt =>
    SqliteStmt.create( this, sql )

class SqliteStmt
  let sdb: SqliteDB
  var handle: Pointer[_PPstmt] = Pointer[_PPstmt].create()

  new create( sdb': SqliteDB, sql: String ) =>
    sdb = sdb'
    let db = sdb.handle
    var extra: Pointer[U8] = Pointer[U8].create()
    let err = @sqlite3_prepare_v2( db, sql.cstring(), sql.size().u32(),
	addressof handle, addressof extra )

  fun ref columns(): U32 =>
    @sqlite3_column_count( handle )

  fun ref step(): U32 =>
    @sqlite3_step( handle )

  fun ref name( column: U32 ): String ref =>
    String.from_cstring( @sqlite3_column_name( handle, column ))

  fun ref datatype( column: U32 ): U32 =>
    @sqlite3_column_type( handle, column )

  fun ref text( column: U32 ): String ref =>
      let ptr: Pointer[U8] = @sqlite3_column_text( handle, column )	
      String.from_cstring( ptr )

  fun ref int( column: U32 ): U64 =>
    @sqlite3_column_int( handle, column )

  fun ref double( column: U32 ): F64 =>
    @sqlite3_column_double( handle, column )

  fun ref blob( column: U32 ): Array[U8] =>
    let size = @sqlite3_column_bytes( handle, column )
    if size > 0 then
      let ptr = @sqlite3_column_blob( handle, column )
      Array[U8].from_cstring( ptr, size.usize() )		
    else
      Array[U8].create()
    end

  fun ref bind( column: U32, value: (String | Array[U8] | U64 | F64 ) ) =>
    let err = match value
      | let s: String =>
	  @sqlite3_bind_text( handle, column, s.cstring(), s.size() )
      | let a: Array[U8] =>
	  @sqlite3_bind_blob( handle, column, a.cstring(), a.size() )
      | let n: U64 =>
	  @sqlite3_bind_int( handle, column, n )
      | let n: F64 =>
	  @sqlite3_bind_double( handle, column, n )
      end

  fun ref close() =>
    @sqlite3_finalize( handle )


primitive SQLType
  fun integer(): U32 => 1
  fun float(): U32 => 2
  fun text(): U32 => 3
  fun blob(): U32 => 4
  fun null(): U32 => 5

interface SQLNotify
  """
  Notifications for LMDB operations.
  """
    fun ref fail( code: U32, msg: String ) =>
    """
    Called when an operation fails.
    """
    None
		
