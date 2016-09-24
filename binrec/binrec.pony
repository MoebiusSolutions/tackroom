/* This package encodes and decodes binary records in something similar
  to Erlang External Term format.  A single value is a Tag, Length, Value
  triple.  The encoded size can be as small as one byte (for None and
  very small integers) up to a separate byte for tag, one to four bytes
  for length, plus the actual value.

  This is a low-level encoding of primitive Pony data types.  Any semantic
  meaning or additional (classes, etc) structure must be applied by the
  application code.
*/
use "buffered"
use "collections"

type BinType is (U8 | U16 | U32 | USize | String | ByteSeq | None)

// Binary Record data types.
primitive _BRDT
  fun none(): U8 => 0x00
  fun tiny_uint(): U8 => 0x10 // + value 0-15
  fun uint(): U8 =>      0x20 // + Len 0, 2, 4, 8, then BigEnd value
  fun tiny_str(): U8 => 0x30 // + len 0-15, then Array[U8]
  fun string(): U8 =>   0x40 // + 1, 2, 4, then Length, then Array[U8]
  fun tiny_array(): U8 =>0x50 // + Len 0-15 then N terms
  fun array(): U8 =>     0x60 // + 0, 2, then Len, then N terms
  fun map(): U8 =>      0x68 // then N, then 0-255 pairs of terms
  fun blob(): U8 =>     0x70 // + 1, 2, 4 then Len, then ByteSeq

class BinRecWriter
  """
  Create a binary record.
  """
  var _buffer: Writer

  new create() =>
    _buffer = Writer
/*
  new from_map( m: Map[U8,String] ) =>
    _buffer = Writer
    add_map( m )
*/
  fun ref data(): Array[ByteSeq] iso^ =>
    """
    Retreive the assembled record after everything has been added.
    """
    _buffer.done()

  fun ref add( value: BinType ) =>
    """
    Add any value to the record, choosing the appropriate encoding for
    the type.
    """
    match value
      | None => _add_none()
      | let n: U8 => _add_uint( n )
      | let n: U16 => _add_uint( n )
      | let n: U32 => _add_uint( n )
      | let s: String => _add_string( s )
      | let b: ByteSeq => _add_blob( b )
    end

  fun ref _add_none() =>
    _buffer.u8( _BRDT.none() )

  fun ref <add_pair( a1: BinType, a2: BinType ) =>
    add( a1 )
    add( a2 )

  fun ref _add_string( s: String ) =>
    """
    Add a String to the record.  The length is encoded in as few bytes
    as possible.
    """
    match s.size()
      | let n: USize if n < 16 =>
          // Really short strings, such as for JSON tags.
          _buffer.u8( _BRDT.tiny_str() + n.u8() )
      | let n: USize if n < 256 =>
          // Typical database fields, names, addresses, etc
          _buffer.u8( _BRDT.string() + 0)
          _buffer.u8( n.u8() )
      | let n: USize if n < 65536 =>
          // Largish chunks of text.
          _buffer.u8( _BRDT.string() + 1 )
          _buffer.u16_be( n.u16() )
    else
          _buffer.u8( _BRDT.string() + 2 )
          _buffer.u32_be( s.size().u32() )
    end
    _buffer.write( s.array() )

  fun ref _add_uint( value: (U8 | U16 | U32 | USize) ) =>
    """
    Add an unsigned integer to the record, encoded in as few bytes as
    possible.
    """
    match value.usize()
      | let n: USize if n < 16 =>
        _buffer.u8( _BRDT.tiny_uint() + n.u8() )
      | let n: USize if n < 256 =>
        _buffer.u8( _BRDT.uint() + 0)
        _buffer.u8( n.u8() )
      | let n: USize if n < 65536 =>
        _buffer.u8( _BRDT.uint() + 1 )
        _buffer.u16_be( n.u16() )
      else
        _buffer.u8( _BRDT.uint() + 2 )
        _buffer.u32_be( value.usize().u32() )
      end

  fun ref _add_blob( value: ByteSeq ) =>
    """
    Add unstructured binary data, up to 2^32-1 bytes
    """
    let n = value.size()
    if n < 256 then
      _buffer.u8( _BRDT.blob()+0 )
      _buffer.u8( n.u8() )
    elseif n < 65536 then
      _buffer.u8( _BRDT.blob()+1 )
      _buffer.u16_be( n.u16() )
    else
      _buffer.u8( _BRDT.blob()+2 )
      _buffer.u32_be( n.u32() )
    end
    _buffer.write( value )

