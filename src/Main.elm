module Main exposing (main)

import Browser
import Html exposing (Html, h1, text)


type alias Model =
    {}


type alias Flags =
    {}


type Msg
    = Sample
    | AnotherSample


main =
    Browser.document { init = init, view = view, update = update, subscriptions = subscriptions }


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( {}, Cmd.none )


view : Model -> Browser.Document Msg
view model =
    let
        documentTitle =
            "youtube-notes"
    in
    Browser.Document documentTitle
        [ h1 [] [ text "hello!" ]
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( {}, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
