module FileParser exposing (elliefy)

import Parser exposing ((|.), (|=), DeadEnd, Parser, Problem(..), Step(..))



-------------------
-- EXPORTS
-- Elliefy makes the code renderable in Ellie. WIP
-------------------


elliefy : String -> { title : String, code : String }
elliefy srcCode =
    let
        ast =
            Parser.run fileParser srcCode

        title =
            case ast of
                Ok file ->
                    getTitle file

                Err _ ->
                    "Parsing Failure"

        parsed =
            Result.map (changeModuleNameTo "Main") ast
                |> Result.map elliefyExports
                |> Result.map toString

        parsedSrcCode =
            case parsed of
                Err parserErr ->
                    -- elm code will literally just contain the error message if parsing fails
                    "Error! " ++ deadEndsToString parserErr

                Ok code ->
                    code
    in
    { title = title
    , code = parsedSrcCode
    }



-------------------
-- DATA
-------------------


type alias File =
    { moduleDeclaration : ModuleDeclaration
    , imports : String
    , codeBlocks : List CodeBlock
    }


type alias ModuleDeclaration =
    { name : String
    , exposes : List String
    }


type CodeBlock
    = TypeDef String
    | FunDef FunInfo


type alias FunInfo =
    { funName : String
    , typeAnnotation : String

    -- everything after the equals sign
    , val : String
    }



-------------------
-- PARSERS
-------------------


fileParser : Parser File
fileParser =
    Parser.succeed File
        |= moduleDeclaration
        |. spacesAndComments
        |= imports
        |. spacesAndComments
        |= codeBlocks


moduleDeclaration : Parser ModuleDeclaration
moduleDeclaration =
    let
        moduleName : Parser String
        moduleName =
            Parser.chompUntil " "
                |> Parser.getChompedString
    in
    Parser.succeed ModuleDeclaration
        |. Parser.keyword "module"
        |. Parser.spaces
        |= moduleName
        |. Parser.spaces
        |. Parser.keyword "exposing"
        |. Parser.spaces
        |= exposes



-- literally parses the big chonk of code
-- we don't need to manipulate imports so there's no need


imports : Parser String
imports =
    Parser.chompUntil "\n\n\n"
        |> Parser.getChompedString


codeBlocks : Parser (List CodeBlock)
codeBlocks =
    let
        importsHelper : List CodeBlock -> Parser (Step (List CodeBlock) (List CodeBlock))
        importsHelper revImports =
            Parser.oneOf
                [ Parser.succeed (\imp -> Loop (imp :: revImports))
                    |= Parser.oneOf [ parseType, parseFunction ]
                    |. Parser.spaces
                , Parser.succeed ()
                    |> Parser.map (\_ -> Done (List.reverse revImports))
                ]

        parseType : Parser CodeBlock
        parseType =
            Parser.keyword "type"
                |. Parser.chompUntilEndOr "\n\n\n"
                |> Parser.getChompedString
                |> Parser.map TypeDef

        parseFunction : Parser CodeBlock
        parseFunction =
            (Parser.getChompedString <| Parser.chompUntil " ")
                |> Parser.andThen
                    (\name ->
                        Parser.succeed (FunInfo name)
                            |= (Parser.getChompedString <| Parser.chompUntil "\n")
                            |. Parser.spaces
                            |. Parser.token name
                            |= (Parser.getChompedString <| Parser.chompUntilEndOr "\n\n\n")
                            |> Parser.map FunDef
                    )
    in
    Parser.loop [] importsHelper



-----------------------
-- HELPERS
-----------------------
-- parses stuff between (..)


exposes : Parser (List String)
exposes =
    let
        innerExposing : Parser (List String)
        innerExposing =
            Parser.chompUntil ")"
                |> Parser.getChompedString
                |> Parser.map (String.split "," >> List.map String.trim)
    in
    Parser.succeed identity
        |. Parser.token "("
        |= innerExposing
        |. Parser.token ")"


spacesAndComments : Parser ()
spacesAndComments =
    Parser.loop 0 <|
        ifProgress <|
            Parser.oneOf
                [ Parser.lineComment "--"
                , Parser.multiComment "{-" "-}" Parser.Nestable
                , Parser.spaces
                ]


ifProgress : Parser a -> Int -> Parser (Step Int ())
ifProgress parser offset =
    Parser.succeed identity
        |. parser
        |= Parser.getOffset
        |> Parser.map
            (\newOffset ->
                if offset == newOffset then
                    Done ()

                else
                    Loop newOffset
            )



