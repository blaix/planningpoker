module Backend exposing (..)

import Dict
import Hashids as Hash
import Lamdera exposing (ClientId, SessionId, broadcast, sendToFrontend)
import Room exposing (CurrentRoom(..), Room)
import Types exposing (..)
import User


type alias Model =
    BackendModel


salt : String
salt =
    "0a74d29e-30ce-400a-9027-3866a088f8a1"


hashContext : Hash.Context
hashContext =
    Hash.hashidsMinimum salt 8


app :
    { init : ( Model, Cmd BackendMsg )
    , update : BackendMsg -> Model -> ( Model, Cmd BackendMsg )
    , updateFromFrontend : SessionId -> ClientId -> ToBackend -> Model -> ( Model, Cmd BackendMsg )
    , subscriptions : Model -> Sub BackendMsg
    }
app =
    Lamdera.backend
        { init = init
        , update = update
        , updateFromFrontend = updateFromFrontend
        , subscriptions = \_ -> Sub.none
        }


init : ( Model, Cmd BackendMsg )
init =
    ( { rooms = Dict.empty
      , userIds = Dict.empty
      , idCounter = 0
      }
    , Cmd.none
    )


update : BackendMsg -> Model -> ( Model, Cmd BackendMsg )
update msg model =
    case msg of
        NoOpBackendMsg ->
            ( model, Cmd.none )


updateFromFrontend : SessionId -> ClientId -> ToBackend -> Model -> ( Model, Cmd BackendMsg )
updateFromFrontend sessionId clientId msg model =
    case msg of
        CreateRoom ->
            let
                ( newRoom, newModel ) =
                    createRoom model
            in
            ( newModel
            , sendToFrontend clientId (RoomCreated newRoom)
            )

        UpdateRoom room ->
            ( { model | rooms = Dict.insert room.slug room model.rooms }
            , broadcast (RoomUpdated room)
            )

        Vote currentRoom userId vote ->
            case Room.vote currentRoom userId vote of
                CurrentRoom room ->
                    ( { model | rooms = Dict.insert room.slug room model.rooms }
                    , broadcast (RoomUpdated room)
                    )

                _ ->
                    ( model, Cmd.none )

        GetCurrentRoom slug ->
            let
                room =
                    model.rooms
                        |> Dict.get slug
                        |> Maybe.map CurrentRoom
                        |> Maybe.withDefault RoomNotFound
            in
            ( model, sendToFrontend clientId (GotCurrentRoom room) )

        GetUserId ->
            let
                ( newUserId, newModel ) =
                    case Dict.get sessionId model.userIds of
                        Just userId ->
                            ( userId, model )

                        Nothing ->
                            createUserId sessionId model
            in
            ( newModel, sendToFrontend clientId (GotUserId newUserId) )


createRoom : Model -> ( Room, Model )
createRoom model =
    let
        newCounter =
            model.idCounter + 1

        slug =
            Hash.encode hashContext newCounter

        newRoom =
            { slug = slug, members = Dict.empty, votes = Dict.empty, revealVotes = False }
    in
    ( newRoom
    , { model
        | rooms = Dict.insert slug newRoom model.rooms
        , idCounter = newCounter
      }
    )


createUserId : SessionId -> Model -> ( User.Id, Model )
createUserId sessionId model =
    let
        newCounter =
            model.idCounter + 1

        userId =
            Hash.encode hashContext newCounter
    in
    ( userId
    , { model
        | idCounter = newCounter
        , userIds = Dict.insert sessionId userId model.userIds
      }
    )
