use "lib:helper"

// @noop returns its parameter, unchanged.  But we declare different caps
// for the input and output values, bypassing Pony's type checking.  The
// authors of LMDB did not have that checking in mind when they designed
// their API.
use @noop[Pointer[U8] ref]( input: Pointer[U8] tag )
use @memmove[Pointer[None]](dst: Pointer[None], src: Pointer[None], len: USize)

// Data in can be any of these types.
type MDBdata is (Array[U8] | String | U32 )
type _OptionalData is Maybe[MDBValue]

// Data out is always Array[U8].

struct ref MDBValue
  """
  This simple descriptor is used as an in/out parameter to some FFI
  routines.

  Key sizes must be between 1 and env.maxkeysize() inclusive.
  The same applies to data sizes in databases with the DUPSORT flag.

  Other data items can in theory be from 0 to 0xffffffff bytes long.
  Values returned from the database are valid only until a subsequent
  update operation, or the end of the transaction, so we copy any
  returned data into Pony-space. The fields will be overwritten by
  LMDB so we just initialize them to zero for now.
  """
  var _len: USize
  // ptr is tag because that is what Array.cstring() returns.
  var _tptr: Pointer[U8] tag

  new create( arg: (Array[U8] | String| U32 | None) = None ) =>
    match arg
      | let a: Array[U8] =>
		_len = a.size()
		_tptr = a.cstring()
      | let s: String =>
		_len = s.size()
		_tptr = s.cstring()
      | let n: U32 =>
		// Numeric values have to be copied into an array then the
		// byte order reversed.
		var temp: U32 = n
		var a: Array[U8] = Array[U8].undefined(4)
		@memmove( a.cstring(), addressof temp, 4 )
		var b: Array[U8] = a.reverse()
		_len = b.size()
		_tptr = b.cstring()
    else
      _len = 0
      _tptr = Pointer[U8].create()
    end

  // We use @noop to convert a tag pointer to a ref pointer.
  fun ref data(): Pointer[U8] ref => @noop(_tptr)
  fun ref size(): USize => _len

  fun ref array(): Array[U8] =>
    """
    Output values are always copied, since MDB only gives us a pointer
    into the virtual memory area, and that can change out from under us.
    """
    Array[U8].from_cstring( @noop(_tptr), _len ).clone()

primitive MDBConvert
  fun u32( a: Array[U8] ): U32 =>
    var n: U32 = 0
    var r: Array[U8] = a.reverse()
    @memmove( addressof n, r.cstring(), 4 )
    n
	  
