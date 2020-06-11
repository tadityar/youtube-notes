module GraphQL.Enum.Notes_constraint exposing
    ( Notes_constraint(..)
    , decoder
    , encode
    , fromString
    , toString
    )

import Json.Decode
import Json.Encode


type Notes_constraint
    = Notes_pkey


encode : Notes_constraint -> Json.Encode.Value
encode value =
    Json.Encode.string (toString value)


decoder : Json.Decode.Decoder Notes_constraint
decoder =
    Json.Decode.string
        |> Json.Decode.andThen
            (\value ->
                value
                    |> fromString
                    |> Maybe.map Json.Decode.succeed
                    |> Maybe.withDefault
                        (Json.Decode.fail <| "unknown Notes_constraint " ++ value)
            )


toString : Notes_constraint -> String
toString value =
    case value of
        Notes_pkey ->
            "notes_pkey"


fromString : String -> Maybe Notes_constraint
fromString value =
    case value of
        "notes_pkey" ->
            Just Notes_pkey

        _ ->
            Nothing
