port module Main exposing (main)


main : Program Flags () msg
main =
    Platform.worker
        { init = init
        , update = \_ model -> ( model, Cmd.none )
        , subscriptions = always Sub.none
        }



-- Ports


port sendLink : String -> Cmd msg



-- Data


type alias Flags =
    String


type alias Package =
    { name : String
    , version : String
    }



-- harcoding the packages elm-antd will have to add in


packages : List Package
packages =
    [ Package "elm/browser" "1.0.2"
    , Package "elm/core" "1.0.5"
    , Package "elm/html" "1.0.0"
    , Package "supermacro/elm-antd" "4.2.3"
    ]


packageToString : Package -> String
packageToString p =
    p.name ++ "@" ++ p.version



-- Init (runs the program)


htmlCode : String
htmlCode =
    """
<html>
<head>
  <style>
    /* you can style your program here */
  </style>
</head>
<body>
  <main></main>
  <script>
    var app = Elm.Main.init({ node: document.querySelector('main') })
    // you can use ports and stuff here
  </script>
</body>
</html>
"""


init : Flags -> ( (), Cmd msg )
init fileContents =
    let
        titleUrl =
            encodeUrl "TITLEEEEE"

        elmCodeUrl =
            fileContents
                |> encodeUrl

        htmlCodeUrl =
            encodeUrl htmlCode

        packagesUrl =
            packages
                |> List.map (packageToString >> encodeUrl)
                |> List.map (\p -> "&packages=" ++ p)
                |> String.join ""

        link =
            "https://ellie-app.com/a/example/v1?title="
                ++ titleUrl
                ++ "&elmcode="
                ++ elmCodeUrl
                ++ "&htmlcode="
                ++ htmlCodeUrl
                ++ packagesUrl
                ++ "&elmversion=0.19.0"
    in
    ( (), sendLink link )



-- replacing every reserved URL character (from Wikipedia) using most likely the most inefficient way possible
-- reserved characters: ! * ' ( ) ; : @ & = + $ , / ? % # [ ]


encodeUrl : String -> String
encodeUrl =
    String.replace "%" "%25"
        >> String.replace "\n" "%0A"
        >> String.replace " " "%20"
        >> String.replace "\"" "%22"
        >> String.replace "!" "%21"
        >> String.replace "#" "%23"
        >> String.replace "$" "%24"
        >> String.replace "&" "%26"
        >> String.replace "'" "%27"
        >> String.replace "(" "%28"
        >> String.replace ")" "%29"
        >> String.replace "*" "%2A"
        >> String.replace "+" "%2B"
        >> String.replace "," "%2C"
        >> String.replace "/" "%2F"
        >> String.replace ":" "%3A"
        >> String.replace ";" "%3B"
        >> String.replace "=" "%3D"
        >> String.replace "?" "%3F"
        >> String.replace "@" "%40"
        >> String.replace "[" "%5B"
        >> String.replace "]" "%5D"
