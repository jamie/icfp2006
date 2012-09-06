class Um

  OPERATORS = [
    :conditional_move, :array_index, :array_amendment,
    :addition, :multiplication, :division, :not_and,
    :halt,
    :allocation, :abandonment,
    :output, :input,
    :load_program,
    :orthography
  ]

  attr_accessor :array, :register, :finger, :key

  def initialize(program, key = "")
    @array = []
    @register = [0] * 8
    @finger = 0
    @key = key.split("")

    @array[0] = program
  end

  def spin(stopchar = nil)
    @executions = 0
    loop do
      platter = @array[0][@finger]
      @finger += 1
      @executions += 1

      opcode = (platter >> 28) & 0xF
      if opcode != 13
        @a = (platter >> 6) & 7
        @b = (platter >> 3) & 7
        @c = (platter     ) & 7
      else
        @z = (platter >> 25) & 7
        @value = platter & 0x01FFFFFF
      end

      if @executions == 962
        p [opcode, @register[@a], @register[@b], @register[@c]]
        p @array[4].size
        break
      end

      self.send(OPERATORS[opcode])
    end
  end



  def conditional_move
    # $a = $b unless $c.zero?
    return if @register[@c].zero?
    @register[@a] = @register[@b]
  end

  def array_index
    # $a = $b[$c]
    @register[@a] = @array[@register[@b]][@register[@c]]
  end

  def array_amendment
    # $a[$b] = $c
    @array[@register[@a]][@register[@b]] = @register[@c]
  end

  def addition
    # $a = $b + $c
    @register[@a] = (@register[@b] + @register[@c]) % 2**32
  end

  def multiplication
    # $a = $b * $c
    @register[@a] = (@register[@b] * @register[@c]) % 2**32
  end

  def division
    # $a = $b / $c
    @register[@a] = (@register[@b] / @register[@c]) % 2**32
  end

  def not_and
    # $a = !$b & !$c
    @register[@a] = 0xFFFFFFFF - (@register[@b] & @register[@c])
  end

  def halt
    # exit
    puts
    exit(0)
  end

  def allocation
    # $b = ([0] * $c).index
    index = @array.length # empty_array_index
    puts "#{index} <- #{@register[@c]}"
    @array[index] = [0] * @register[@c]
    @register[@b] = index
  end

  def abandonment
    # $c = nil
    @array[@register[@c]] = nil
  end

  def output
    # puts $c
    char = @register[@c].chr
    STDERR.print char
    STDERR.flush
    @last_output = char
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
    @array[0] = @array[@register[@b]].dup unless @register[@b].zero?
    @finger = @register[@c]
  end

  def orthography
    # $z = value
    @register[@z] = @value
  end

  def dump
    STDERR.puts
    STDERR.puts "#{@executions} iterations."

    puts Marshal.dump(self)

    exit(0)
  end

end

if $0 == __FILE__
  Um.new(File.read(ARGV[0] || 'sandmark.umz').unpack("N*")).spin
end

