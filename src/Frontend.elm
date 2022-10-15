module Frontend exposing (..)

import Browser exposing (UrlRequest(..))
import Browser.Navigation as Nav
import Dict
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Event
import Lamdera exposing (sendToBackend)
import Room exposing (CurrentRoom(..), Room)
import Types exposing (..)
import Url
import User


type alias Model =
    FrontendModel


app :
    { init : Lamdera.Url -> Nav.Key -> ( Model, Cmd FrontendMsg )
    , view : Model -> Browser.Document FrontendMsg
    , update : FrontendMsg -> Model -> ( Model, Cmd FrontendMsg )
    , updateFromBackend : ToFrontend -> Model -> ( Model, Cmd FrontendMsg )
    , subscriptions : Model -> Sub FrontendMsg
    , onUrlRequest : UrlRequest -> FrontendMsg
    , onUrlChange : Url.Url -> FrontendMsg
    }
app =
    Lamdera.frontend
        { init = init
        , onUrlRequest = UrlClicked
        , onUrlChange = UrlChanged
        , update = update
        , updateFromBackend = updateFromBackend
        , subscriptions = \_ -> Sub.none
        , view = view
        }


init : Url.Url -> Nav.Key -> ( Model, Cmd FrontendMsg )
init url key =
    let
        slug =
            String.dropLeft 1 url.path

        ( currentRoom, getRoomMsg ) =
            if slug == "" then
                ( HomeRoom, Cmd.none )

            else
                ( LoadingRoom
                , sendToBackend (GetCurrentRoom slug)
                )
    in
    ( { key = key
      , room = currentRoom
      , userId = ""
      , pendingUserName = ""
      , pendingVote = ""
      }
    , Cmd.batch
        [ sendToBackend GetUserId
        , getRoomMsg
        ]
    )


update : FrontendMsg -> Model -> ( Model, Cmd FrontendMsg )
update msg model =
    case msg of
        UrlClicked urlRequest ->
            case urlRequest of
                Internal url ->
                    ( model
                    , Nav.pushUrl model.key (Url.toString url)
                    )

                External url ->
                    ( model
                    , Nav.load url
                    )

        UrlChanged _ ->
            ( model, Cmd.none )

        Clicked_CreateRoom ->
            ( { model | room = LoadingRoom }
            , sendToBackend CreateRoom
            )

        Changed_PendingName name ->
            ( { model | pendingUserName = name }
            , Cmd.none
            )

        Changed_PendingVote vote ->
            ( { model | pendingVote = vote }
            , Cmd.none
            )

        Clicked_Vote ->
            ( { model | room = Room.vote model.room model.userId model.pendingVote }
            , sendToBackend (Vote model.room model.userId model.pendingVote)
            )

        Clicked_JoinRoom ->
            case model.room of
                CurrentRoom room ->
                    let
                        newMembers =
                            room.members
                                |> Dict.insert model.userId model.pendingUserName

                        newRoom =
                            { room | members = newMembers }
                    in
                    ( { model | room = CurrentRoom newRoom }
                    , sendToBackend (UpdateRoom newRoom)
                    )

                _ ->
                    ( model, Cmd.none )

        Clicked_RevealVotes ->
            case model.room of
                CurrentRoom room ->
                    let
                        newRoom =
                            { room | revealVotes = True }
                    in
                    ( { model | room = CurrentRoom newRoom }
                    , sendToBackend (UpdateRoom newRoom)
                    )

                _ ->
                    ( model, Cmd.none )

        Clicked_ResetVotes ->
            case model.room of
                CurrentRoom room ->
                    let
                        newRoom =
                            { room
                                | votes = Dict.empty
                                , revealVotes = False
                            }
                    in
                    ( { model | room = CurrentRoom newRoom }
                    , sendToBackend (UpdateRoom newRoom)
                    )

                _ ->
                    ( model, Cmd.none )

        Clicked_LeaveRoom ->
            -- TODO: also remove user on disconnect
            let
                backendMsg =
                    case model.room of
                        CurrentRoom room ->
                            let
                                newRoom =
                                    { room | members = Dict.remove model.userId room.members }
                            in
                            sendToBackend (UpdateRoom newRoom)

                        _ ->
                            Cmd.none
            in
            ( { model | room = HomeRoom }
            , Cmd.batch
                [ Nav.pushUrl model.key "/"
                , backendMsg
                ]
            )


