compile_elm:
	@echo "Compiling Elm"
	elm make src/Main.elm --output="src/elm.js"
	

run:
	@echo "running js"
	node src/main.js test_files/IconExample.elm