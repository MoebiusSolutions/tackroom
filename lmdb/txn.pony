use @mdb_txn_begin[USize]( env: Pointer[MDB_env], parent: Pointer[MDBtxn],
   flags: USize, txn: Pointer[Pointer[MDBtxn]] )
use @mdb_txn_id[USize]( txn: Pointer[MDBtxn] )   
use @mdb_txn_commit[USize]( txn: Pointer[MDBtxn] )
use @mdb_txn_abort[None]( txn: Pointer[MDBtxn] )
use @mdb_txn_reset[None]( txn: Pointer[MDBtxn] )
use @mdb_txn_renew[None]( txn: Pointer[MDBtxn])
use @mdb_stats[USize]( txn: Pointer[MDBtxn], dbi: Pointer[MDB_dbi],
     stats: Pointer[Pointer[MDBdbstats]] )

class MDBTransaction
  """
  The transaction handle may be discarded using abort() or commit().
  A transaction and its cursors must only be used by a single
  thread, and a thread may only have a single transaction at a time.
  If NOTLS is in use, this does not apply to read-only transactions.
  Cursors may not span transactions.
  """
  let _txn: MDBtxn
  let _env: MDBEnvironment
  new create( env: MDBEnvironment, txn: MDBtxn ) =>
    _txn = txn
    _env = env

  fun ref handle(): MDBtxn => _txn

  fun ref id(): USize =>
    """
    Return the transaction's ID number.
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

  fun ref reset() =>
    """
    Reset a read-only transaction.
    Abort the transaction like #mdb_txn_abort(), but keep the transaction
    handle. #mdb_txn_renew() may reuse the handle. This saves allocation
    overhead if the process will start a new read-only transaction soon,
 * and also locking overhead if #MDB_NOTLS is in use. The reader table
 * lock is released, but the table slot stays tied to its thread or
 * #MDBtxn. Use mdb_txn_abort() to discard a reset handle, and to free
 * its lock table slot if MDB_NOTLS is in use.
 * Cursors opened within the transaction must not be used
 * again after this call, except with #mdb_cursor_renew().
 * Reader locks generally don't interfere with writers, but they keep old
 * versions of database pages allocated. Thus they prevent the old pages
 * from being reused when writers commit new data, and so under heavy load
 * the database size may grow much more rapidly than otherwise.
 * @param[in] txn A transaction handle returned by #mdb_txn_begin()
     """
     @mdb_txn_reset( _txn )

  fun ref renew() =>
    """
    Renew a read-only transaction.
 *
 * This acquires a new reader lock for a transaction handle that had been
 * released by #mdb_txn_reset(). It must be called before a reset transaction
 * may be used again.
    """
    @mdb_txn_renew( _txn )

  fun ref opendb( name: String, flags: USize = 0 ): MDBDatabase =>
    """
    Open a database in the environment.
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
 """
     var dbi: Pointer[MDB_dbi] = Pointer[MDB_dbi]()
     let err = @mdb_dbi_open( _txn,
         (if name.size() == 0 then Pointer[U8]() else name.cstring() end),
         flags, addressof dbi )
     MDBDatabase.create( _txn, dbi )

