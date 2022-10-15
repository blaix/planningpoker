module Types exposing (..)

import Browser exposing (UrlRequest)
import Browser.Navigation exposing (Key)
import Dict exposing (Dict)
import Lamdera exposing (SessionId)
import Url exposing (Url)


type alias FrontendModel =
    { key : Key
    , room : CurrentRoom
    , userId : Maybe UserId
    , pendingUserName : String
    , pendingVote : String
    }


type alias BackendModel =
    { rooms : Dict Slug Room
    , idCounter : Int
    , userIds : Dict SessionId UserId
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
    | GotUserId (Maybe UserId)


type ToBackend
    = CreateRoom
    | UpdateRoom Room
    | GetCurrentRoom String
    | GetUserId


type CurrentRoom
    = CurrentRoom Room
    | LoadingRoom
    | RoomNotFound
    | HomeRoom


type alias Room =
    { slug : Slug
    , members : Dict UserId UserName
    , votes : Dict UserId String
    , revealVotes : Bool
    }


type alias UserId =
    String


type alias UserName =
    String


type alias Slug =
    String
