actor Main

  new create( env: Env ) =>
    var mynote: MyNotify = MyNotify.create( env )		
try
    // Create the 'environment'.  This contains all LMDB operations.
    // The Notify class will take care of reporting any errors.	  
    var dbe: MDBEnvironment = MDBEnvironment.create( mynote )

    // Open the environement, specifying the name of the directory that
    // will contain all the data files.  The 2nd parameter is the file system
    // protection mode for the files.
    dbe.open( "lmdb.mdb", 0, 0b111000000 )

    // Fetch an environment parameter.  Key size is usually 511.
    let maxkey = dbe.maxkeysize()
    env.out.print("  Max key size "+maxkey.string())
    // Start a Transaction.  The 0 is a bitmask of options.
    var txn = dbe.begin( 0 )

    // Open a 'database' within the environment.  Each database is a
    // separate Btree, but they are all contained within the single file.
    // By specifying None for the name, we get the default, single, nameless
    // database.
    var dbi = txn.open( None,
	MDBopenflag.dupsort() or
	MDBopenflag.createdb() )

    // Now we write some records.  Data must be passed as Array[U8].
    write( dbi, "Orange", "fruit" )
    write( dbi, "Orange", "color" )
    write( dbi, "Zuccini", "vegetable" )
    write( dbi, "Tuna", "protein" )

    // Read back one record to see it is there.
    let result = a2s(dbi( s2a("Orange") ))
    env.out.print( " Read back "+result )

    // Done with the transaction.
    txn.commit()

    // Start another for testing cursor operations.
    txn = dbe.begin( 0 )
    dbi = txn.open( None, 0 )
    mynote.print( false )
    test_all( dbi, env )
    test_group( dbi, env, "Orange" )
    mynote.print( true )
    txn.commit()
    dbe.close()		    
  else
	env.out.print("Unexpected error")
  end

  fun ref test_all( dbi: MDBDatabase, env: Env ) ? =>
    """
    Loop over all records in the DB.  I would like to be able to write:
	for (k,v) in dbi.all().pairs() do
	  env.out.print(k,v)
	end
    The problem is that if the body of the loop contains a 'break'
    then there is no place to close the cursor that was created inside
    the dbi.all() function.
    """
    var cursor = dbi.cursor()
    var k: Array[U8] = Array[U8].create(0)
    var v: Array[U8] = Array[U8].create(0)
    var first: Bool = true
    env.out.print("Test of cursor over all records")
    // Position to first record
    while true do
      try
	if first then
          (k,v) = cursor( MDBop.first() )
	  first = false
        else
	  (k,v) = cursor( MDBop.next() )
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
    let start = s2a(group)
    var cursor = dbi.cursor()
    var k: Array[U8] = Array[U8].create(0)
    var v: Array[U8] = Array[U8].create(0)
    var first: Bool = true
    env.out.print("Test of cursor over one duplicate-group")
    // Position to first record in the group
    while true do
      try
	if first then
          (k,v) = cursor( MDBop.first() )
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

  fun ref write( d: MDBDatabase, k: String, v: String ) ? =>
    let key = s2a(k)
    let dat = s2a(v)
    d( key ) = dat
		
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
		
