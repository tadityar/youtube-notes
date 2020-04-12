port module Main exposing (main)

import Browser
import Dict exposing (Dict)
import Html exposing (Html, button, div, form, h1, input, label, text, textarea)
import Html.Attributes exposing (class, disabled, step, type_, value)
import Html.Events exposing (onClick)
import String exposing (fromInt)


type alias Model =
    { currentTime : Float
    , currentNotes : Dict Int String
    , notes : List ( Int, String ) -- must always be sorted ascending based on timestamp
    }


type alias Flags =
    { currentTime : Float
    }


type Msg
    = ReceivedVideoTimestamp Float
    | OnSeekVideo Int
    | OnNextNote ( Int, String )
    | OnPrevNote ( Int, String )


main =
    Browser.element { init = init, view = view, update = update, subscriptions = subscriptions }


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { currentTime = flags.currentTime
      , currentNotes = Dict.empty
      , notes = [ ( 0, "something" ), ( 100, "something else" ) ]
      }
    , Cmd.none
    )


view : Model -> Html Msg
view model =
    div []
        [ noteDisplay model
        , button [ class "btn btn-primary mt-1" ] [ text "Add note" ]
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
                    List.filter (isAfter (toFloat (Tuple.first currentNote))) model.notes

                nextNote =
                    Maybe.withDefault ( 0, "" ) (List.head notesAfter)
            in
            ( { model | currentTime = toFloat (Tuple.first nextNote) }, seekVideo (Tuple.first nextNote) )

        OnPrevNote currentNote ->
            let
                notesBefore =
                    List.filter (isBefore (toFloat (Tuple.first currentNote))) model.notes

                prevNote =
                    Maybe.withDefault ( 0, "" ) (List.head (List.reverse notesBefore))
            in
            ( { model | currentTime = toFloat (Tuple.first prevNote) }, seekVideo (Tuple.first prevNote) )


subscriptions : Model -> Sub Msg
subscriptions model =
    getTimestamp ReceivedVideoTimestamp


noteForm : Model -> Html Msg
noteForm model =
    form []
        (List.map
            (noteItemForm model)
            model.notes
        )


noteItemForm : Model -> ( Int, String ) -> Html Msg
noteItemForm model currentNote =
    div [ class "card mt-1" ]
        [ div [ class "card-body" ]
            [ div [ class "form-group" ]
                [ label [] [ text "Timestamp" ]
                , input [ class "form-control", value (fromInt (Tuple.first currentNote)) ] []
                ]
            , div [ class "form-group" ]
                [ label [] [ text "Note" ]
                , textarea [ class "form-control", value (Tuple.second currentNote) ] []
                ]
            ]
        ]


noteDisplay : Model -> Html Msg
noteDisplay model =
    let
        passedNotes =
            List.filter (isOnOrBefore model.currentTime) model.notes

        currentNote =
            Maybe.withDefault ( 0, "" ) (List.head (List.reverse passedNotes))

        prevBtnDisabled =
            if List.length passedNotes < 2 then
                True

            else
                False

        nextBtnDisabled =
            if List.length passedNotes == List.length model.notes then
                True

            else
                False
    in
    div [ class "card" ]
        [ div [ class "card-body" ]
            [ div [ class "card-text" ] [ text (Tuple.second currentNote) ]
            , div [ class "btn-group" ]
                [ button [ class "btn btn-outline-secondary", onClick (OnPrevNote currentNote), disabled prevBtnDisabled ]
                    [ text "prev" ]
                , button [ class "btn btn-outline-secondary", onClick (OnNextNote currentNote), disabled nextBtnDisabled ] [ text "next" ] -- TODO: Disable when there's no prev or next
                ]
            ]
        ]


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
