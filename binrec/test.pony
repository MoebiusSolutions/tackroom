actor Main
  let env: Env
  let b1: BinRecWriter = BinRecWriter
  let b2: BinRecReader = BinRecReader

  new create( env': Env ) =>
    env = env'
    // Test reading.
    env.input( HaveInput.create( this ) )

  be input( data: Array[U8] iso ) =>
    env.err.print("Have " + data.size().string() + " bytes" )
    b2.append( consume data )

  be eof() =>
    """
    If stdin supplied some data, decode it to stdout.
    If stdin supplied no data, then generate some to stdout.
    """
    if b2.size() > 1 then
      env.err.print("Have all data")
      for value in b2.values() do
        match value
          | None => env.err.print( "  None" )
          | let n: USize => env.err.print( "  N " + n.string() )
          | let s: String => env.err.print( "  S " + s )
          | let b: ByteSeq => env.err.print( "  B ("+b.size().string()+")" )
        end
      end
    else
      // Test writing.
      b1.add_pair( U8(1), "foo" )
      b1.add( "Apples" )
      b1.add( U16(200) )
      let bytes: Array[U8] val = recover val [1,2,3,4,5,6,7,8] end
      b1.add( bytes )
      b1.add( U32(5000) )
      b1.add( "A reasonably long string" )
      // Dump it to stdout
      env.out.writev( b1.data() )
    end

      
class HaveInput is StdinNotify
  """
  Handle events from reading stdin.
  """
  let _parent: Main
  
  new iso create( parent': Main tag ) =>
    _parent = parent'

  fun ref apply( data: Array[U8] iso ) =>
    _parent.input( consume data )    

  fun ref dispose() =>
    _parent.eof()
    
