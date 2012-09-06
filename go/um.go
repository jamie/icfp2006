package main

import (
	"bufio"
	"encoding/binary"
	"fmt"
	"io/ioutil"
	"os"
)

func load_file(filename string) []uint32 {
	file, err := os.Open(filename)
	if err != nil {
		panic(err)
	}
	defer file.Close()
	reader := bufio.NewReader(file)

	// This is a terrible way to get the right size array, I'm sure
	tmpstr, tmperr := ioutil.ReadFile(filename)
	if tmperr != nil {
		panic(tmperr)
	}
	size := len(tmpstr) / 4

	data := make([]uint32, size)
	err2 := binary.Read(reader, binary.BigEndian, &data)
	if err2 != nil {
		panic(err)
	}

	return data
}

type Um struct {
	array    [][]uint32
	register []uint32
	finger   uint32
	key      byte
}

func main() {
	args := os.Args
	if len(args) < 2 {
		fmt.Println("Please specify virtual machine to run")
		os.Exit(1)
	}

	machine := new(Um)
	machine.array = make([][]uint32, 1)
	machine.array[0] = load_file(args[1]) // load initial program
	machine.register = make([]uint32, 8)

	for {
		platter := machine.array[0][machine.finger]
		machine.finger = machine.finger + 1

		opcode := (platter >> 28) & 0xF
		if opcode == 7 { break }

		if opcode != 13 {
			a := (platter >> 6) & 7
			b := (platter >> 3) & 7
			c := platter & 7
			operators[opcode](machine, a, b, c)
		} else {
			z := (platter >> 25) & 7
			value := platter & 0x01FFFFFF
			operators[opcode](machine, z, 0, value)
		}
	}
}

var operators = [14]func(*Um, uint32, uint32, uint32){
	// 0 conditional move // $a = $b unless $c.zero?
	func(m *Um, a, b, c uint32) {
		if m.register[c] != 0 {
			m.register[a] = m.register[b]
		}
	},

	// 1 array index // $a = $b[$c]
	func(m *Um, a, b, c uint32) { m.register[a] = m.array[m.register[b]][m.register[c]] },

	// 2 array amendment // $a[$b] = $c
	func(m *Um, a, b, c uint32) { m.array[m.register[a]][m.register[b]] = m.register[c] },

	// 3 addition // $a = $b + $c
	func(m *Um, a, b, c uint32) { m.register[a] = m.register[b] + m.register[c] },

	// 4 multiplication // $a = $b * $c
	func(m *Um, a, b, c uint32) { m.register[a] = m.register[b] * m.register[c] },

	// 5 division // $a = $b / $c
	func(m *Um, a, b, c uint32) { m.register[a] = m.register[b] / m.register[c] },

	// 6 not and // $a = !$b & !$c
	func(m *Um, a, b, c uint32) { m.register[a] = 0xFFFFFFFF - (m.register[b] & m.register[c]) },

	// 7 halt
	func(m *Um, a, b, c uint32) { panic("halt") },

	// 8 allocation // $b = ([0] * $c).index
	func(m *Um, a, b, c uint32) {
		new_array := make([]uint32, m.register[c])
		m.register[b] = uint32(len(m.array))
		m.array = append(m.array, new_array)
	},

	// 9 abandonment // $c = nil
	func(m *Um, a, b, c uint32) { m.array[m.register[c]] = nil },

	// 10 output // puts $c
	func(m *Um, a, b, c uint32) { fmt.Printf("%c", m.register[c]) },

	// 11 input // $c = getc
	//   def input
	//     // $c = getc
	//     char = @key.length > 0 ?
	//       @key.shift[0] :
	//       STDIN.getc
	//     @register[@c] = (char == 10 ? 0xFFFFFFFF : char)
	//   end
	func(m *Um, a, b, c uint32) {},

	// 12 load program // $0 = $b.dup; @finger = $c
	func(m *Um, a, b, c uint32) {
		if m.register[b] != 0 {
			dup := make([]uint32, len(m.array[m.register[b]]))
			copy(dup, m.array[m.register[b]])
			m.array[0] = dup
		}
		m.finger = m.register[c]
	},

	// 13 orthography // $z = value
	func(m *Um, z, _, value uint32) { m.register[z] = value },
}
