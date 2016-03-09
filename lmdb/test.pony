actor Main

  new create( env: Env ) =>
    // Create the 'environment'.  This contains all LMDB operations.
    // The Notify class will take care of reporting any errors.	  
    var dbe: MDBEnvironment = MDBEnvironment.create( MyNotify.create(env) )

    // Open the environement, specifying the name of the directory that
    // will contain all the data files.  The 2nd parameter is the file system
    // protection mode for the files.
    dbe.open( "lmdb.mdb", 0, 0b111000000 )

    // Fetch an environment parameter.  Key size is usually 511.
    let maxkey = dbe.maxkeysize()
    env.out.print("  Max key size "+maxkey.string())

    // Start a Transaction.  The 0 is a bitmask of options.
    let txn = dbe.begin( 0 )

    // Open a 'database' within the environment.  Each database is a
    // separate Btree, but they are all contained within the single file.
    // By specifying None for the name, we get the default, single, nameless
    // database.
    let dbi = txn.open( None, 0 )

    // Now we write a record.  Data must be passed as Array[U8].
    let key = s2a("Orange")
    let dat = s2a("fruit")
    dbi( key ) = dat

    // Read back the record to see it is there.
    let result = dbi( s2a("Orange") )
    env.out.print( " Read back " + result.size().string() + " bytes" )

    // Done with the transaction.
    txn.commit()
    dbe.close()		    

  fun ref a2s( a: Array[U8] val) : String ref =>
    """
    Tedious function to convert Array[U8] to String.  There is
    undoubtedly a better way to do this.
    """
    var s: String ref = recover ref String.create( a.size() ) end
    var n: USize = 0
    while n < a.size() do
      try s.push( a(n) ) end
      n = n + 1
    end
    s
  
  fun ref s2a( s: String val ): Array[U8] =>
    recover iso
      var a: Array[U8] = Array[U8].create( s.size() )
      var n: USize = 0
      while n < s.size() do
	try a.push( s(n) ) end
        n = n + 1
      end   
      a
      end	  

class MyNotify is MDBNotify
  """
  Handle alerts coming back from LMDB.
  """
  let env: Env
  new create( env': Env ) =>
    env = env'

  fun ref fail( dbe: MDBEnvironment, code: I32, msg: String ) =>
    env.out.print("Error: " + msg)

