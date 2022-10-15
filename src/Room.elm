module Room exposing (CurrentRoom(..), Room, Slug, vote)

import Dict exposing (Dict)
import User


type alias Room =
    { slug : Slug
    , members : Dict User.Id User.Name
    , votes : Dict User.Id String
    , revealVotes : Bool
    }


type alias Slug =
    String


type CurrentRoom
    = CurrentRoom Room
    | LoadingRoom
    | RoomNotFound
    | HomeRoom


vote : CurrentRoom -> User.Id -> String -> CurrentRoom
vote currentRoom userId userVote =
    case currentRoom of
        CurrentRoom room ->
            let
                newVotes =
                    Dict.insert userId userVote room.votes
            in
            CurrentRoom { room | votes = newVotes }

        _ ->
            currentRoom
