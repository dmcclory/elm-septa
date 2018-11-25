module Main exposing (Model, Msg(..), init, main, update, view)

import Browser
import Html exposing (Html, div, h1, img, p, text)
import Html.Attributes exposing (src)
import Http
import Json.Decode as Decode
import Url.Builder exposing (crossOrigin)


main : Program () Model Msg
main =
    Browser.element
        { view = view
        , init = init
        , update = update
        , subscriptions = always Sub.none
        }


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
    = Failure String
    | Loading
    | Success


lineDatas =
    [ ( "Airport Terminal E-F", "Airport" )
    , ( "Chestnut Hill East", "Chestnut Hill East" )
    , ( "Chestnut Hill West", "Chestnut Hill West" )
    , ( "Fox Chase", "Fox Chase" )
    , ( "Lansdale", "Lansdale/Doylestown" )
    , ( "Manayunk", "Manayunk/Norristown" )
    , ( "Elwyn Station", "Media/Elwyn" )
    , ( "Malvern", "Paoli/Thorndale" )
    , ( "Trenton", "Trenton" )
    , ( "Warminster", "Warminster" )
    , ( "West Trenton", "West Trenton" )
    , ( "Wilmington", "Wilmington/Newark" )
    ]


current =
    "Chestnut Hill West"


init : () -> ( Model, Cmd Msg )
init _ =
    let
        lineData =
            List.map
                (\l ->
                    { reqStatus = Loading, name = Tuple.second l, trains = [] }
                )
                lineDatas
    in
    ( lineData, kickoffRequests lineDatas )


kickoffRequests : List ( String, String ) -> Cmd Msg
kickoffRequests lds =
    Cmd.batch (List.map (\l -> Http.send GotData (getSeptaData (Tuple.first l))) lds)


getSeptaData : String -> Http.Request (List Train)
getSeptaData originStation =
    let
        url =
            crossOrigin "http://localhost:4567" [ "forward", originStation, "Market East", "10" ] []
    in
    Http.get url decodeTrains



---- UPDATE ----


type Msg
    = NoOp
    | GotData (Result Http.Error (List Train))


setTrains : List Train -> Line -> Line
setTrains newTrains line =
    { line | trains = newTrains }


updateIfLineNameMatches : String -> List Train -> Line -> Line
updateIfLineNameMatches lineName trainResult line =
    if line.name == lineName then
        let
            newLine =
                setTrains trainResult line
        in
        { newLine | reqStatus = Success }

    else
        line


setToFailure : String -> Line -> Line
setToFailure message line =
    { line | reqStatus = Failure message }


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
                                    updateIfLineNameMatches t.line data

                                Nothing ->
                                    setToFailure "data seems ... empty?"
                    in
                    ( List.map updater model, Cmd.none )

                Err x ->
                    ( List.map (setToFailure (Debug.toString x)) model, Cmd.none )



---- VIEW ----


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
        Failure m ->
            div [] [ text (Debug.toString line ++ ": " ++ m) ]

        Loading ->
            text "Loading..."

        Success ->
            viewTrains line


viewTrains line =
    div []
        (List.append
            [ h1 [] [ text line.name ] ]
            (List.map
                (\a -> p [] [ text (a.number ++ " leaving at: " ++ a.departureTime ++ ". delayed? " ++ a.delay) ])
                line.trains
            )
        )
