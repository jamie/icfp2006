class Um
  def initialize(program, key = "")
    @array = [program]
    @register = Array.new(8, 0_u32)
    @finger = 0_u32
    @platter = 0_u32
    @key = key.split("")

    @a = @b = @c = @z = @value = 0_u32
  end

  def spin(stopchar = nil)
    loop do
      @platter = @array[0][@finger]
      @finger += 1

      if opcode != 13
        @a = (@platter >> 6) & 7
        @b = (@platter >> 3) & 7
        @c = (@platter     ) & 7
      else
        @z = (@platter >> 25) & 7
        @value = @platter & 0x01FFFFFF
      end

      case opcode
      when  0; conditional_move
      when  1; array_index
      when  2; array_amendment
      when  3; addition
      when  4; multiplication
      when  5; division
      when  6; not_and
      when  7; halt
      when  8; allocation
      when  9; abandonment
      when 10; output
      # when 11; input
      when 12; load_program
      when 13; orthography
      end
    end
  end

  def opcode
    (@platter >> 28) & 0xF
  end


  def conditional_move
    # $a = $b unless $c.zero?
    return if @register[@c] == 0
    @register[@a] = @register[@b]
  end

  def array_index
    # $a = $b[$c]
    a = @register[@a]
    b = @register[@b]
    c = @register[@c]
    @register[@a] = @array[b][c] as UInt32
  end

  def array_amendment
    # $a[$b] = $c
    a = @register[@a]
    b = @register[@b]
    c = @register[@c]
    @array[a][b] = c
  end

  def addition
    # $a = $b + $c
    b = @register[@b].to_u64
    c = @register[@c].to_u64
    @register[@a] = (b + c).to_u32
  end

  def multiplication
    # $a = $b * $c
    b = @register[@b].to_u64
    c = @register[@c].to_u64
    @register[@a] = (b * c).to_u32
  end

  def division
    # $a = $b / $c
    a = @register[@a]
    b = @register[@b].to_u64
    c = @register[@c].to_u64
    @register[@a] = (b / c).to_u32
  end

  def not_and
    # $a = !$b & !$c
    b = @register[@b]
    c = @register[@c]
    @register[@a] = (0xFFFFFFFF - (b & c)).to_u32
  end

  def halt
    # exit
    puts
    exit(0)
  end

  def allocation
    # $b = ([0] * $c).index
    c = @register[@c]
    index = @array.size
    @array << Array.new(c.to_i, 0_u32)
    @register[@b] = index.to_u32
  end

  def abandonment
    # $c = nil
    @array[@register[@c]] = [] of UInt32
  end

  def output
    # puts $c
    char = @register[@c].chr
    print char
    #STDOUT.flush
  end

  def input
    # $c = getc
    char = @key.length > 0 ?
      @key.shift[0] :
      STDIN.getc
    @register[@c] = (char == 10 ? 0xFFFFFFFF : char)
  end

  def load_program
    # $0 = $b.dup; @finger = $c
    b = @register[@b]
    @array[0] = @array[b].dup unless b == 0
    @finger = @register[@c]
  end

  def orthography
    # $z = value
    @register[@z] = @value
  end
end

filename = "sandmark.umz"
filename = ARGV[0] if ARGV.size > 0
data = [] of UInt32
File.open(filename, "rb") do |file|
  slice = Slice(UInt8).new(file.size.to_i)
  file.read(slice)
  (file.size/4).times do |w|
    a, b, c, d = slice[(w.to_i32 * 4), 4].map{|v| v.to_u32}
    data << ((a << 24) + (b << 16) + (c << 8) + d)
  end
end
Um.new(data).spin
