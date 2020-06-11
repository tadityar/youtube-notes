module GraphQL.Enum.Notes_select_column exposing
    ( Notes_select_column(..)
    , decoder
    , encode
    , fromString
    , toString
    )

import Json.Decode
import Json.Encode


type Notes_select_column
    = Id
    | Is_dark_mode
    | Notes
    | Title


encode : Notes_select_column -> Json.Encode.Value
encode value =
    Json.Encode.string (toString value)


decoder : Json.Decode.Decoder Notes_select_column
decoder =
    Json.Decode.string
        |> Json.Decode.andThen
            (\value ->
                value
                    |> fromString
                    |> Maybe.map Json.Decode.succeed
                    |> Maybe.withDefault
                        (Json.Decode.fail <| "unknown Notes_select_column " ++ value)
            )


toString : Notes_select_column -> String
toString value =
    case value of
        Id ->
            "id"

        Is_dark_mode ->
            "is_dark_mode"

        Notes ->
            "notes"

        Title ->
            "title"


fromString : String -> Maybe Notes_select_column
fromString value =
    case value of
        "id" ->
            Just Id

        "is_dark_mode" ->
            Just Is_dark_mode

        "notes" ->
            Just Notes

        "title" ->
            Just Title

        _ ->
            Nothing
