module Main exposing (Model, Msg(..), init, main, multiple_records, update, view)

import Browser
import Html exposing (Html, div, h1, img, p, text)
import Html.Attributes exposing (src)
import Json.Decode as Decode


single_record =
    """{"orig_train":"850","orig_line":"Chestnut Hill West","orig_departure_time":" 5:46PM","orig_arrival_time":" 5:59PM","orig_delay":"On time","isdirect":"true"}"""


multiple_records =
    """[
    {"orig_train":"850","orig_line":"Chestnut Hill West","orig_departure_time":" 5:26PM","orig_arrival_time":" 5:59PM","orig_delay":"On time","isdirect":"true"},
    {"orig_train":"854","orig_line":"Chestnut Hill West","orig_departure_time":" 6:26PM","orig_arrival_time":" 6:59PM","orig_delay":"On time","isdirect":"true"},
    {"orig_train":"858","orig_line":"Chestnut Hill West","orig_departure_time":" 7:26PM","orig_arrival_time":" 7:59PM","orig_delay":"On time","isdirect":"true"},
    {"orig_train":"862","orig_line":"Chestnut Hill West","orig_departure_time":" 8:26PM","orig_arrival_time":" 8:59PM","orig_delay":"On time","isdirect":"true"},
    {"orig_train":"866","orig_line":"Chestnut Hill West","orig_departure_time":" 9:26PM","orig_arrival_time":" 9:59PM","orig_delay":"On time","isdirect":"true"},
    {"orig_train":"870","orig_line":"Chestnut Hill West","orig_departure_time":"10:14PM","orig_arrival_time":"10:46PM","orig_delay":"On time","isdirect":"true"},
    {"orig_train":"8234","orig_line":"Chestnut Hill West","orig_departure_time":"10:54PM","orig_arrival_time":"11:25PM","orig_delay":"On time","isdirect":"true"},
    {"orig_train":"8234","orig_line":"Chestnut Hill West","orig_departure_time":"11:14PM","orig_arrival_time":"11:45PM","orig_delay":"On time","isdirect":"true"}
    ]
"""


type alias Train =
    { number : String
    , line : String
    , departureTime : String
    , arrivalTime : String
    , delay : String
    , direct : String
    }


decodeTrain : Decode.Decoder Train
decodeTrain =
    Decode.map6 Train
        (Decode.field "orig_train" Decode.string)
        (Decode.field "orig_line" Decode.string)
        (Decode.field "orig_departure_time" Decode.string)
        (Decode.field "orig_arrival_time" Decode.string)
        (Decode.field "orig_delay" Decode.string)
        (Decode.field "isdirect" Decode.string)


decodeTrains : Decode.Decoder (List Train)
decodeTrains =
    Decode.list decodeTrain



---- MODEL ----


type Model
    = Failure
    | Loading
    | Success String


init : ( Model, Cmd Msg )
init =
    ( Success multiple_records, Cmd.none )



---- UPDATE ----


type Msg
    = NoOp


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( model, Cmd.none )



---- VIEW ----
--parseResults : List Train


parseResults response =
    Decode.decodeString decodeTrains response


fetchTimes response =
    let
        results =
            parseResults response

        trains =
            case results of
                Ok t ->
                    t

                Err e ->
                    []
    in
    List.map .departureTime trains


view : Model -> Html Msg
view model =
    case model of
        Failure ->
            div [] [ text "trouble loading results from SEPTA" ]

        Loading ->
            text "Loading..."

        Success response ->
            let
                times =
                    fetchTimes response
            in
            div []
                (List.append
                    [ img [ src "/logo.svg" ] []
                    , h1 [] [ text "Your Elm App is working at!" ]
                    ]
                    (List.map
                        (\a -> p [] [ text ("leaving at: " ++ a) ])
                        times
                    )
                )



---- PROGRAM ----


main : Program () Model Msg
main =
    Browser.element
        { view = view
        , init = \_ -> init
        , update = update
        , subscriptions = always Sub.none
        }
