interface MDBNotify
  """
  Notifications for LMDB operations.
  """
	fun ref fail( env: MDBEnvironment, code: Stat,
		msg: String ) =>
    """
    Called when an operation fails.
    """
    None
		
