extern crate byteorder;

use std::mem;
use std::error::Error;
use std::io::prelude::*;
use std::fs::File;

use std::path::Path;

struct Um {
    array: Vec<Vec<u32>>,
    register: Vec<u32>,
    finger: usize,
}

fn load_file(filename: &str) -> Vec<u32> {
    let mut platter: Vec<u32> = vec![];

    // Open file
    let path = Path::new(filename);
    let display = path.display();
    let mut file = match File::open(&path) {
        Err(why) => panic!("couldn't open {}: {}", display, Error::description(&why)),
        Ok(file) => file,
    };

    // Read bytes from file
    let mut bytes: Vec<u8> = Vec::new();
    file.read_to_end(&mut bytes).unwrap();

    // Convert chunks of bytes into u32s
    for word in bytes.chunks(4) {
        unsafe {
            let a = [word[3], word[2], word[1], word[0]];
            let val = mem::transmute::<[u8; 4], u32>(a);
            platter.push(val);
        }
    }

    return platter;
}

fn main() {
//     args := os.Args
//     if len(args) < 2 {
//         fmt.Println("Please specify virtual machine to run")
//         os.Exit(1)
//     }

    let mut machine = Um {
        array: vec![],
        register: vec![0; 8],
        finger: 0,
    };

    let program = load_file("../sandmark.umz");
    machine.array.push(program);

    loop {
        let platter = machine.array[0][machine.finger];
        machine.finger = machine.finger + 1;

        let opcode = (platter >> 28) & 0xF;

        let a = ((platter >> 6) & 7) as usize;
        let b = ((platter >> 3) & 7) as usize;
        let c = (platter & 7) as usize;

        let z = ((platter >> 25) & 7) as usize;
        let value = platter & 0x01FFFFFF;

        let i = machine.register[a] as usize;
        let j = machine.register[b] as usize;
        let k = machine.register[c] as usize;

        match opcode {
            // 0 conditional move // $a = $b unless $c.zero?
            0 => { if machine.register[c] == 0 {} else { machine.register[a] = machine.register[b] } },
            // 1 array index // $a = $b[$c]
            1 => { machine.register[a] = machine.array[j][k]; },
            // 2 array amendment // $a[$b] = $c
            2 => { machine.array[i][j] = machine.register[c]; },
            // 3 addition // $a = $b + $c
            3 => {
                let j = machine.register[b] as u64;
                let k = machine.register[c] as u64;
                machine.register[a] = ((j + k) % 0x100000000) as u32;
            },
            // 4 multiplication // $a = $b * $c
            4 => {
                let j = machine.register[b] as u64;
                let k = machine.register[c] as u64;
                machine.register[a] = ((j * k) % 0x100000000) as u32;
            },
            // 5 division // $a = $b / $c
            5 => {
                let j = machine.register[b] as u64;
                let k = machine.register[c] as u64;
                machine.register[a] = ((j / k) % 0x100000000) as u32;
            },
            // 6 not and // $a = !$b & !$c
            6 => { machine.register[a] = 0xffffffff - (machine.register[b] & machine.register[c]) },
            // 7 halt
            7 => { println!(""); break }
            // 8 allocation // $b = ([0] * $c).index
            8 => {
                machine.register[b] = machine.array.len() as u32;
                machine.array.push(vec![0; k]);
            }
            // 9 abandonment // $c = nil
            9 => { machine.array[k] = vec![]; }
            // 10 output // puts $c
            10=> {
                let chr = match std::char::from_u32(machine.register[c]) {
                    Some(ch) => ch,
                    None => ' ',
                };
                print!("{}", chr);
            },
            // 11 input // $c = getc
            // TODO
            // 12 load program // $0 = $b.dup; @finger = $c
            12=> {
                if j == 0 {} else {
                    machine.array[0] = machine.array[j].clone();
                }
                machine.finger = k;
            },
            // 13 orthography // $z = value
            13=> { machine.register[z] = value },
            _ => panic!("Unknown opcode: {}", opcode),
        }
    }
}
