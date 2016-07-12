defmodule Um do
  def spin(program) do
    # array    = [program]
    # register = Array.new(8, 0_u32)
    # finger   = 0_u32
    # platter  = 0_u32

    # loop do
    #   platter = array[0][finger]
    #   finger += 1

    #   opcode = (platter >> 28) & 0xF

    #   a = register[(platter >> 6) & 7]
    #   b = register[(platter >> 3) & 7]
    #   c = register[platter & 7]

      #   # Optimize these first few by calling frequency

      # when 13; register[(platter >> 25) & 7] = platter & 0x01FFFFFF
      # when  3; register[(platter >> 6) & 7] = (b.to_u64 + c.to_u64).to_u32
      # when  6; register[(platter >> 6) & 7] = (0xFFFFFFFF - (b & c)).to_u32
      # when 12; array[0] = array[b].dup unless b == 0
      #          finger = c
      # when  2; array[a][b] = c

      # when  4; register[(platter >> 6) & 7] = (b.to_u64 * c.to_u64).to_u32
      # when  5; register[(platter >> 6) & 7] = (b.to_u64 / c.to_u64).to_u32
      # when  7; puts
      #          exit(0)
      # when  8; index = array.size.to_u32
      #          array << Array.new(c.to_i32, 0_u32)
      #          register[(platter >> 3) & 7] = val = index
      # when  9; array[c] = [] of UInt32
      # when 10; print c.chr # STDOUT.flush ?
      # # when 11; input
#     end
  end

  defp exec(0) do
    # when  0; register[(platter >> 6) & 7] = b unless c == 0
  end

  defp exec(1) do
    # when  1; register[(platter >> 6) & 7] = array[b][c] as UInt32
  end

  # ...
end

# def input
#   # TODO: Port this from ruby
#   # $c = getc
#   char = key.length > 0 ?
#     key.shift[0] :
#     STDIN.getc
#   register[platter & 7] = (char == 10 ? 0xFFFFFFFF : char)
# end

case System.argv do
  [f | _] -> f
  _       -> "../sandmark.umz"
end
  |> File.read!
  |> Um.spin
