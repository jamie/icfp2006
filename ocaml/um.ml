
module M = struct
	external alloc : int32 -> int32 = "icfp_alloc"
	external free : int32 -> unit = "icfp_free"
	external get : int32 -> int32 -> int32 = "icfp_get"
	external set : int32 -> int32 -> int32 -> unit = "icfp_set"
	external copy : int32 -> int32 = "icfp_copy"
end

external udiv : int32 -> int32 -> int32 = "icfp_udiv"
external nand : int32 -> int32 -> int32 = "icfp_nand"

open Int32

exception Halt_machine

type operands = (int * int * int)
type operands_special = (int * int)

type operator =
	| Cond_move of operands
	| Array_index of operands
	| Array_amend of operands
	| Add of operands
	| Mul of operands
	| Div of operands
	| Not_and of operands
	| Halt of operands
	| Alloc of operands
	| Free of operands
	| Output of operands
	| Input of operands
	| Load of operands
	| Orth of operands_special

let operands t =
	let t = to_int t in
	((t asr 6) land 0x7, (t asr 3) land 0x7, t land 0x7)

let operands_special t =
	let t = to_int t in
	((t asr 25) land 0x7, t land 0x1FF_FFFF)

let decode t =
	let ops = operands t in
	let ops' = operands_special t in
	match to_int (shift_right_logical t 28) with
		| 0 -> Cond_move ops
		| 1 -> Array_index ops
		| 2 -> Array_amend ops
		| 3 -> Add ops
		| 4 -> Mul ops
		| 5 -> Div ops
		| 6 -> Not_and ops
		| 7 -> Halt ops
		| 8 -> Alloc ops
		| 9 -> Free ops
		| 10 -> Output ops
		| 11 -> Input ops
		| 12 -> Load ops
		| 13 -> Orth ops'
		| op -> failwith "invalid op"

type state = {
		registers: int32 array;
		mutable zeroth: int32;
		mutable pc: int32;
	}

let initial filename =
	let ic = open_in_bin filename in
	let len = in_channel_length ic in
	let block = M.alloc (of_int (len / 4)) in
	for i = 0 to len / 4 - 1 do
		let a = int_of_char (input_char ic) in
		let b = int_of_char (input_char ic) in
		let c = int_of_char (input_char ic) in
		let d = int_of_char (input_char ic) in
		let v = logor (shift_left (of_int a) 24) (of_int ((b lsl 16) lor (c lsl 8) lor d)) in
		M.set block (of_int i) v;
	done;
	close_in ic;
	{
		registers = Array.init 8 (fun x -> zero);
		zeroth = block;
		pc = zero;
	}

let get_char =
	let buf = ref ""
	and pos = ref 1
	in let rec get_char () =
		if !pos < String.length !buf then
			( incr pos; !buf.[!pos - 1] )
		else if !pos = String.length !buf then
			( incr pos; '\n' )
		else
			( buf := read_line (); pos := 0; get_char () )
	in get_char

let state = initial Sys.argv.(1)

let get n = state.registers.(n)

let set n v = state.registers.(n) <- v

let () = try
	let rec step () =
		let instr = decode (M.get state.zeroth state.pc) in
		state.pc <- add state.pc one;
	begin
		match instr with
		| Cond_move (a,b,c) -> if get c <> zero then set a (get b)
		| Array_index (a,b,c) -> (match get b with
			| 0l -> set a (M.get state.zeroth (get c))
			| n -> set a (M.get n (get c))
			)
		| Array_amend (a,b,c) -> (match get a with
			| 0l -> M.set state.zeroth (get b) (get c)
			| n -> M.set n (get b) (get c)
			)
		| Add (a,b,c) -> set a (add (get b) (get c))
		| Mul (a,b,c) -> set a (mul (get b) (get c))
		| Div (a,b,c) -> set a (udiv (get b) (get c))
		| Not_and (a,b,c) -> set a (nand (get b) (get c))
		| Halt _ -> raise Halt_machine
		| Alloc (_,b,c) ->
			if get c <> zero then
				set b (M.alloc (get c))
			else set b (sub zero one);
		| Free (_,_,c) ->
			if get c <> (sub zero one) then
				M.free (get c)
		| Output (_,_,c) ->
			print_char (char_of_int (to_int (get c) land 0xFF)); flush stdout
		| Input (_,_,c) ->
			set c (of_int (int_of_char (get_char ())))
		| Load (_,b,c) ->
			if get b <> zero then
				(
				M.free state.zeroth;
				state.zeroth <- M.copy (get b);
				);
			state.pc <- get c
		| Orth (a,b) -> set a (of_int b)
	end;
		step ()
	in step ()
	with
		| Halt_machine -> ()
		| exn -> print_endline (Printexc.to_string exn)
