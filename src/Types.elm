module Types exposing (..)

import Browser exposing (UrlRequest)
import Browser.Navigation exposing (Key)
import Dict exposing (Dict)
import Lamdera exposing (SessionId)
import Room exposing (CurrentRoom, Room)
import Url exposing (Url)
import User


type alias FrontendModel =
    { key : Key
    , room : CurrentRoom
    , userId : User.Id
    , pendingUserName : String
    , pendingVote : String
    }


type alias BackendModel =
    { rooms : Dict Room.Slug Room
    , idCounter : Int
    , userIds : Dict SessionId User.Id
    }


type FrontendMsg
    = UrlClicked UrlRequest
    | UrlChanged Url
    | Clicked_CreateRoom
    | Clicked_JoinRoom
    | Clicked_Vote
    | Clicked_RevealVotes
    | Clicked_ResetVotes
    | Clicked_LeaveRoom
    | Changed_PendingName String
    | Changed_PendingVote String


type BackendMsg
    = NoOpBackendMsg


type ToFrontend
    = RoomCreated Room
    | RoomUpdated Room
    | GotCurrentRoom CurrentRoom
    | GotUserId User.Id


type ToBackend
    = CreateRoom
    | UpdateRoom Room
    | Vote CurrentRoom User.Id String
    | GetCurrentRoom String
    | GetUserId
