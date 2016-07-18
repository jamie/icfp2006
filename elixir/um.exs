use Bitwise

defmodule Um do
  defmodule Program do
    defstruct [
      platters: [],
      registers: [],
      finger: 0
    ]

    def load(binary) do
      words = words_from_binary(binary)
      %Um.Program{
        platters: [words],
        registers: %{0=>0, 1=>0, 2=>0, 3=>0, 4=>0, 5=>0, 6=>0, 7=>0},
        finger: 0
      }
    end

    def step(program) do
      %Program{program | finger: program.finger+1}
    end
    def step_to(program, target) do
      %Program{program | finger: target}
    end

    defp words_from_binary(words, list \\ {})
    defp words_from_binary(<<>>, list), do: list
    defp words_from_binary(<<word :: size(32), rest::binary>>, list) do
      bits = <<word :: size(32)>>
      list = Tuple.append(list, bits)
      words_from_binary(rest, list)
    end

    def opcode(program) do
      [platter | _] = program.platters
      elem(platter, program.finger)
    end

    def allocate(program, size, register) do
      platter = Tuple.duplicate(<<0,0,0,0>>, size)
      id = Enum.count(program.platters)
      %Program{program | platters: program.platters ++ [platter]} |> set_register(register, id)
    end

    def deallocate(program, platter_id) do
      %Program{program | platters: List.replace_at(program.platters, platter_id, nil)}
    end

    def read_platter(program, platter_id, word_id) do
      program.platters |> Enum.at(platter_id) |> elem(word_id)
    end

    def write_platter(program, platter_id, word_id, value) do
      platter = program.platters |> Enum.at(platter_id) |> put_elem(word_id, value)
      %Program{program | platters: List.replace_at(program.platters, platter_id, platter)}
    end

    def load_platter(program, platter_id) do
      platter = program.platters |> Enum.at(platter_id)
      %Program{program | platters: List.replace_at(program.platters, 0, platter)}
    end

    def set_register(program, register, value) do
      registers = %{program.registers | register => value}
      %Program{program | registers: registers}
    end
  end

  def spin(program) do
    opcode = program |> Program.opcode

    program |> Program.step
            |> exec(opcode)
            |> spin
  end

  # A <- B unless C.zero?
  defp exec(program, <<0::size(4), _::size(19), a::size(3), b::size(3), c::size(3)>>) do
    rb = program.registers[b]
    rc = program.registers[c]
    case rc do
      0 -> program
      _ -> program |> Program.set_register(a, rb)
    end
  end

  # A = platter[B][C]
  defp exec(program, <<1::size(4), _::size(19), a::size(3), b::size(3), c::size(3)>>) do
    rb = program.registers[b]
    rc = program.registers[c]
    <<value :: size(32)>> = Program.read_platter(program, rb, rc)
    program |> Program.set_register(a, value)
  end

  # platter[A][B] = C
  defp exec(program, <<2::size(4), _::size(19), a::size(3), b::size(3), c::size(3)>>) do
    ra = program.registers[a]
    rb = program.registers[b]
    value = <<program.registers[c] :: size(32)>>
    program |> Program.write_platter(ra, rb, value)
  end

  # A = (B + C)
  defp exec(program, <<3::size(4), _::size(19), a::size(3), b::size(3), c::size(3)>>) do
    rb = program.registers[b]
    rc = program.registers[c]
    program |> Program.set_register(a, clamp(rb+rc))
  end

  # A = (B * C)
  defp exec(program, <<4::size(4), _::size(19), a::size(3), b::size(3), c::size(3)>>) do
    rb = program.registers[b]
    rc = program.registers[c]
    program |> Program.set_register(a, clamp(rb*rc))
  end

  # A = (B / C)
  defp exec(program, <<5::size(4), _::size(19), a::size(3), b::size(3), c::size(3)>>) do
    rb = program.registers[b]
    rc = program.registers[c]
    program |> Program.set_register(a, div(rb, rc))
  end

  # A = B, C
  # --------
  # 1 = 0, _
  # 1 = _, 0
  # 0 = 1, 1
  #
  # A = NOT (B AND C)
  defp exec(program, <<6::size(4), _::size(19), a::size(3), b::size(3), c::size(3)>>) do
    rb = program.registers[b]
    rc = program.registers[c]
    <<nand :: size(32)>> = <<(~~~(rb &&& rc)) :: size(32)>>
    program |> Program.set_register(a, nand)
  end

  defp exec(_, <<7::size(4), _::size(19), _::size(3), _::size(3), _::size(3)>>) do
    IO.puts ""
    System.halt
  end

  # Allocate platter of C bytes, B contains platter ID
  defp exec(program, <<8::size(4), _::size(19), _::size(3), b::size(3), c::size(3)>>) do
    rc = program.registers[c]
    program |> Program.allocate(rc, b)
  end

  # Deallocate platter C
  defp exec(program, <<9::size(4), _::size(19), _::size(3), _::size(3), c::size(3)>>) do
    rc = program.registers[c]
    program |> Program.deallocate(rc)
  end

  # print C
  defp exec(program, <<10::size(4), _::size(19), _::size(3), _::size(3), c::size(3)>>) do
    rc = program.registers[c]
    IO.chardata_to_string([rc]) |> IO.write
    program
  end

  # Read 1 character of input, store byte in C
  # defp exec(program, <<11::size(4), _::size(19), a::size(3), b::size(3), c::size(3)>>) do
  #   program
  # end

  # Platter[0] = Platter[B], Finger = C
  defp exec(program, <<12::size(4), _::size(19), _::size(3), b::size(3), c::size(3)>>) do
    rb = program.registers[b]
    rc = program.registers[c]
    program |> Program.load_platter(rb) |> Program.step_to(rc)
  end

  # A <- val
  defp exec(program, <<13::size(4), a::size(3), val::size(25)>>) do
    program |> Program.set_register(a, val)
  end

  defp clamp(int) do
    if int >= 4294967296 do
      int - 4294967296
    else
      int
    end
  end
end

case System.argv do
  [f | _] -> f
  _       -> "../sandmark.umz"
end
  |> File.read!
  |> Um.Program.load
  |> Um.spin
