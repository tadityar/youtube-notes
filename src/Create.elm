port module Create exposing (deadEndsToString, isAfter, isBefore, isOnOrBefore, main)

import Browser
import Browser.Navigation
import Db.InsertNotes
import Dict exposing (Dict)
import Ext.GraphQL.Http
import Ext.Json.JsonB exposing (JsonB)
import Ext.Json.UUID
import GraphQL.Optional
import GraphQL.Response
import Html exposing (Html, a, button, div, form, h1, input, label, small, text, textarea)
import Html.Attributes exposing (checked, class, disabled, for, href, id, readonly, step, type_, value)
import Html.Events exposing (onCheck, onClick, onInput, onSubmit)
import Http
import Markdown.Parser
import Markdown.Renderer
import String exposing (fromInt)
import Task


type alias Model =
    { currentTime : Float
    , notes : Dict Int String
    , videoId : String
    , title : String
    , isDarkMode : Bool
    }


type alias Flags =
    { currentTime : Float
    , videoId : String
    }


type Msg
    = ReceivedVideoTimestamp Float
    | OnSeekVideo Int
    | OnNextNote ( Int, String )
    | OnPrevNote ( Int, String )
    | OnAddNote
    | OnNoteChanged Int String
    | OnNoteDelete Int
    | OnToggleDarkMode
    | OnVideoIdChange String
    | OnChangeVideo String
    | OnPublishNote
    | OnInsertNote (Result Http.Error Db.InsertNotes.Response)


main =
    Browser.element { init = init, view = view, update = update, subscriptions = subscriptions }


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { currentTime = flags.currentTime
      , notes = Dict.fromList []
      , videoId = flags.videoId
      , title = "youtube-notes"
      , isDarkMode = False
      }
    , Cmd.none
    )


