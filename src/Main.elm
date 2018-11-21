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
    , reqStatus : Request
    }


type alias Model =
    List Line


type Request
    = Failure
    | Loading
    | Success


lines =
    [ "Airport"
    , "Chestnut Hill West"
    , "Chestnut Hill West"
    , "Lansdale-Doylestown"
    ]


current =
    "Chestnut Hill West"


init : () -> ( Model, Cmd Msg )
init _ =
    let
        line =
            { reqStatus = Loading, name = current, trains = [] }
    in
    ( [ line ], send line.name )



---- UPDATE ----


type Msg
    = NoOp
    | GotData (Result Http.Error (List Train))


setTrains : List Train -> Line -> Line
setTrains newTrains line =
    { line | trains = newTrains }


updateGoofy : String -> List Train -> Line -> Line
updateGoofy lineName trains line =
    if line.name == lineName then
        let
            newLine =
                setTrains trains line
        in
        { newLine | reqStatus = Success }

    else
        line


setToFailure : Line -> Line
setToFailure line =
    { line | reqStatus = Failure }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        GotData result ->
            case result of
                Ok data ->
                    let
                        -- get the current line from the first result
                        -- set to failure if that is empty
                        -- pass that in the updater
                        updater =
                            case List.head data of
                                Just t ->
                                    updateGoofy t.line data

                                Nothing ->
                                    setToFailure
                    in
                    ( List.map updater model, Cmd.none )

                Err _ ->
                    ( List.map setToFailure model, Cmd.none )


parseResults response =
    Decode.decodeString decodeTrains response


viewTrains line =
    div []
        (List.append
            [ h1 [] [ text line.name ] ]
            (List.map
                (\a -> p [] [ text (a.number ++ " leaving at: " ++ a.departureTime ++ ". delayed? " ++ a.delay) ])
                line.trains
            )
        )


view : Model -> Html Msg
view model =
    let
        divs =
            List.map viewLine model
    in
    div [] divs


viewLine : Line -> Html Msg
viewLine line =
    case line.reqStatus of
        Failure ->
            div [] [ text (Debug.toString line) ]

        Loading ->
            text "Loading..."

        Success ->
            viewTrains line


getSeptaData : String -> Http.Request (List Train)
getSeptaData originStation =
    let
        url =
            crossOrigin "http://localhost:4567" [ "forward", originStation, "Market East", "10" ] []
    in
    Http.get url decodeTrains


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
