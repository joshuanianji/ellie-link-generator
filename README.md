# Ellie Link Generator

A simple headless Elm program that generates an ellie link given the source code of an Elm file. The installed packages are the default Elm packages with elm-antd.

The files which we can encode with a URL is in the `test_files/` folder. 

## Compile

To compile the `Main.elm` file into `elm.js`, run 
```bash 
make
``` 
or 
```bash
elm make src/Main.elm --output="src/elm.js"
```

## Execute
To run the program with a file, executing
```bash 
make run 
```
in the terminal defaults to `HelloWorld.elm`.
```bash 
node src/main.js PATH_TO_FILE.elm
``` 
allows you to run any file (given it's an Elm file) through the program.


## Caveats

This program makes a lot of assumptions, especially the fact that the Elm code will be compatible with Ellie straight off the bat. The module name will HAVE to be in the form:
```elm
module Main exposing (main)
```
or else the Ellie program will result in a bunch of errors.

Using `elm/parser` might be a viable solution but it might take a while.