actor Main

  new create( env: Env ) =>
    var mynote: MyNotify = MyNotify.create( env )		
try
    // Get LMDB version
    let v = MDBVersion
    env.out.print( "LMDB version " + v.major.string() +
	"." + v.minor.string() )

    // Create the 'environment'.  This contains all LMDB operations.
    // The Notify class will take care of reporting any errors.	  
    var dbe: MDBEnvironment = MDBEnvironment.create( mynote )

    // Allow for up to two databases in the environment.  This has to
    // be specified before the 'open' call.
    dbe.set_maxdb( 2 )

    // Open the environment, specifying the name of the directory that
    // will contain all the data files.  The 2nd parameter is a bitmask
    // of options.  The 3rd parameter is the file system
    // protection mode for the files.   The directory must already exist.
    dbe.open( "fruit.mdb", 0, 0b111000000 )

    // Fetch an environment parameter.  Key size is usually 511.
    let maxkey = dbe.maxkeysize()
    env.out.print("  Max key size "+maxkey.string())

    // Start a Transaction.  There are additional optional parameters
    // of a bitmask of options, and a parent transaction.
    var txn = dbe.begin()

    // Open a 'database' within the environment.  Each database is a
    // separate Btree, but they are all contained within the single file.
    // It might be clearer to refer to these as 'tables'.
    // By specifying None for the name, we get the default, single, nameless
    // database.  Note that databases are opened within a particular
    // transaction.
    var food = txn.open( "FOOD",
	MDBopenflag.dupsort() or    // Allow duplicate keys
	MDBopenflag.createdb() )    // Create files if missing
    var nums = txn.open( "NUMS",
	MDBopenflag.createdb() )

    // Now we write some records.  Data can be passed as String, Array[U8],
    // or various unsigned integers.
    food( "Orange" ) = "fruit"
    food( "Orange" ) = "color"
    food( "Zuccini" ) = "vegetable"
    food( "Tuna" ) = "protein"
    food( "Tomato" ) = "vegetable"
    food( "Tilapia" ) = "protein"

    // Read back one record to see it is there.
    let result = food( "Tuna" )
    env.out.print( " Read back Tuna = "+MDBConvert.string(result) )

    // Done with the transaction.  This does a 'sync' operation to make
    // sure the on-disk file reflect recent operations.
    txn.commit()

    // Start another for testing cursor operations.
    txn = dbe.begin()
    // Open the same tables again.
    food = txn.open( "FOOD" )
    nums = txn.open( "NUMS" )

    // Varous test suites.
    // Disable NOTFOUND error preport - they happen at the end of queries.
    mynote.print( 1 )
    test_all( food, env )
    test_group( food, env, "Orange" )
    test_delete( food, env, "Tuna" )
    test_loop( food, env )
    test_numbers( nums, env )
    test_partial( food, env, "T" )
    env.out.print("Done")
    txn.commit()
    dbe.close()		    
  else
	env.out.print("Unexpected error in tests")
  end

  fun ref test_numbers( dbi: MDBDatabase, env: Env ) ? =>
    """
    Note that when using numeric keys, all keys in a given database must
    be the same length if consistent sorting is expected.  This is
    because values are internally converted to left-padded byte sequences
    according to the specified type width.  The numeric type must be
    specified because it will accept U32, U64, and U128.
    """
    env.out.print("Test of numeric keys")
    dbi( U32(17) ) = "seventeen"
    dbi( U32(32) ) = "thirtytwo"
    dbi( U32(256) ) = "two fifty six"

    with query = dbi.all().pairs() do
      for (k,v) in query do
        let key = MDBConvert.u32(k)
	env.out.print("  " + key.string() + " = " + MDBConvert.string(v))
        end
      end
    	  
  fun ref test_delete( dbi: MDBDatabase, env: Env, key: String ) ? =>
    """
    Test deleting a record by cursor.
    """
    env.out.print("Test of deleting '" + key + "' record")
    var cursor = dbi.cursor()
    cursor.seek( key )
    cursor.delete()
    cursor.close()
    // Dump the whole table again
    test_all( dbi, env )

  fun ref test_partial( dbi: MDBDatabase, env: Env, start: String ) ? =>
    """
    Loop over all records with same initial string.
    """
    env.out.print("Test of iterator over just '"+start+"' records")
    with query = dbi.partial(start).pairs() do
      for (k,v) in query do
        env.out.print("  " + MDBConvert.string(k) +
	      " = " + MDBConvert.string(v))
        end
      end

  fun ref test_loop( dbi: MDBDatabase, env: Env ) ? =>
    """
    Loop over all records in the database an Iterator.
    """
    env.out.print("Test of iterator over all records")
    with query = dbi.all().pairs() do
      for (k,v) in query do
        env.out.print("  " + MDBConvert.string(k) +
	      " = " + MDBConvert.string(v))
        end
      end

    env.out.print("Test of iterator over just Orange values")
    with orange = dbi.group( "Orange" ).values() do
      for v in orange do
        env.out.print("  " + MDBConvert.string(v))
        end
     end

  fun ref test_all( dbi: MDBDatabase, env: Env ) ? =>
    """
    Loop over all records in the DB using just cursor operations.
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
        env.out.print("  "+MDBConvert.string(k)+" = "+MDBConvert.string(v))
      else
	break
      end
     end
    cursor.close()

  fun ref test_group( dbi: MDBDatabase, env: Env, group: String ) ? =>
    """
    Loop over a single dup-group.
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
        env.out.print("  "+MDBConvert.string(k)+
	    " = "+MDBConvert.string(v))
      else
	break
      end
     end
    cursor.close()
		
class MyNotify is MDBNotify
  """
  Handle alerts coming back from LMDB.
  """
  let env: Env
  var doprint: U8 = 2
  new create( env': Env ) =>
    env = env'

  fun ref fail( dbe: MDBEnvironment, code: I32, msg: String ) =>
    if doprint > 0 then
      if (doprint < 2) and (code == MDBerror.notfound()) then return end
      env.out.print("Error: " + msg)
      end

  fun ref print( level: U8 ) =>
    doprint = level
		
