module Ext.Json.UUID exposing (UUID(..), string)


type UUID
    = UUID String


string : UUID -> String
string (UUID s) =
    s
