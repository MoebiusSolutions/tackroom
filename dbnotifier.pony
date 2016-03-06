interface PonyDB
  fun apply( key: String ): String => None
  fun ref update( key: String, data: String ) => None
		
interface DBNotify
  """
  Notifications for database operations
  """
  fun ref open_failed( name: String ) => None
  fun ref oper_failed( dbi: PonyDB ref, opname: String ) => None
  fun ref opened( dbi: PonyDB ref ) => None

	  
