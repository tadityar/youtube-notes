module Route exposing (..)

import Url
import Url.Parser as Parser exposing ((</>), Parser, map, oneOf, s, string)


type Route
    = Create
    | Note String
    | Homepage
    | NotFound


parser : Parser (Route -> a) a
parser =
    oneOf
        [ map Homepage Parser.top
        , map Create (s "create")
        , map Note (s "note" </> string)
        ]


fromUrl : Url.Url -> Route
fromUrl url =
    url
        |> Parser.parse parser
        |> Maybe.withDefault NotFound


toString : Route -> String
toString route =
    case route of
        Create ->
            "/create"

        Note string ->
            "/note/" ++ string

        Homepage ->
            "/"

        NotFound ->
            "/notfound"