-- copy and pasting YuichiMorita's PR since the elm/parser library hasn't implemented this yet :((


deadEndsToString : List DeadEnd -> String
deadEndsToString deadEnds =
    let
        deadEndToString : DeadEnd -> String
        deadEndToString deadEnd =
            let
                position : String
                position =
                    "row:" ++ String.fromInt deadEnd.row ++ " col:" ++ String.fromInt deadEnd.col ++ "\n"
            in
            case deadEnd.problem of
                Expecting str ->
                    "Expecting " ++ str ++ " at " ++ position

                ExpectingInt ->
                    "ExpectingInt at " ++ position

                ExpectingHex ->
                    "ExpectingHex at " ++ position

                ExpectingOctal ->
                    "ExpectingOctal at " ++ position

                ExpectingBinary ->
                    "ExpectingBinary at " ++ position

                ExpectingFloat ->
                    "ExpectingFloat at " ++ position

                ExpectingNumber ->
                    "ExpectingNumber at " ++ position

                ExpectingVariable ->
                    "ExpectingVariable at " ++ position

                ExpectingSymbol str ->
                    "ExpectingSymbol " ++ str ++ " at " ++ position

                ExpectingKeyword str ->
                    "ExpectingKeyword " ++ str ++ "at " ++ position

                ExpectingEnd ->
                    "ExpectingEnd at " ++ position

                UnexpectedChar ->
                    "UnexpectedChar at " ++ position

                Problem str ->
                    "ProblemString " ++ str ++ " at " ++ position

                BadRepeat ->
                    "BadRepeat at " ++ position
    in
    List.foldl (++) "" (List.map deadEndToString deadEnds)



-- for example, "Routes.AlertComponent.BasicExample" -> "BasicExample AlertComponent"
-- if parsing fails, it just return "bruh moment"


getTitle : File -> String
getTitle f =
    let
        splitName =
            String.split "." f.moduleDeclaration.name
                |> List.drop 1

        -- remove "Routes"
    in
    case splitName of
        [ component, name ] ->
            name ++ " - " ++ component

        _ ->
            "bruh moment"



-------------------
-- MANIPULATORS
-------------------


changeModuleNameTo : String -> File -> File
changeModuleNameTo newName file =
    let
        oldModuleDeclaration =
            file.moduleDeclaration

        newModuleDeclaration =
            { oldModuleDeclaration | name = newName }
    in
    { file | moduleDeclaration = newModuleDeclaration }



-- this only does one task so far
-- if the name is 'example', then change it to 'main


elliefyExports : File -> File
elliefyExports file =
    case file.moduleDeclaration.exposes of
        [ "example" ] ->
            let
                newExposes =
                    [ "main" ]

                mDeclaration =
                    file.moduleDeclaration

                newMDeclaration =
                    { mDeclaration | exposes = newExposes }

                -- rename instances of "example" to "main"
                newCodeBlocks =
                    file.codeBlocks
                        |> List.map
                            (\block ->
                                case block of
                                    FunDef funData ->
                                        if funData.funName == "example" then
                                            FunDef
                                                { funData | funName = "main" }

                                        else
                                            FunDef funData

                                    typeDef ->
                                        -- do not change type definitions
                                        typeDef
                            )
            in
            { file
                | moduleDeclaration = newMDeclaration
                , codeBlocks = newCodeBlocks
            }

        _ ->
            -- do nothing - yet!!
            file



-------------------
-- STRINGIFY
-------------------


toString : File -> String
toString file =
    let
        moduleDeclarationStr =
            "module "
                ++ file.moduleDeclaration.name
                ++ " exposing ("
                ++ String.join ", " file.moduleDeclaration.exposes
                ++ ")"

        importsStr =
            file.imports

        codeBlocksStr =
            List.map codeBlocksToString file.codeBlocks
                |> String.join "\n\n\n"
    in
    [ moduleDeclarationStr, importsStr, codeBlocksStr ]
        |> String.join "\n\n\n"


codeBlocksToString : CodeBlock -> String
codeBlocksToString block =
    case block of
        TypeDef val ->
            val

        FunDef { funName, typeAnnotation, val } ->
            funName ++ typeAnnotation ++ "\n" ++ funName ++ val



-------------------
-- TESTS
-------------------


closeableExample =
    Ok
        { codeBlocks =
            [ TypeDef "type alias Model =\n    { closeableAlerts : CloseableAlertStack Msg\n    }"
            , TypeDef "type Msg\n    = AlertMsg Alert.Msg"
            , FunDef
                { funName = "init"
                , typeAnnotation = " : Model"
                , val = " =\n    { closeableAlerts =\n        initAlertStack AlertMsg\n            [ alert \"Warning Text Warning Text Warning TextW arning Text Warning Text Warning TextWarning Text\"\n                |> withType Warning\n            , alert \"Normal alertNormal alertNormal alertNormal alertNormal alertNormal alert\"\n            , alert \"Error Text\"\n                |> withDescription \"Error Description Error Description Error Description Error Description Error Description Error Description\"\n                |> withType Error\n            ]\n    }"
                }
            , FunDef
                { funName = "update"
                , typeAnnotation = " : Msg -> Model -> ( Model, Cmd Msg )"
                , val = " msg model =\n    case msg of\n        AlertMsg alertMsg ->\n            let\n                ( alertModel, alertCmd ) =\n                    updateAlertStack AlertMsg alertMsg model.closeableAlerts\n            in\n            ( { closeableAlerts = alertModel }\n            , alertCmd\n            )"
                }
            , FunDef
                { funName = "view"
                , typeAnnotation = " : Model -> Html Msg"
                , val = " model =\n    div\n        [ style \"width\" \"100%\"\n        ]\n        [ stackToHtml model.closeableAlerts ]\n"
                }
            ]
        , imports = "import Ant.Alert as Alert\n    exposing\n        ( Alert\n        , AlertType(..)\n        , CloseableAlertStack\n        , alert\n        , initAlertStack\n        , stackToHtml\n        , toHtml\n        , updateAlertStack\n        , withDescription\n        , withType\n        )\nimport Ant.Space as Space exposing (space, withSize)\nimport Html exposing (Html, div)\nimport Html.Attributes exposing (style)"
        , moduleDeclaration =
            { exposes = [ "Model", "Msg", "init", "update", "view" ]
            , name = "Routes.AlertComponent.CloseableExample"
            }
        }
