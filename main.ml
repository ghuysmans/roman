(** Simple command line tool to convert roman numerals to integers
*)

exception Error of string
let error fmt = Printf.ksprintf (fun msg -> raise (Error msg)) fmt

let integer str =
    try int_of_string str
    with Failure _ -> error "not an integer: %s" str

let usage () =
    List.iter prerr_endline
    [ "usage: roman mmxv        convert mmxv to integer"
    ; "       roman 123         convert 123 to roman"
    ; ""
    ; "(c) 2015 Christian Lindig <lindig@gmail.com>"
    ; "https://github.com/lindig/roman"
    ]

(** [main] function - handles command line arguments and exit codes *)
let main () =
   let argv = Array.to_list Sys.argv in
   let args = List.tl argv in
   match args with
   |  "-h"::_  -> (usage (); exit 0)
   | [str]     -> ( ( match Roman.scan str with
                    | Roman.Decimal(d) ->
                        Printf.printf "%s\n" @@ Roman.as_roman d
                    | Roman.Roman(r) ->
                        Printf.printf "%d\n" @@ Roman.from_roman r
                    )
                  ; exit 0
                  )
   | _         -> ( usage ()
                  ; exit 1
                  )

let () =
    try main () with
    | Roman.Error msg -> Printf.eprintf "%s\n" msg; exit 1
