module GraphQL.Enum.Order_by exposing
    ( Order_by(..)
    , decoder
    , encode
    , fromString
    , toString
    )

import Json.Decode
import Json.Encode


type Order_by
    = Asc
    | Asc_nulls_first
    | Asc_nulls_last
    | Desc
    | Desc_nulls_first
    | Desc_nulls_last


encode : Order_by -> Json.Encode.Value
encode value =
    Json.Encode.string (toString value)


decoder : Json.Decode.Decoder Order_by
decoder =
    Json.Decode.string
        |> Json.Decode.andThen
            (\value ->
                value
                    |> fromString
                    |> Maybe.map Json.Decode.succeed
                    |> Maybe.withDefault
                        (Json.Decode.fail <| "unknown Order_by " ++ value)
            )


toString : Order_by -> String
toString value =
    case value of
        Asc ->
            "asc"

        Asc_nulls_first ->
            "asc_nulls_first"

        Asc_nulls_last ->
            "asc_nulls_last"

        Desc ->
            "desc"

        Desc_nulls_first ->
            "desc_nulls_first"

        Desc_nulls_last ->
            "desc_nulls_last"


fromString : String -> Maybe Order_by
fromString value =
    case value of
        "asc" ->
            Just Asc

        "asc_nulls_first" ->
            Just Asc_nulls_first

        "asc_nulls_last" ->
            Just Asc_nulls_last

        "desc" ->
            Just Desc

        "desc_nulls_first" ->
            Just Desc_nulls_first

        "desc_nulls_last" ->
            Just Desc_nulls_last

        _ ->
            Nothing