/*
  fun ref _add_map[K: (BinType & Hashable #read & Equatable[K] #read),
                  V: (BinType #read)]( m: Map[K,V] ) =>
    """
    Add a Map, consisting of pairs of values.  This is a generic function.
    """
    let n = m.size()
    if n < 256 then
      _buffer.u8( _BRDT.map()+1 )
      _buffer.u8( n.u8() )
    elseif n < 65536 then
      _buffer.u8( _BRDT.map()+2 )
      _buffer.u16_be( n.u16() )
    end

    for (k,v) in m.pairs() do
      add( k )
      add( v )
    end
*/

class BinRecReader
  """
  Extract values from a binary record.
  """
  var _buffer: Reader = Reader

  fun ref append( value: Array[U8] val ) =>
    """
    Add some bytes to the record to be decoded.  It is done this way because
    network and file operations sometimes deliver data in chunks.
    """
    _buffer.append( value )

  fun ref size(): USize => _buffer.size()

  fun ref next(): BinType ? =>
    """
    Fetch the next value in a record.  It can be any of the supported types.
    The high-order 4 bits of the tag byte indicate the general data type.
    The low-order 4 bits supply additional information.
    """
    let dtag = _buffer.u8()
    let high = (dtag and 0xF0).u8()
    let low =  (dtag and 0x0F).usize()

    match high
    | _BRDT.none() => None

    | _BRDT.tiny_uint() =>
       // Very small unsigned int in the low 4 bits.
       return low

    | _BRDT.uint() =>
       // Low 4 bits say how many bytes in the value of an unsigned int.
       match low
       | 0 => return _buffer.u8().usize()
       | 1 => return _buffer.u16_be().usize()
       | 2 => return _buffer.u32_be().usize()
       | 3 => return _buffer.u64_be().usize()
       end

   | _BRDT.tiny_str() =>
       // Low 4 bits tell how many bytes in a short string.
       let len   = low.usize()
       let value = _buffer.block(len)
       String.from_array( consume value )

    | _BRDT.string() =>
       // Low 4 bits tell how many bytes in the length of the string.
       let len = match low
         | 0 => _buffer.u8().usize()
         | 1 => _buffer.u16_be().usize()
         | 2 => _buffer.u32_be().usize()
         else 0
       end
       let value = _buffer.block(len)
       String.from_array( consume value )

    | _BRDT.blob() =>
       // Low 4 bits tell how many bytes in the length of the binary blob.
       let len = match low
         | 0 => _buffer.u8().usize()
         | 1 => _buffer.u16_be().usize()
         | 2 => _buffer.u32_be().usize()
         else 0
       end
       _buffer.block(len)
   end

  fun ref has_next(): Bool =>
    _buffer.size() > 0

  fun ref values( limit: (USize | None) = None): BRValueIterator =>
    """
    Return an iterator over single values.
    """
    BRValueIterator.create( this, limit )

  fun ref pairs( limit: (USize | None) = None): BRPairIterator =>
    """
    Return an iterator over pairs of values, as for a Map or Tagged record.
    """
    BRPairIterator.create( this, limit )

class BRValueIterator is Iterator[BinType]
  """
  An iterator for fetching single values, or elements of an Array.
  """
  let _base: BinRecReader
  var _limit: (USize | None)

  new create( base': BinRecReader, limit': (USize | None) = None ) =>
    _base = base'
    _limit = limit'

  fun ref has_next(): Bool =>
    """
    Test if there are more terms.  If a limit was specified, it has to
    be positive.  If not, there have to be bytes remaining.
    """
    match _limit
      | let n: USize => (n > 0)
      | None => _base.has_next()
      else false
    end

  fun ref next(): BinType ? =>
    // Decrement term limit if there is one.  This is used when decoding
    // 'array' terms.
    match _limit
    | let n: USize => _limit = n - 1
    end
    _base.next()

class BRPairIterator is Iterator[(BinType,BinType)]
  """
  An iterator for fetching pairs of values, or elements of a Map.
  """
  let _base: BinRecReader
  var _limit: (USize | None)

  new create( base': BinRecReader, limit': (USize | None) = None ) =>
    _base = base'
    _limit = limit'

  fun ref has_next(): Bool =>
    """
    Test if there are more pairs.  If a limit was specified, it has to
    be positive.  If not, there have to be bytes remaining.
    """
    match _limit
      | None => _base.has_next()
      | let n: USize => (n > 0)
      else false
    end

  fun ref next(): (BinType,BinType) ? =>
    // Decrement pair limit if there is one.  This is used when decoding
    // 'map' terms.
    match _limit
    | let n: USize => _limit = n - 1
    end
    let key = _base.next()
    let value = _base.next()
    (key, value)
