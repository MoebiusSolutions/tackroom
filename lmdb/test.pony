actor Main

  new create( env: Env ) =>
    var mynote: MyNotify = MyNotify.create( env )		
try
    // Create the 'environment'.  This contains all LMDB operations.
    // The Notify class will take care of reporting any errors.	  
    var dbe: MDBEnvironment = MDBEnvironment.create( mynote )

    // Allow for up to two databases.
    dbe.set_maxdb( 2 )

    // Open the environement, specifying the name of the directory that
    // will contain all the data files.  The 2nd parameter is a bitmask
    // of options.  The 3rd parameter is the file system
    // protection mode for the files.
    dbe.open( "fruit.mdb", 0, 0b111000000 )

    // Fetch an environment parameter.  Key size is usually 511.
    let maxkey = dbe.maxkeysize()
    env.out.print("  Max key size "+maxkey.string())

    // Start a Transaction.  The 0 is a bitmask of options, a subset of the
    // Environment options - just rdonly, nosync, and nometasync.
    var txn = dbe.begin( 0 )

    // Open a 'database' within the environment.  Each database is a
    // separate Btree, but they are all contained within the single file.
    // By specifying None for the name, we get the default, single, nameless
    // database.  Note that databases are opened within a particular
    // transaction.
    var food = txn.open( "FOOD",
	MDBopenflag.dupsort() or    // Allow duplicate keys
	MDBopenflag.createdb() )    // Create files if missing
    var nums = txn.open( "NUMS",
	MDBopenflag.createdb() )

    // Now we write some records.  Data can be passed as String or Array[U8].
    food( "Orange" ) = "fruit"
    food( "Orange" ) = "color"
    food( "Zuccini" ) = "vegetable"
    food( "Tuna" ) = "protein"
    food( "Tomato" ) = "vegetable"
    food( "Tilapia" ) = "protein"

    // Read back one record to see it is there.
    let result = food( "Tuna" )
    env.out.print( " Read back Tuna = "+a2s(result) )

    // Done with the transaction.  This does a 'sync' operation to make
    // sure the on-disk file reflect recent operations.
    txn.commit()

    // Start another for testing cursor operations.
    txn = dbe.begin( 0 )
    // Open the same table again
    food = txn.open( "FOOD", 0 )
    nums = txn.open( "NUMS", 0 )
    mynote.print( false )
    
    test_all( food, env )
    test_group( food, env, "Orange" )
    test_delete( food, env, "Tuna" )
    test_loop( food, env )
    test_numbers( nums, env )
    test_partial( food, env, "T" )
    env.out.print("Done")

    mynote.print( true )
    txn.commit()
    dbe.close()		    
  else
	env.out.print("Unexpected error")
  end

  fun ref test_numbers( dbi: MDBDatabase, env: Env ) ? =>
    env.out.print("Test of numeric keys")
    dbi( 17 ) = "seventeen"
    dbi( 32 ) = "thirtytwo"
    dbi( 256 ) = "three hundred"
    with query = dbi.all().pairs() do
    for (k,v) in query do
	    let key = MDBConvert.u32(k)
	    env.out.print("  " + key.string() + " = " + a2s(v))
        end
      end
    	  
  fun ref test_delete( dbi: MDBDatabase, env: Env, key: String ) ? =>
    var cursor = dbi.cursor()
    var k: Array[U8] = Array[U8].create(0)
    var v: Array[U8] = Array[U8].create(0)
    var first: Bool = true
    env.out.print("Test of deleting '" + key + "' record")
    cursor.seek( key )
    cursor.delete()
    cursor.close()
    test_all( dbi, env )

  fun ref test_partial( dbi: MDBDatabase, env: Env, start: String ) ? =>
    """
    Loop over all records with same initial string.
    """
    env.out.print("Test of iterator over just '"+start+"' records")
    with query = dbi.partial(start).pairs() do
      for (k,v) in query do
        env.out.print("  " + a2s(k) + " = " + a2s(v))
        end
      end

  fun ref test_loop( dbi: MDBDatabase, env: Env ) ? =>
    """
    Loop over all records in the database using the Iterator method.
    """
    env.out.print("Test of iterator over all records")
    with query = dbi.all().pairs() do
      for (k,v) in query do
        env.out.print("  " + a2s(k) + " = " + a2s(v))
        end
      end

    env.out.print("Test of iterator over just Orange values")
    with orange = dbi.group( "Orange" ).values() do
    for v in orange do
	    env.out.print("  " + a2s(v))
    end
    end

  fun ref test_all( dbi: MDBDatabase, env: Env ) ? =>
    """
    Loop over all records in the DB.
    """
    var cursor = dbi.cursor()
    var k: Array[U8] = Array[U8].create(0)
    var v: Array[U8] = Array[U8].create(0)
    var first: Bool = true
    env.out.print("Test of cursor over all records in reverse order")
    // Position to first record
    while true do
      try
	if first then
          (k,v) = cursor( MDBop.last() )
	  first = false
        else
	  (k,v) = cursor( MDBop.prev() )
        end // if
        env.out.print("  "+a2s(k)+" = "+a2s(v))
      else
	break
      end
     end
    cursor.close()

  fun ref test_group( dbi: MDBDatabase, env: Env, group: String ) ? =>
    """
    Loop over a single dup-group.  I would like to be able to write:
	for (k,v) in dbi.group("Orange").pairs() do
	  env.out.print(k,v)
	end
    """
    let start = group
    var cursor = dbi.cursor()
    var k: Array[U8] = Array[U8].create(0)
    var v: Array[U8] = Array[U8].create(0)
    var first: Bool = true
    env.out.print("Test of cursor over one duplicate-group")
    // Position to first record in the group
    while true do
      try
	if first then
          (k,v) = cursor.seek( "Orange" )
	  first = false
        else
	  (k,v) = cursor( MDBop.next_dup() )
        end // if
        env.out.print("  "+a2s(k)+" = "+a2s(v))
      else
	break
      end
     end
    cursor.close()

  fun ref a2s( a: Array[U8] box) : String val =>
    """
    Tedious function to convert Array[U8] to String.  There is
    undoubtedly a better way to do this.
    """
    // Make a local sendable copy of the size, so we cna use it in a recover.
    let len: USize val = a.size()
    var s: String iso = recover iso String.create( len ) end
    var n: USize = 0
    while n < a.size() do
      try s.push( a(n) ) end
      n = n + 1
    end
    consume s
/*  
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
*/
		
class MyNotify is MDBNotify
  """
  Handle alerts coming back from LMDB.
  """
  let env: Env
  var doprint: Bool = true
  new create( env': Env ) =>
    env = env'

  fun ref fail( dbe: MDBEnvironment, code: I32, msg: String ) =>
    if doprint then
      env.out.print("Error: " + msg)
      end

  fun ref print( yes: Bool ) =>
    doprint = yes
		
