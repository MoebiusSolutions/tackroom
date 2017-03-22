/* This file contains datatype conversion functions for LMDB.

LMDB treats all keys and data as binary byte sequences.  For convenience,
the following Pony types are acceptable as inputs:

  *  Array[U8]
  *  String
  *  U32, U64, and U128

  Internally, they are all treated as simple byte sequences.  Integers
  are converted from "little endian" where appropriate so that they sort
  properly.
*/
use "lib:helper"

// @noop returns its parameter, unchanged.  But we declare different caps
// for the input and output values, bypassing Pony's type checking.  The
// authors of LMDB did not have that checking in mind when they designed
// their API.
use @noop[Pointer[U8] ref]( input: Pointer[U8] tag )
use @memmove[Pointer[None]](dst: Pointer[None], src: Pointer[None], len: USize)

// Data in can be any of these types.
type MDBdata is (Array[U8] | String | U32 | U64 | U128 )
type _OptionalData is MaybePointer[MDBValue]

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
  var _tptr: Pointer[U8] tag

  new create( arg: (Array[U8] | String| U32 | U64 | U128 | None) = None ) =>
    match arg
      | let a: Array[U8] =>
		_len = a.size()
		_tptr = a.cpointer()
      | let s: String =>
		_len = s.size()
		_tptr = s.cpointer()
      | let n: U32 =>
		// Numeric values have to be copied into an array then the
		// byte order reversed.
		var temp: U32 = n
		var a = Array[U8].>undefined(4)
		@memmove( a.cpointer(), addressof temp, 4 )
		var b: Array[U8] = a.reverse()
		_len = b.size()
		_tptr = b.cpointer()
      | let n: U64 =>
		var temp: U64 = n
		var a = Array[U8].>undefined(8)
		@memmove( a.cpointer(), addressof temp, 8 )
		var b: Array[U8] = a.reverse()
		_len = b.size()
		_tptr = b.cpointer()
      | let n: U128 =>
		var temp: U128 = n
		var a = Array[U8].>undefined(16)
		@memmove( a.cpointer(), addressof temp, 16 )
		var b: Array[U8] = a.reverse()
		_len = b.size()
		_tptr = b.cpointer()
    else
      _len = 0
      _tptr = Pointer[U8].create()
    end

/* We use @noop to convert a tag pointer to a ref pointer.  The cstring
   functions of Array and String return a Pointer[U8] tag, but the
   constructor functions for those types want a Pointer[U8] ref.
*/
  fun ref data(): Pointer[U8] ref => @noop(_tptr)
  fun ref size(): USize => _len

  fun ref array(): Array[U8] =>
    """
    Output values are always copied, since MDB only gives us a pointer
    into the virtual memory area, and that can change out from under us.
    """
    Array[U8].from_cpointer( @noop(_tptr), _len ).clone()

primitive MDBConvert
  """
  Utility functions to convert Array[U8] data retreived from LMDB into
  various other types.  ALl of these require copying the data one way
  or another.
  """
  fun u32( a: Array[U8] ): U32 =>
    var n: U32 = 0
    var r: Array[U8] = a.reverse()
    @memmove( addressof n, r.cpointer(), 4 )
    n

  fun u64( a: Array[U8] ): U64 =>
    var n: U64 = 0
    var r: Array[U8] = a.reverse()
    @memmove( addressof n, r.cpointer(), 8 )
    n

  fun u128( a: Array[U8] ): U128 =>
    var n: U128 = 0
    var r: Array[U8] = a.reverse()
    @memmove( addressof n, r.cpointer(), 16 )
    n

  fun string( a: Array[U8] box) : String val =>
    """
    Tedious function to convert Array[U8] to String.  There is
    undoubtedly a better way to do this.  It has to make a copy
    to make sure the zero byte is at the end of the String.
    """
    // Make a local sendable copy of the size, so we can use it in a recover.
    let len: USize val = a.size()
    var s: String iso = recover iso String.create( len ) end
    var n: USize = 0
    while n < a.size() do
      try s.push( a(n) ) end
      n=n+1
      end
    consume s

  fun array( data: (MDBdata | None) ): Array[U8] =>
    match data
    | let a: Array[U8] => a
    | let s: String =>
        Array[U8].from_cpointer(@noop(s.cpointer()), s.size())
    | let n: U32 =>
	// Numeric values have to be copied into an array then the
	// byte order reversed.
	var temp: U32 = n
	var a = Array[U8].>undefined(4)
	@memmove( a.cpointer(), addressof temp, 4 )
	var b: Array[U8] = a.reverse()
	b
    | let n: U64 =>
	var temp: U64 = n
	var a = Array[U8].>undefined(8)
	@memmove( a.cpointer(), addressof temp, 8 )
	var b: Array[U8] = a.reverse()
	b
    | let n: U128 =>
	var temp: U128 = n
	var a = Array[U8].>undefined(16)
	@memmove( a.cpointer(), addressof temp, 16 )
	var b: Array[U8] = a.reverse()
	b
    else
	Array[U8].create()
    end