view : Model -> Html Msg
view model =
    let
        addNoteDisabled =
            if Dict.member (Basics.floor model.currentTime) model.notes then
                True

            else
                False
    in
    div []
        [ button [ class "btn btn-primary mb-1 mr-1", onClick OnAddNote, disabled addNoteDisabled ] [ text "Add note" ]
        , button [ class "btn btn-outline-primary mb-1", onClick OnPublishNote ] [ text "Publish note" ]
        , div [ class "row" ]
            [ div [ class "col-md-9" ] [ noteDisplay model ], div [ class "col-md-3" ] [ noteSettings model ] ]
        , noteForm model
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case Debug.log "update" msg of
        ReceivedVideoTimestamp timeStamp ->
            ( { model | currentTime = timeStamp }, Cmd.none )

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

        OnAddNote ->
            ( { model | notes = Dict.insert (Basics.floor model.currentTime) "" model.notes }, Cmd.none )

        OnNoteChanged ts s ->
            let
                newNote =
                    Dict.update ts (\_ -> Just s) model.notes
            in
            ( { model | notes = newNote }, Cmd.none )

        OnNoteDelete ts ->
            let
                newNotes =
                    Dict.remove ts model.notes
            in
            ( { model | notes = newNotes }, Cmd.none )

        OnVideoIdChange s ->
            ( { model | videoId = s }, Cmd.none )

        OnChangeVideo videoId ->
            ( model, Browser.Navigation.load ("/create.html?videoId=" ++ model.videoId) )

        OnToggleDarkMode ->
            ( { model | isDarkMode = not model.isDarkMode }, Cmd.none )

        OnPublishNote ->
            ( model
            , publishNote "http://localhost:8080/v1/graphql"
                { input =
                    [ { id = GraphQL.Optional.Absent
                      , is_dark_mode = GraphQL.Optional.Present model.isDarkMode
                      , notes = GraphQL.Optional.Present (Ext.Json.JsonB.JsonB model.notes)
                      , title = GraphQL.Optional.Present model.title
                      }
                    ]
                }
            )

        OnInsertNote result ->
            case result of
                Ok (GraphQL.Response.Data mutation) ->
                    let
                        maybeCreatedNote =
                            Maybe.andThen (\n -> List.head n.returning) mutation.insert_notes

                        cmd =
                            case maybeCreatedNote of
                                Just note ->
                                    let
                                        darkStr =
                                            if note.is_dark_mode then
                                                "1"

                                            else
                                                "0"
                                    in
                                    Browser.Navigation.load ("view.html?videoId=" ++ model.videoId ++ "&noteId=" ++ Ext.Json.UUID.string note.id ++ "&isDark=" ++ darkStr ++ "&title=" ++ note.title)

                                Nothing ->
                                    Cmd.none
                    in
                    ( model, cmd )

                Ok (GraphQL.Response.Errors errors _) ->
                    -- TODO: alert that there was an error
                    ( model, Cmd.none )

                Err error ->
                    -- TODO: alert that there was an error
                    ( model, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    getTimestamp ReceivedVideoTimestamp


noteSettings : Model -> Html Msg
noteSettings model =
    div [ class "card" ]
        [ div [ class "card-body" ]
            [ form []
                [ div [ class "form-group" ]
                    [ label [] [ text "Video ID" ]
                    , input [ class "form-control", value model.videoId, onInput OnVideoIdChange ] []
                    ]
                , button [ class "btn btn-danger", type_ "button", onClick (OnChangeVideo model.videoId) ] [ text "Change Video" ]
                , div [ class "form-group" ]
                    [ label [] [ text "Title" ]
                    , input [ class "form-control", value model.title ] []
                    ]
                , div [ class "custom-control custom-switch" ]
                    [ input [ type_ "checkbox", class "custom-control-input", id "dark-mode-switch", checked model.isDarkMode, onCheck (\_ -> OnToggleDarkMode) ] []
                    , label [ class "custom-control-label", for "dark-mode-switch" ] [ text "Dark Mode" ]
                    ]
                ]
            ]
        ]


noteForm : Model -> Html Msg
noteForm model =
    form []
        (List.map
            (noteItemForm model)
            (Dict.toList model.notes)
        )


noteItemForm : Model -> ( Int, String ) -> Html Msg
noteItemForm model currentNote =
    let
        ts =
            Tuple.first currentNote
    in
    div [ class "card mt-1 mb-1" ]
        [ div [ class "card-body" ]
            [ div [ class "form-group" ]
                [ label [] [ text "Timestamp" ]
                , input [ class "form-control", value (fromInt ts), readonly True ] []
                , small [ class "form-text text-muted" ] [ text "timestamp is set based on when you press 'Add note'. If you want to change it, delete the note and re-add at the correct time." ]
                ]
            , div [ class "form-group" ]
                [ label [] [ text "Note" ]
                , textarea [ class "form-control", value (Tuple.second currentNote), onInput (\s -> OnNoteChanged ts s) ] []
                ]
            , button [ class "btn btn-outline-danger", onClick (OnNoteDelete ts), type_ "button" ] [ text "Delete" ]
            ]
        ]


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


deadEndsToString deadEnds =
    deadEnds
        |> List.map Markdown.Parser.deadEndToString
        |> String.join "\n"


hasDuplicateTimestamp : Int -> List ( Int, String ) -> Bool
hasDuplicateTimestamp ts notes =
    List.filter (\n -> Tuple.first n == ts) notes
        |> List.length
        |> (<) 1


isOnOrBefore : Float -> ( Int, a ) -> Bool
isOnOrBefore currentTime ( time, _ ) =
    if isAfter currentTime ( time, "" ) then
        False

    else
        True


isBefore : Float -> ( Int, a ) -> Bool
isBefore currentTime ( time, _ ) =
    if toFloat time < currentTime then
        True

    else
        False


isAfter : Float -> ( Int, a ) -> Bool
isAfter currentTime ( time, _ ) =
    if toFloat time > currentTime then
        True

    else
        False


publishNote : String -> Db.InsertNotes.Variables -> Cmd Msg
publishNote apiUrl variables =
    Db.InsertNotes.mutation variables
        |> Ext.GraphQL.Http.post { headers = [ Http.header "X-Hasura-Role" "public" ], url = apiUrl, timeout = Just 60000.0 }
        |> Task.attempt OnInsertNote


port getTimestamp : (Float -> msg) -> Sub msg


port seekVideo : Int -> Cmd msg
