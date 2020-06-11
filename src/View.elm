port module View exposing (main)

import Browser
import Create exposing (deadEndsToString, isAfter, isBefore, isOnOrBefore)
import Db.NotesByPK
import Dict exposing (Dict)
import Ext.GraphQL.Http
import Ext.Json.JsonB
import Ext.Json.UUID exposing (UUID)
import GraphQL.Response
import Html exposing (Html, button, div, text)
import Html.Attributes exposing (class, disabled)
import Html.Events exposing (onClick)
import Http
import Markdown.Parser
import Markdown.Renderer
import Task


type alias Model =
    { title : String
    , currentTime : Float
    , notes : Dict Int String
    , isDarkMode : Bool
    }


type alias Flags =
    { uuid : String
    , currentTime : Float
    }


type Msg
    = Something
    | OnGetNote (Result Http.Error Db.NotesByPK.Response)
    | OnSeekVideo Int
    | OnNextNote ( Int, String )
    | OnPrevNote ( Int, String )
    | ReceivedVideoTimestamp Float


main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


subscriptions : Model -> Sub Msg
subscriptions model =
    getTimestamp ReceivedVideoTimestamp


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { title = "View"
      , currentTime = flags.currentTime
      , notes = Dict.fromList []
      , isDarkMode = True
      }
    , getNote "http://localhost:8080/v1/graphql"
        { id =
            Ext.Json.UUID.UUID flags.uuid
        }
    )


view : Model -> Html Msg
view model =
    noteDisplay model


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ReceivedVideoTimestamp timeStamp ->
            ( { model | currentTime = timeStamp }, Cmd.none )

        Something ->
            ( model, seekVideo 0 )

        OnGetNote result ->
            case result of
                Ok (GraphQL.Response.Data query) ->
                    let
                        resp =
                            Debug.log "resp" query

                        notes =
                            case query.notes_by_pk of
                                Just note ->
                                    note.notes

                                _ ->
                                    Ext.Json.JsonB.JsonB (Dict.fromList [])
                    in
                    ( { model | notes = Ext.Json.JsonB.dict notes }, Cmd.none )

                Ok (GraphQL.Response.Errors errors _) ->
                    let
                        a =
                            Debug.log "resp" errors
                    in
                    ( model, Cmd.none )

                Err error ->
                    let
                        a =
                            Debug.log "resp" error
                    in
                    ( model, Cmd.none )

        OnSeekVideo timeStamp ->
            ( { model | currentTime = toFloat timeStamp }, seekVideo timeStamp )

        OnNextNote currentNote ->
            let
                notesAfter =
                    List.filter (isAfter (toFloat (Tuple.first currentNote))) (Dict.toList model.notes)

                nextNote =
                    Maybe.withDefault ( 0, "" ) (List.head notesAfter)
            in
            ( { model | currentTime = toFloat (Tuple.first nextNote) }, seekVideo (Tuple.first nextNote) )

        OnPrevNote currentNote ->
            let
                notesBefore =
                    List.filter (isBefore (toFloat (Tuple.first currentNote))) (Dict.toList model.notes)

                prevNote =
                    Maybe.withDefault ( 0, "" ) (List.head (List.reverse notesBefore))
            in
            ( { model | currentTime = toFloat (Tuple.first prevNote) }, seekVideo (Tuple.first prevNote) )


noteDisplay : Model -> Html Msg
noteDisplay model =
    let
        passedNotes =
            List.filter (isOnOrBefore model.currentTime) (Dict.toList model.notes)

        currentNote =
            Maybe.withDefault ( 0, "" ) (List.head (List.reverse passedNotes))

        prevBtnDisabled =
            if List.length passedNotes < 2 then
                True

            else
                False

        nextBtnDisabled =
            if List.length passedNotes == Dict.size model.notes then
                True

            else
                False

        cardBody =
            case
                Tuple.second currentNote
                    |> Markdown.Parser.parse
                    |> Result.mapError deadEndsToString
                    |> Result.andThen (\ast -> Markdown.Renderer.render Markdown.Renderer.defaultHtmlRenderer ast)
            of
                Ok rendered ->
                    div [ class "card-text" ] rendered

                Err errors ->
                    div [ class "card-text" ] [ text errors ]

        ( cardClass, btnClass ) =
            if model.isDarkMode then
                ( "card bg-dark text-light", "btn btn-outline-light" )

            else
                ( "card", "btn btn-outline-secondary" )
    in
    div [ class cardClass ]
        [ div [ class "card-body" ]
            [ cardBody
            , div [ class "btn-group" ]
                [ button [ class btnClass, onClick (OnPrevNote currentNote), disabled prevBtnDisabled ]
                    [ text "prev" ]
                , button [ class btnClass, onClick (OnNextNote currentNote), disabled nextBtnDisabled ] [ text "next" ] -- TODO: Disable when there's no prev or next
                ]
            ]
        ]


getNote : String -> Db.NotesByPK.Variables -> Cmd Msg
getNote apiUrl variables =
    Db.NotesByPK.query variables
        |> Ext.GraphQL.Http.post { headers = [], url = apiUrl, timeout = Just 60000.0 }
        |> Task.attempt OnGetNote


port getTimestamp : (Float -> msg) -> Sub msg


port seekVideo : Int -> Cmd msg
