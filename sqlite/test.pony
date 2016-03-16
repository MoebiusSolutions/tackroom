actor Main
  new create( env: Env ) =>
    // Open the database
    var db: SqliteDB = SqliteDB.create( MyNotify.create(env),
	"movies.db",
	SqliteOpen.readonly() )

    // Create a query.
    var q: SqliteStmt = db.prepare( "SELECT * FROM MOVIES" )

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

    while q.has_next() do
      env.out.print( q.text(1) )
      end

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
    env.out.print("SQLite error "+code.string()+"="+msg)

