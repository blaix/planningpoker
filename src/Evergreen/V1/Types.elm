module Evergreen.V1.Types exposing (..)

import Browser
import Browser.Navigation
import Dict
import Lamdera
import Url


type alias Slug =
    String


type alias UserId =
    String


type alias UserName =
    String


type alias Room =
    { slug : Slug
    , members : Dict.Dict UserId UserName
    , votes : Dict.Dict UserId (Maybe Int)
    , revealVotes : Bool
    }


type CurrentRoom
    = CurrentRoom Room
    | LoadingRoom
    | RoomNotFound
    | HomeRoom


type alias FrontendModel =
    { key : Browser.Navigation.Key
    , room : CurrentRoom
    , userId : Maybe UserId
    , pendingUserName : String
    , pendingVote : String
    }


type alias BackendModel =
    { rooms : Dict.Dict Slug Room
    , idCounter : Int
    , userIds : Dict.Dict Lamdera.SessionId UserId
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | Clicked_CreateRoom
    | Clicked_JoinRoom
    | Clicked_Vote
    | Clicked_RevealVotes
    | Clicked_ResetVotes
    | Clicked_LeaveRoom
    | Changed_PendingName String
    | Changed_PendingVote String


type ToBackend
    = CreateRoom
    | UpdateRoom Room
    | GetCurrentRoom String
    | GetUserId


type BackendMsg
    = NoOpBackendMsg


type ToFrontend
    = RoomCreated Room
    | RoomUpdated Room
    | GotCurrentRoom CurrentRoom
    | GotUserId (Maybe UserId)
