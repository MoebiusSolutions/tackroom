actor Main
  new create( env: Env ) =>
    try
      let db = LevelDB.create( "test.ldb" )
      db.put( "Orange", "fruit" )
      db.put( "Apple", "fruit" )
      db.put( "Zuccini", "vegetable" )

      // Read back the data starting at 'Orange'.  Records are sorted
      // by key so the 'Apple' record should not be returned.
      let cursor = db.get( "Orange" )
      for (key,data) in cursor.pairs() do
        env.out.print(data)
        end

      db.delete( "Apple" )
      db.close()
      env.out.print("LevelDB test complete")
    else
      env.out.print("Fail")
    end
