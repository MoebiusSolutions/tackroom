actor Main
  new create( env: Env ) =>
    let db = LevelDB.create( "fruitdb" )
    if db.errtxt.size() > 0 then
      env.out.print("Open error "+db.errtxt)
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

