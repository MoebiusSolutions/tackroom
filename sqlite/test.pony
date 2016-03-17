actor Main
  new create( env: Env ) =>
    // Open the database
    var db: SqliteDB = SqliteDB.create( MyNotify.create(env),
	"movies.dbx",
	SqliteOpen.readwrite() )

    // Create a query.
    var q: SqliteStmt = db.prepare(
      """SELECT ROWID,TTL FROM MOVIES WHERE GEN="adv" ORDER BY TTL LIMIT 10""" )

    // Print some metadata.
    let nc = q.columns()
    env.out.print("Query has "+nc.string() + " columns")

    var n: U32 = 0
    while n < nc do
      let name = q.name(n)
      let dtype = q.datatype(n)
      env.out.print("  Col "+n.string()+" "+name+" "+dtype.string())
      n = n + 1
    end

    while q.next() do
      let num = q.int(0)
      let ttl = q.string(1)
      env.out.print( num.string() + ": " + ttl )
      end

    q.close()

    q = db.prepare("UPDATE MOVIES SET TTL=? WHERE ROWID=28")
    q.bind( 1, "--> something---" )
    q.execute()
    q.close()
    db.close()

class MyNotify is SQLNotify
  """
  Handle alerts coming back from SQLite
  """
  let env: Env
  var doprint: U8 = 2
  new create( env': Env ) =>
    env = env'

  fun ref fail( code: U32, msg: String ) =>
    env.out.print("SQLite error "+code.string()+", "+msg)