updateFromBackend : ToFrontend -> Model -> ( Model, Cmd FrontendMsg )
updateFromBackend msg model =
    case msg of
        RoomCreated room ->
            ( { model | room = CurrentRoom room }
            , Nav.pushUrl model.key ("/" ++ room.slug)
            )

        RoomUpdated room ->
            ( { model | room = updateCurrentRoom room model.room }
            , Cmd.none
            )

        GotCurrentRoom currentRoom ->
            ( { model | room = currentRoom }
            , Cmd.none
            )

        GotUserId userId ->
            ( { model | userId = userId }
            , Cmd.none
            )


updateCurrentRoom : Room -> CurrentRoom -> CurrentRoom
updateCurrentRoom newRoom currentRoom =
    case currentRoom of
        CurrentRoom room ->
            if room.slug == newRoom.slug then
                CurrentRoom newRoom

            else
                currentRoom

        _ ->
            currentRoom


view : Model -> Browser.Document FrontendMsg
view model =
    { title = ""
    , body =
        [ Html.node "link" [ Attr.rel "stylesheet", Attr.href "/styles.css" ] []
        , Html.header []
            [ Html.h1 [] [ Html.text "Planning Poker" ] ]
        , Html.main_ []
            [ case model.room of
                HomeRoom ->
                    viewHomeRoom model

                RoomNotFound ->
                    Html.div []
                        [ Html.p [] [ Html.text "Uh oh! Can't find a room with that id." ]
                        , viewHomeRoom model
                        ]

                LoadingRoom ->
                    Html.text "Loading your room..."

                CurrentRoom room ->
                    viewRoom room model
            ]
        , Html.footer []
            [ Html.div []
                [ Html.text "Created by "
                , Html.a [ Attr.href "https://twitter.com/blaix" ] [ Html.text "@blaix" ]
                ]
            , Html.div [ Attr.style "font-style" "italic" ]
                [ Html.text "Super beta and probably buggy" ]
            , Html.div []
                [ Html.a [ Attr.href "https://github.com/blaix/planningpoker" ] [ Html.text "Source" ]
                ]
            ]
        ]
    }


viewHomeRoom : Model -> Html FrontendMsg
viewHomeRoom model =
    Html.button [ Event.onClick Clicked_CreateRoom ]
        [ Html.text <|
            if model.room == LoadingRoom then
                "CREATING..."

            else
                "CREATE ROOM"
        ]


viewRoom : Room -> Model -> Html FrontendMsg
viewRoom room model =
    Html.div [ Attr.style "text-align" "center" ] <|
        [ Html.h2 [] [ Html.text ("Room " ++ room.slug) ]
        , Html.table [] <|
            (Html.thead []
                [ Html.tr []
                    [ Html.th [] [ Html.text "Member" ]
                    , Html.th [] [ Html.text "Points" ]
                    ]
                ]
                :: (room.members
                        |> Dict.toList
                        |> List.sortBy Tuple.second
                        |> List.map (viewMemberRow room model)
                   )
            )
        , if Dict.member model.userId room.members then
            viewVoteForm

          else
            viewJoinForm
        , Html.p [ Attr.class "btnGroup" ] <|
            [ Html.button [ Event.onClick Clicked_RevealVotes ] [ Html.text "Reveal Votes" ]
            , Html.button [ Event.onClick Clicked_ResetVotes ] [ Html.text "Reset Votes" ]

            -- TODO: handle tab closing as Leaving
            , Html.button [ Event.onClick Clicked_LeaveRoom ] [ Html.text "Leave Room" ]
            ]
        ]


viewMemberRow : Room -> Model -> ( User.Id, User.Name ) -> Html FrontendMsg
viewMemberRow room model ( userId, userName ) =
    let
        voteDisplay =
            case Dict.get userId room.votes of
                Nothing ->
                    ""

                Just vote ->
                    if userId == model.userId || room.revealVotes then
                        vote

                    else
                        "✅"
    in
    Html.tr []
        [ Html.td []
            [ if userId == model.userId then
                Html.strong [] [ Html.text userName ]

              else
                Html.text userName
            ]
        , Html.td [ Attr.style "text-align" "center" ] [ Html.text voteDisplay ]
        ]


viewJoinForm : Html FrontendMsg
viewJoinForm =
    Html.p []
        [ Html.label [] [ Html.text "Your Name: " ]
        , Html.input
            [ Attr.type_ "text"
            , Event.onInput Changed_PendingName
            ]
            []
        , Html.button
            [ Event.onClick Clicked_JoinRoom
            ]
            [ Html.text "Join" ]
        ]


viewVoteForm : Html FrontendMsg
viewVoteForm =
    Html.div []
        [ Html.input
            [ Attr.type_ "number"
            , Event.onInput Changed_PendingVote
            ]
            []
        , Html.button
            [ Attr.class "primary"
            , Event.onClick Clicked_Vote
            ]
            [ Html.text "Vote" ]
        ]
