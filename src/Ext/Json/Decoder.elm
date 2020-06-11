module Ext.Json.Decoder exposing (..)

import Dict.Extra
import Ext.Json.JsonB exposing (JsonB(..), stringKeyedDict)
import Ext.Json.UUID exposing (UUID(..))
import Json.Decode
import String exposing (toInt)


decodeUUID : Json.Decode.Decoder UUID
decodeUUID =
    Json.Decode.string
        |> Json.Decode.andThen
            (\string ->
                Json.Decode.succeed (UUID string)
            )


decodeJsonB : Json.Decode.Decoder JsonB
decodeJsonB =
    Json.Decode.map (\sDict -> JsonB (Dict.Extra.mapKeys (\s -> Maybe.withDefault 0 (toInt s)) sDict)) (Json.Decode.dict Json.Decode.string)
