module Main exposing (Model, Msg(..), init, main, update, view)

import Browser
import Element exposing (Element, alignLeft, alignRight, centerX, centerY, column, el, fill, height, padding, paddingEach, paddingXY, px, rgb255, row, spacing, text, width, wrappedRow)
import Element.Background as Background
import Element.Border as Border
import Element.Events as Events
import Element.Font as Font
import Html exposing (Html)
import Http
import Json.Decode as Decode
import Url.Builder exposing (crossOrigin, relative)


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
    { inboundLines : List Line
    , outboundLines : List Line
    , inbound : Bool
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

        inbound =
            True
    in
    ( { outboundLines = lineData, inboundLines = lineData, inbound = inbound }, kickoffRequests lineDatas inbound )


kickoffRequests : List ( String, String ) -> Bool -> Cmd Msg
kickoffRequests lds inbound =
    let
        pairs =
            List.map (\d -> ( d, True )) lds ++ List.map (\d -> ( d, False )) lds

        signaler =
            \d ->
                case d of
                    True ->
                        GotInbound

                    False ->
                        GotOutbound
    in
    Cmd.batch (List.map (\( l, d ) -> Http.send (signaler d) (getSeptaData (Tuple.first l) d)) pairs)


getSeptaData : String -> Bool -> Http.Request (List Train)
getSeptaData originStation inbound =
    let
        ( origin, destination ) =
            case inbound of
                True ->
                    ( originStation, "Market East" )

                False ->
                    ( "Market East", originStation )

        url =
            relative [ "forward", origin, destination, "10" ] []

        --crossOrigin "http://localhost:4567" [ "forward", origin, destination, "10" ] []
    in
    Http.get url decodeTrains



---- UPDATE ----


type Msg
    = NoOp
    | GotOutbound (Result Http.Error (List Train))
    | GotInbound (Result Http.Error (List Train))
    | SetDirection Bool


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


updateLines inbound model data =
    let
        updater =
            case List.head data of
                Just t ->
                    updateIfLineNameMatches t.line data

                Nothing ->
                    setToFailure "data ... seems empty?"
    in
    case inbound of
        True ->
            { model | inboundLines = List.map updater model.inboundLines }

        False ->
            { model | outboundLines = List.map updater model.outboundLines }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        SetDirection direction ->
            ( { model | inbound = direction }, Cmd.none )

        GotOutbound result ->
            case result of
                Ok data ->
                    ( updateLines False model data, Cmd.none )

                Err x ->
                    ( model, Cmd.none )

        GotInbound result ->
            case result of
                Ok data ->
                    ( updateLines True model data, Cmd.none )

                Err x ->
                    ( { model | inboundLines = List.map (setToFailure "had trouble making the request >... sorry!") model.inboundLines }, Cmd.none )



---- VIEW ----


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


lineSelector : Model -> List Line
lineSelector model =
    case model.inbound of
        True ->
            model.inboundLines

        False ->
            model.outboundLines


view : Model -> Html Msg
view model =
    let
        divs =
            wrappedRow [] (List.map viewLine (lineSelector model))
    in
    Element.layout []
        (column
            [ Background.color black, Font.color white, width fill, centerX, padding 5 ]
            [ viewHeader model.inbound
            , divs
            ]
        )


viewHeader inbound =
    let
        cool =
            case inbound of
                True ->
                    "to"

                False ->
                    "from"
    in
    row [ Background.color blue, centerX, width fill ]
        [ el [ alignLeft ] Element.none
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


viewLine : Line -> Element Msg
viewLine line =
    case line.reqStatus of
        Failure m ->
            viewLoadError line m

        -- el [] (text (line.name ++ ": " ++ m))
        Loading ->
            viewLoading

        Success ->
            viewLineRefactorMe line



-- boxAttrs : List Element.Attribute Msg


boxAttrs =
    [ Border.color white
    , Border.width 1
    , Border.solid
    , width (px 475)
    , height (px 290)
    ]


viewLoadError line m =
    el boxAttrs (text (line.name ++ ": " ++ m))


viewLoading : Element Msg
viewLoading =
    el boxAttrs (text "Loading...")


viewLineRefactorMe : Line -> Element Msg
viewLineRefactorMe line =
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
