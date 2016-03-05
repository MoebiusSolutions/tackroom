actor Main
  new create( env: Env ) =>
    try
	    let db = LevelDB.create( "testdb" )
	    if not db.errptr.is_null() then
		    let s = String.from_cstring(db.errptr)
		    env.out.print(s)
	    end
	    
      try
        db( "Orange" ) = "fruit" 
        db( "Apple" ) = "fruit" 
        db( "Zuccini") = "vegetable"
        env.out.print("Inserts done")
      else
	env.out.print("Update fail")
      end

      // Read back some of the data.
      for key in ["Orange", "Zuccini"].values() do
        try
	  let value = db( key )
	  env.out.print(key + "=" + value)
	else
	  env.out.print("Get failed for "+key)
	end
      end

      try
        db.delete( "Apple" )
      else
	env.out.print("Delete fail")
      end
      db.close()
      env.out.print("LevelDB test complete")
    else
      env.out.print("Could not open DB ")
    end
