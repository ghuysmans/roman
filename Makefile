all:
	dune build

test:
	dune runtest

clean:
	dune clean

install:
	dune build @install
	dune install
