/* All LMDB data operations take place within a transaction.
*/
use @mdb_txn_id[U32]( txn: Pointer[MDBtxn] tag )   
use @mdb_txn_commit[Stat]( txn: Pointer[MDBtxn] tag )
use @mdb_txn_abort[None]( txn: Pointer[MDBtxn] tag )
use @mdb_txn_reset[None]( txn: Pointer[MDBtxn] tag )
use @mdb_txn_renew[None]( txn: Pointer[MDBtxn] tag)
use @mdb_dbi_open[Stat]( txn: Pointer[MDBtxn] tag,
	name: Pointer[U8] tag,
	flags: FlagMask,
	dbi: Pointer[Pointer[MDBdbi]] )

class MDBTransaction
  """
  The transaction handle may be discarded using abort() or commit().
  A transaction and its cursors must only be used by a single
  thread, and a thread may only have a single transaction at a time.
  If NOTLS is in use, this does not apply to read-only transactions.
  Cursors may not span transactions.
  """
  let _mdbtxn: Pointer[MDBtxn]
  let _env: MDBEnvironment
  new create( env: MDBEnvironment, txn: Pointer[MDBtxn] ) =>
    _mdbtxn = txn
    _env = env

  fun ref handle(): Pointer[MDBtxn] tag => _mdbtxn

  fun ref id(): U32 =>
    """
    Return the transaction's ID number.
    This returns the identifier associated with this transaction. For a
    read-only transaction, this corresponds to the snapshot being read;
    concurrent readers will frequently have the same transaction ID.
    """
    @mdb_txn_id( _mdbtxn )

  fun ref commit() ? =>
    """
    Commit all the operations of a transaction into the database.
    The transaction handle is freed. It and its cursors must not be used
    again after this call, except with #mdb_cursor_renew().
    Earlier documentation incorrectly said all cursors would be freed.
    Only write-transactions free cursors.
    """
    let err = @mdb_txn_commit( _mdbtxn )
    _env.report_error( err )

  fun ref abort() =>
    """
    Abandon all the operations of the transaction instead of saving them.
    The transaction handle is freed. It and its cursors must not be used
    again after this call, except with #mdb_cursor_renew().
    Earlier documentation incorrectly said all cursors would be freed.
    Only write-transactions free cursors.
    """
    @mdb_txn_abort( _mdbtxn )

  fun ref reset() =>
    """
    Reset a read-only transaction.
    Abort the transaction like #mdb_txn_abort(), but keep the transaction
    handle. renew() may reuse the handle. This saves allocation
    overhead if the process will start a new read-only transaction soon,
    and also locking overhead if NOTLS is in use. The reader table
    lock is released, but the table slot stays tied to its thread or
    MDBtxn. Use abort() to discard a reset handle, and to free
    its lock table slot if NOTLS is in use.
    Cursors opened within the transaction must not be used
    again after this call, except with renew().
    Reader locks generally don't interfere with writers, but they keep old
    versions of database pages allocated. Thus they prevent the old pages
    from being reused when writers commit new data, and so under heavy load
    the database size may grow much more rapidly than otherwise.
     """
     let err = @mdb_txn_reset( _mdbtxn )

  fun ref renew() =>
    """
    Renew a read-only transaction.
    This acquires a new reader lock for a transaction handle that had been
    released by txn.reset(). It must be called before a reset transaction
    may be used again.
    """
    let err = @mdb_txn_renew( _mdbtxn )

  fun ref open( name: (String | None),
		flags: FlagMask = 0 ): MDBDatabase ? =>
    """
    Open a database in the environment.
    A database handle denotes the name and parameters of a database,
    independently of whether such a database exists.
    The database handle may be discarded by calling dbi.close().
    The old database handle is returned if the database was already open.
    The handle may only be closed once.

    The database handle will be private to the current transaction until
    the transaction is successfully committed. If the transaction is
    aborted the handle will be closed automatically.
    After a successful commit the handle will reside in the shared
    environment, and may be used by other transactions.

    This function must not be called from multiple concurrent
    transactions in the same process. A transaction that uses
    this function must finish (either commit or abort) before
    any other transaction in the process may use this function.

    To use named databases (with name != None), env.set_maxdbs()
    must be called before opening the environment.  Database names are
    keys in the unnamed database, and may be read but not written.
    """
    var namep: Pointer[U8 val] tag =
	    match name
	    | let s: String => s.cstring()
	    else Pointer[U8].create()
	    end
    // A place to receive the new DBI handle
    var dbi: Pointer[MDBdbi] = Pointer[MDBdbi].create()
    let err = @mdb_dbi_open( _mdbtxn, namep,
        flags, addressof dbi )
    _env.report_error( err )
    MDBDatabase.create( _env, _mdbtxn, dbi )

