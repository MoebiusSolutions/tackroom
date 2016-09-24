/*
   Interface to the SQLITE3 relational database.
*/
use "lib:sqlite3"
use "debug"

use @sqlite3_open_v2[U32]( name: Pointer[U8] tag,
	db: Pointer[Pointer[_PPdb]], flags: U32, vfs: Pointer[U8] )
use @sqlite3_close_v2[U32]( db: Pointer[_PPdb] tag )
use @sqlite3_prepare_v2[U32]( db: Pointer[_PPdb] tag, sql: Pointer[U8] tag,
	maxlen: U32, stmt: Pointer[Pointer[_PPstmt] tag],
	extra: Pointer[Pointer[U8]] )
use @sqlite3_column_count[ISize]( stmt: Pointer[_PPstmt] tag )
use @sqlite3_column_name[Pointer[U8]]( stmt: Pointer[_PPstmt] tag, column: ISize )
use @sqlite3_column_type[U32]( stmt: Pointer[_PPstmt] tag, column: ISize )
use @sqlite3_column_double[F64]( handle: Pointer[_PPstmt] tag, column: ISize )
use @sqlite3_column_text[Pointer[U8] ref]( handle: Pointer[_PPstmt] tag,
	column: ISize )
use @sqlite3_column_int[ISize]( handle: Pointer[_PPstmt] tag, column: ISize )
use @sqlite3_step[U32]( stmt: Pointer[_PPstmt] tag )
use @sqlite3_column_bytes[U32]( stmt: Pointer[_PPstmt] tag, column: ISize )
use @sqlite3_column_blob[Pointer[U8] ref]( stmt: Pointer[_PPstmt] tag, column: ISize )
use @sqlite3_bind_text[U32]( stmt: Pointer[_PPstmt] tag, column: ISize,
	data: Pointer[U8] tag, size: USize )
use @sqlite3_bind_blob[U32]( stmt: Pointer[_PPstmt] tag,column: ISize,
	data: Pointer[U8] tag, size: USize )
use @sqlite3_bind_int[U32]( stmt: Pointer[_PPstmt] tag, column: ISize, data: ISize )
use @sqlite3_bind_double[U32]( stmt: Pointer[_PPstmt] tag, column: ISize, data: F64 )
use @sqlite3_finalize[U32]( stmt: Pointer[_PPstmt] tag )
use @sqlite3_reset[U32]( stmt: Pointer[_PPstmt] tag )
use @sqlite3_errmsg[Pointer[U8]]( db: Pointer[_PPdb] tag )

primitive _PPdb
primitive _PPstmt

class SqliteDB
  """
  This class represents a connection to an open sqlite3 database.
  """
  var handle: Pointer[_PPdb] tag = Pointer[_PPdb].create()
  let _notify: (None | SQLNotify)
  
  new create( notify: (SQLNotify | None), name: String,
	  flags: U32 = SqliteOpen.readwrite() ) =>
    """
    Open the sqlite database.  The flags must include either 'readonly'
    or 'readwrite', otherwise error 21 happens.
    """
    _notify = notify
    var dbhandle: Pointer[_PPdb] = Pointer[_PPdb].create()
    let err = @sqlite3_open_v2( name.cstring(), addressof dbhandle,
	flags, Pointer[U8].create() )
    handle = dbhandle
    _report(err)

  fun ref _report( code: U32 ) =>
    Debug.out("Reporting "+code.string())
    if code == 0 then return end
    match _notify
    | let n: SQLNotify =>
	var hdl = handle
        let msg = recover val
	      String.from_cstring( @sqlite3_errmsg( hdl ) )
	      end
	    n.fail(code, msg)
    end

  fun ref close() =>
    @sqlite3_close_v2( handle )

  fun ref prepare( sql: String ): SqliteStmt =>
    SqliteStmt.create( this, sql )

class SqliteStmt
  """
  This class represents a prepared SQL statement.
  """
  let sdb: SqliteDB
  var handle: Pointer[_PPstmt] tag = Pointer[_PPstmt].create()

  new create( sdb': SqliteDB, sql: String ) =>
    """
    Compile a SQL statement to be run on this database.  It will not actually
    run until a call to 'next' or 'execute'.
    """
    sdb = sdb'
    let db = sdb.handle
    var extra: Pointer[U8] = Pointer[U8].create()
    let err = @sqlite3_prepare_v2( db, sql.cstring(), sql.size().u32(),
	addressof handle, addressof extra )

  fun ref columns(): ISize =>
    @sqlite3_column_count( handle )

  fun ref next(): Bool =>
    let err = @sqlite3_step( handle )
    match err
    | SqliteError.row() => true
    | SqliteError.done() => false
    else
      sdb._report(err)
      false
    end

  fun ref execute() =>
    let err = @sqlite3_step( handle )
    if err != SqliteError.done() then
	sdb._report(err)
	end

  fun ref name( column: ISize ): String =>
    """
    Returns the name of a column in the query.
    """
    // Bring
    let hdl = handle
    recover val
      String.from_cstring( @sqlite3_column_name( hdl, column ))
      end

  fun ref datatype( column: ISize ): U32 =>
    @sqlite3_column_type( handle, column )

  fun ref string( column: ISize ): String =>
    """
    Returns the specified column as a string.
    """
    var col: ISize val = column
    var hdl = handle
    recover val
      String.copy_cstring( @sqlite3_column_text( hdl, col ) )
	end

  fun ref blob( column: ISize ): Array[U8] val =>
    let size = @sqlite3_column_bytes( handle, column )
    if size > 0 then
      var col: ISize val = column
	    var hdl = handle
	    var len: USize = size.usize()
	    recover val
	      let ptr = @sqlite3_column_blob( hdl, col )
	      Array[U8].from_cstring( ptr, len ).clone()
	    end
    else
      recover val Array[U8].create() end
    end

  fun ref int( column: ISize ): ISize =>
    """
    Return the specified column of the current row as an integer.
    """
    @sqlite3_column_int( handle, column )

  fun ref double( column: ISize ): F64 =>
    """
    Return the specified column of the current row as a float.
    """
    @sqlite3_column_double( handle, column )

  fun ref bind( column: ISize, value: (String | Array[U8] | ISize | F64 ) ) =>
    """
    Associate a value with a wildcard in a SQL statement.
    """
    let err = match value
      | let s: String =>
        @sqlite3_bind_text( handle, column, s.cstring(), s.size() )
      | let a: Array[U8] =>
	      @sqlite3_bind_blob( handle, column, a.cstring(), a.size() )
      | let n: ISize =>
	      @sqlite3_bind_int( handle, column, n )
      | let n: F64 =>
	      @sqlite3_bind_double( handle, column, n )
      end

  fun ref reset(): U32 =>
    """
    Reset the cursor back to its initial state.
    """
    @sqlite3_reset( handle )
		
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
		
