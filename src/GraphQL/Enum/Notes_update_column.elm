module GraphQL.Enum.Notes_update_column exposing
    ( Notes_update_column(..)
    , decoder
    , encode
    , fromString
    , toString
    )

import Json.Decode
import Json.Encode


type Notes_update_column
    = Id
    | Is_dark_mode
    | Notes
    | Title


encode : Notes_update_column -> Json.Encode.Value
encode value =
    Json.Encode.string (toString value)


decoder : Json.Decode.Decoder Notes_update_column
decoder =
    Json.Decode.string
        |> Json.Decode.andThen
            (\value ->
                value
                    |> fromString
                    |> Maybe.map Json.Decode.succeed
                    |> Maybe.withDefault
                        (Json.Decode.fail <| "unknown Notes_update_column " ++ value)
            )


toString : Notes_update_column -> String
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


fromString : String -> Maybe Notes_update_column
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
