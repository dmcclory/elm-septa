module Main exposing (Model, Msg(..), init, main, multiple_records, update, view)

import Browser
import Html exposing (Html, div, h1, img, p, text)
import Html.Attributes exposing (src)
import Http
import Json.Decode as Decode
import Url.Builder exposing (crossOrigin)


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


type alias Line =
    { name : String
    , trains : List Train
    }


type alias Model =
    { reqStatus : Request
    , line : Line
    }


type Request
    = Failure
    | Loading
    | Success


init : () -> ( Model, Cmd Msg )
init _ =
    let
        name =
            "Chestnut Hill West"
    in
    ( { reqStatus = Loading, line = { name = name, trains = [] } }, send name )



---- UPDATE ----


type Msg
    = NoOp
    | GotData (Result Http.Error (List Train))


setTrains : List Train -> Line -> Line
setTrains newTrains line =
    { line | trains = newTrains }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        GotData result ->
            case result of
                Ok data ->
                    let
                        newLine =
                            setTrains data model.line
                    in
                    ( { model | reqStatus = Success, line = newLine }, Cmd.none )

                Err _ ->
                    ( { model | reqStatus = Failure }, Cmd.none )


parseResults response =
    Decode.decodeString decodeTrains response


fetchTimes : List Train -> List String
fetchTimes trains =
    List.map .departureTime trains


view : Model -> Html Msg
view model =
    case model.reqStatus of
        Failure ->
            div [] [ text (Debug.toString model) ]

        Loading ->
            text "Loading..."

        Success ->
            div []
                (List.append
                    [ img [ src "/logo.svg" ] []
                    , h1 [] [ text "Your Elm App is working at!" ]
                    ]
                    (List.map
                        (\a -> p [] [ text (a.line ++ " leaving at: " ++ a.departureTime ++ ". delayed? " ++ a.delay) ])
                        model.line.trains
                    )
                )


getSeptaData : String -> Http.Request (List Train)
getSeptaData originStation =
    let
        url =
            crossOrigin "http://localhost:4567" [ "forward", originStation, "Market East", "10" ] []
    in
    Http.get url decodeTrains



-- Http.get "http://www3.septa.org/hackathon/NextToArrive/Chestnut%20Hill%20West/Suburban%20Station/10" decodeTrains
-- Http.get "http://localhost:4567/forward/Market%20East/Chestnut%20Hill%20West/10" decodeTrains
-- Http.get "http://localhost:4567/forward/Trenton/Market%20East/10" decodeTrains
-- Http.get "http://localhost:4567/forward/Market%20East/Trenton/10" decodeTrains


send : String -> Cmd Msg
send lineName =
    Http.send GotData (getSeptaData lineName)


main : Program () Model Msg
main =
    Browser.element
        { view = view
        , init = init
        , update = update
        , subscriptions = always Sub.none
        }
