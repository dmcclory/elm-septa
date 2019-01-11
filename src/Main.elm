module Main exposing (Model, Msg(..), init, main, update, view)

import Browser
import Dict exposing (Dict)
import Element exposing (Element, alignLeft, alignRight, centerX, centerY, column, el, fill, height, padding, paddingEach, paddingXY, px, rgb255, row, spacing, text, width, wrappedRow)
import Element.Background as Background
import Element.Border as Border
import Element.Events as Events
import Element.Font as Font
import Html exposing (Html)
import Http
import Json.Decode as Decode
import Time
import Url.Builder exposing (crossOrigin, relative)


main : Program () Model Msg
main =
    Browser.element
        { view = view
        , init = init
        , update = update
        , subscriptions = subscriptions
        }


subscriptions model =
    Time.every 5000 Tick


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


decodeLine : Decode.Decoder Line
decodeLine =
    Decode.map2 Line
        (Decode.field "trains" decodeTrains)
        (Decode.field "name" Decode.string)


decodeLines : Decode.Decoder (List Line)
decodeLines =
    Decode.list decodeLine


decodeLineReqResult : Decode.Decoder LineReqResult
decodeLineReqResult =
    Decode.map2 LineReqResult
        (Decode.field "inbound" decodeLines)
        (Decode.field "outbound" decodeLines)



---- MODEL ----


type alias Train =
    { number : String
    , line : String
    , departureTime : String
    , arrivalTime : String
    , delay : String
    , direct : String
    }


type alias Line =
    { trains : List Train
    , name : String
    }


type alias LineReq =
    { line : Line
    , reqStatus : Request
    }


type alias LineReqResult =
    { inbound : List Line
    , outbound : List Line
    }


type alias Model =
    { inboundLines : List Line
    , outboundLines : List Line
    , inbound : Bool
    , dumb : String
    }


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


init : () -> ( Model, Cmd Msg )
init _ =
    let
        lineData =
            List.map
                (\l ->
                    { name = Tuple.second l, trains = [] }
                )
                lineDatas

        inbound =
            True
    in
    ( { dumb = ""
      , outboundLines = lineData
      , inboundLines = lineData
      , inbound = inbound
      }
    , Cmd.none
    )


getLinesData : Http.Request LineReqResult
getLinesData =
    Http.get (relative [ "lines" ] []) decodeLineReqResult



---- UPDATE ----


type Msg
    = NoOp
    | GotLinesData (Result Http.Error LineReqResult)
    | SetDirection Bool
    | Tick Time.Posix


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        SetDirection direction ->
            ( { model | inbound = direction }, Cmd.none )

        GotLinesData result ->
            case result of
                Ok data ->
                    let
                        message =
                            case List.head data.inbound of
                                Just line ->
                                    line.name

                                Nothing ->
                                    "what the frick"
                    in
                    ( { model | inboundLines = data.inbound, outboundLines = data.outbound, dumb = message }, Cmd.none )

                Err x ->
                    ( { model | dumb = "Real dumb" }, Cmd.none )

        Tick _ ->
            ( model, Http.send GotLinesData getLinesData )



---- VIEW ----


view : Model -> Html Msg
view model =
    let
        departingTrains =
            wrappedRow [] (List.map viewLine (lineSelector model))
    in
    Element.layout []
        (column
            [ Background.color black, Font.color white, width fill, centerX, padding 5 ]
            [ viewHeader model.inbound model.dumb
            , departingTrains
            ]
        )


viewHeader inbound dumb =
    let
        cool =
            case inbound of
                True ->
                    "to"

                False ->
                    "from"
    in
    row [ Background.color blue, centerX, width fill ]
        [ el [ alignLeft ] (text dumb)
        , el [ centerX, Font.bold, Font.size 30 ] (String.concat [ "Departures ", cool, " Center City" ] |> text)
        , directionToggle inbound
        ]


selectedButton =
    [ Background.color white, padding 10, Font.color blue ]


deselectedButton =
    [ Border.color white, padding 10 ]


directionToggle inbound =
    let
        ( inSel, outSel ) =
            case inbound of
                True ->
                    ( selectedButton, deselectedButton )

                False ->
                    ( deselectedButton, selectedButton )
    in
    row [ alignRight, paddingEach { top = 0, right = 40, bottom = 0, left = 0 }, spacing 20 ]
        [ el (inSel ++ [ Events.onClick (SetDirection True) ]) (text "Inbound")
        , el (outSel ++ [ Events.onClick (SetDirection False) ]) (text "Outbound")
        ]


lineSelector : Model -> List Line
lineSelector model =
    case model.inbound of
        True ->
            model.inboundLines

        False ->
            model.outboundLines


viewLine : Line -> Element Msg
viewLine line =
    viewTrains line


boxAttrs =
    [ Border.color white
    , Border.width 1
    , Border.solid
    , width (px 475)
    , height (px 290)
    ]


viewLoadError lineReq m =
    el boxAttrs (text (lineReq.line.name ++ ": " ++ m))


viewLoading : Element Msg
viewLoading =
    el boxAttrs (text "Loading...")


viewTrains : Line -> Element Msg
viewTrains line =
    column boxAttrs
        ([ viewLineHeader line ]
            ++ (List.take 4 line.trains |> List.map viewTrain)
        )


viewTrain train =
    row [ height (px 50), width fill, Border.color grey, Border.widthEach { bottom = 1, top = 0, left = 0, right = 0 }, spacing 30, paddingXY 20 0 ]
        [ column [ Font.size 16 ] [ text train.departureTime, viewTrainStatus train.delay ] -- eventually lateness
        , column [ alignLeft, Font.size 16 ] [ text train.line, el [ Font.color cyan ] (text "LOCAL") ]
        , column [ alignRight, Font.size 16, width (px 40) ] [ text "1A", el [ Font.color cyan ] (text train.number) ]
        ]


viewTrainStatus delay =
    let
        c =
            case delay of
                "On time" ->
                    green

                _ ->
                    red
    in
    el [ Font.color c ] (text (String.toUpper delay))


viewLineHeader line =
    row [ Background.color darkBlue, width fill, height (px 50), centerX ] [ el [ centerX ] (text line.name) ]


white =
    rgb255 255 255 255


black =
    rgb255 0 0 0


blue =
    rgb255 0 0 204


green =
    rgb255 0 255 0


red =
    rgb255 255 0 0


cyan =
    rgb255 0 255 255


darkBlue =
    rgb255 0 0 102


grey =
    rgb255 153 153 153
