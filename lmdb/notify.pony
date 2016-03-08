interface MDBNotify
  """
  Notifications for LMDB operations.
  """
  fun ref fail( env: MDBEnvironment, msg: String ) =>
    """
    Called when an operation fails.
    """
    None
		
