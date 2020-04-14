port module Main exposing (main)

import Browser
import Dict exposing (Dict)
import Html exposing (Html, button, div, form, h1, input, label, small, text, textarea)
import Html.Attributes exposing (class, disabled, readonly, step, type_, value)
import Html.Events exposing (onClick, onInput)
import Markdown.Parser
import Markdown.Renderer
import String exposing (fromInt)


type alias Model =
    { currentTime : Float
    , notes : Dict Int String
    }


type alias Flags =
    { currentTime : Float
    }


type Msg
    = ReceivedVideoTimestamp Float
    | OnSeekVideo Int
    | OnNextNote ( Int, String )
    | OnPrevNote ( Int, String )
    | OnAddNote
    | OnNoteChanged Int String
    | OnNoteDelete Int


main =
    Browser.element { init = init, view = view, update = update, subscriptions = subscriptions }


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { currentTime = flags.currentTime
      , notes = Dict.fromList []
      }
    , Cmd.none
    )


view : Model -> Html Msg
view model =
    let
        addNoteDisabled =
            if Dict.member (Basics.round model.currentTime) model.notes then
                True

            else
                False
    in
    div []
        [ noteDisplay model
        , button [ class "btn btn-primary mt-1", onClick OnAddNote, disabled addNoteDisabled ] [ text "Add note" ]
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
            ( { model | notes = Dict.insert (Basics.round model.currentTime) "" model.notes }, Cmd.none )

        OnNoteChanged ts s ->
            let
                newNote =
                    Dict.update ts (\_ -> Just s) model.notes
            in
            ( { model | notes = newNote }, Cmd.none )

        OnNoteDelete ts ->
            -- let
            --     newNotes =
            --         Dict.remove ts model.notes
            -- in
            -- ( { model | notes = newNotes }, Cmd.none )
            ( model, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    getTimestamp ReceivedVideoTimestamp


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
            , button [ class "btn btn-outline-dark" ] [ text "Delete" ]
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
    in
    div [ class "card" ]
        [ div [ class "card-body" ]
            [ cardBody
            , div [ class "btn-group" ]
                [ button [ class "btn btn-outline-secondary", onClick (OnPrevNote currentNote), disabled prevBtnDisabled ]
                    [ text "prev" ]
                , button [ class "btn btn-outline-secondary", onClick (OnNextNote currentNote), disabled nextBtnDisabled ] [ text "next" ] -- TODO: Disable when there's no prev or next
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


port getTimestamp : (Float -> msg) -> Sub msg


port seekVideo : Int -> Cmd msg
