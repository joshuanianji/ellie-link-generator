# Ellie Link Generator

A simple headless Elm program that generates an ellie link given the source code of an Elm file. The installed packages are the default Elm packages as well as elm-antd.

The files which we will encode with a URL is in the (/test_files)[test_files/] folder. 

## Execute

To compile the `Main.elm` file into `elm.js`, run `make` or `elm make src/Main.elm --output="src/elm.js"`

To run the program with a file, execute `node src/main.js PATH_TO_FILE.elm` in the terminal. 
`make run` has the file defaulted to the HelloWorld.elm, but you can change that if you want.