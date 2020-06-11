module Ext.GraphQL.Http exposing (post)

import GraphQL.Operation exposing (Operation)
import GraphQL.Response exposing (Response)
import Http
import Json.Decode
import Platform exposing (Task)


{-| mimics `Http.task` api but leaves out `method`, `body`, and `resolver`
since those are provided by the `Operation`
-}
post : { headers : List Http.Header, url : String, timeout : Maybe Float } -> Operation t e a -> Task Http.Error (Response e a)
post { headers, url, timeout } operation =
    Http.task
        { method = "POST"
        , headers = headers
        , url = url
        , body = Http.jsonBody (GraphQL.Operation.encode operation)
        , resolver = Http.stringResolver (jsonBodyResolver (GraphQL.Response.decoder operation))
        , timeout = timeout
        }


jsonBodyResolver : Json.Decode.Decoder (Response e a) -> Http.Response String.String -> Result Http.Error (Response e a)
jsonBodyResolver decoder httpResp =
    case httpResp of
        Http.BadUrl_ s ->
            Err (Http.BadUrl s)

        Http.Timeout_ ->
            Err Http.Timeout

        Http.NetworkError_ ->
            Err Http.NetworkError

        Http.BadStatus_ metadata body ->
            -- since `Http.BadStatus` hides the error response body, consider Http.BadBody ?
            -- Err (Http.BadBody (String.fromInt metadata.statusCode ++ " " ++ metadata.statusText ++ ": " ++ body))
            Err (Http.BadStatus metadata.statusCode)

        Http.GoodStatus_ metadata body ->
            Json.Decode.decodeString decoder body
                |> Result.mapError (\err -> Http.BadBody (Json.Decode.errorToString err))
