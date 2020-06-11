module Ext.Json.Encoder exposing (..)

import Ext.Json.JsonB exposing (JsonB(..))
import Ext.Json.UUID exposing (UUID(..))
import Json.Encode
import String exposing (fromInt)


encodeUUID : UUID -> Json.Encode.Value
encodeUUID (UUID s) =
    Json.Encode.string s


encodeJsonB : JsonB -> Json.Encode.Value
encodeJsonB (JsonB d) =
    Json.Encode.dict (\k -> fromInt k) (\v -> Json.Encode.string v) d
