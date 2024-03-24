{
    (**
    Command line tool to convert roman numerals to decimal. For the
    syntax of roman numerals see Wikipedia. This tool implements
    the subtraction rule, for example:

    ix = 9
    cm = 900
    cd = 400

    (c) 2015 Christian Lindig <lindig@gmail.com>. This is licensed
    under the BSD 2-clause license.
    *)

    exception Error of string
    let error fmt = Printf.ksprintf (fun msg -> raise (Error msg)) fmt

    type number =
        | Roman     of string
        | Decimal   of int

    let concat digits = String.concat "" @@ List.rev digits

    let rec roman' digits = function
    | n when n >= 4000 -> error "can't represent %d as a roman' numeral" n
    | n when n >= 1000 -> roman' ("m"  :: digits) (n-1000)
    | n when n >=  900 -> roman' ("cm" :: digits) (n-900)
    | n when n >=  500 -> roman' ("d"  :: digits) (n-500)
    | n when n >=  400 -> roman' ("cd" :: digits) (n-400)
    | n when n >=  100 -> roman' ("c"  :: digits) (n-100)
    | n when n >=   90 -> roman' ("xc" :: digits) (n-90)
    | n when n >=   50 -> roman' ("l"  :: digits) (n-50)
    | n when n >=   40 -> roman' ("xl" :: digits) (n-40)
    | n when n >=   10 -> roman' ("x"  :: digits) (n-10)
    | n when n  =    9 -> roman' ("ix" :: digits) (n-9)
    | n when n >=    5 -> roman' ("v"  :: digits) (n-5)
    | n when n  =    4 -> roman' ("iv" :: digits) (n-4)
    | n when n >=    1 -> roman' ("i"  :: digits) (n-1)
    | 0                -> concat digits
    | n                -> error "can't represent %d as a roman' numeral" n

    let as_roman n = roman' [] n

}

let decimal = ['0'-'9']+
let roman   =
    ( "M" | "MM" | "MMM" )? (* could use "M"* to avoid limit *)
    ( "D"? ( "C" | "CC" | "CCC" )? | "CD" | "CM" )?
    ( "L"? ( "X" | "XX" | "XXX" )? | "XL" | "XC" )?
    ( "V"? ( "I" | "II" | "III" )? | "IV" | "IX" )?


rule syntax = parse (* check syntax *)
    roman eof { true }

and digit = parse (* return value of roman digit *)
    | "M"       { 1000 }
    | "CM"      { 900  }
    | "D"       { 500  }
    | "CD"      { 400  }
    | "C"       { 100  }
    | "XC"      { 90   }
    | "L"       { 50   }
    | "XL"      { 40   }
    | "X"       { 10   }
    | "IX"      { 9    }
    | "V"       { 5    }
    | "IV"      { 4    }
    | "I"       { 1    }
    | eof       { 0    }
    | _         { error "not a roman digit: %s" @@ Lexing.lexeme lexbuf }

and number = parse
    | (roman    as r) eof         { Roman(r)                  }
    | (decimal  as d) eof         { Decimal(int_of_string d)  }
    | _
        { error "neither roman nor decimal: %s" @@ Lexing.lexeme lexbuf }

{

(** [is_wellformed str] is true, iff [str] is a roman numeral.
    [is_wellformed] is case insensitive. *)
let is_wellformed str =
    try  syntax @@ Lexing.from_string str
    with Failure _ -> false

(** [roman str] computes the integer value of roman numeral [str]. An
    empty string has value zero. [scan] assumes that [str] has the correct
    syntax and does not check for it. *)
let roman str =
    let state = Lexing.from_string str in
    let rec loop sum = match digit state with
        | 0 -> sum
        | n -> loop (sum + n)
    in
        loop 0

(** [from_roman] returns integer value of roman numeral [str]. The function
    is case insensitive and validates the syntax of [str]. In case of an
    error it raises [Error msg]. *)
let from_roman str =
    let str = String.uppercase_ascii str in
    if is_wellformed str
    then roman str
    else error "not a roman numeral: %s" str

let scan str = number @@ Lexing.from_string @@ String.uppercase_ascii str


let%test _ =
    let syntax =
        [ "xxxx"
        ; "im"
        ; "abc"
        ; "xcc"
        ; "ic"
        ; "imm"
        ; "mxm"
        ; "viiii"
        ; "ivi"
        ]
    in
    let fail str =
        try
            ( from_roman str |> ignore
            ; false
            )
        with
            Error _ -> true
    in
    let idem i =
        let r  = as_roman i  in
        let i' = from_roman r  in
        let r' = as_roman i' in
        r = r' && i = i'
    in
    let rec loop = function
        | 0 -> true
        | n -> idem n && loop (n-1)
    in
    loop 3999 && List.for_all fail syntax


}
