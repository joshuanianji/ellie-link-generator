port module Main exposing (main)

import EllieUrlGenerator exposing (fromSourceCode)


main : Program Flags () msg
main =
    Platform.worker
        { init = init
        , update = \_ model -> ( model, Cmd.none )
        , subscriptions = always Sub.none
        }



-- Data


type alias Flags =
    String



-- Ports


port sendLink : String -> Cmd msg



-- init


init : Flags -> ( (), Cmd msg )
init fileContents =
    ( (), sendLink <| fromSourceCode "5.0.0" fileContents )
