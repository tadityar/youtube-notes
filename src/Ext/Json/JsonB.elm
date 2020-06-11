module Ext.Json.JsonB exposing (JsonB(..), dict, stringKeyedDict)

import Dict exposing (Dict)
import Dict.Extra
import String exposing (fromInt)


type JsonB
    = JsonB (Dict Int String)


stringKeyedDict : JsonB -> Dict String String
stringKeyedDict (JsonB d) =
    Dict.Extra.mapKeys (\i -> fromInt i) d


dict : JsonB -> Dict Int String
dict (JsonB d) =
    d
