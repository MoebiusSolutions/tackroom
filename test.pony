actor Main
  new create( env: Env ) =>
    try
      let db = LevelDB.create( "test.ldb" )
      db.put( "Orange", "fruit" )
      db.put( "Apple", "fruit" )
      db.put( "Zuccini", "vegetable" )

      // Read back some of the data.
      for key in ["Orange", "Zuccini"] do
        try
	  let value = db( key )
	  env.out.print(key + "=" + value)
	else
	  env.out.print("Get failed for "+key)
	end
      end

      db.delete( "Apple" )
      db.close()
      env.out.print("LevelDB test complete")
    else
      env.out.print("Fail")
    end
