module Main exposing (main, unwords)

import Browser
import Dict exposing (Dict)
import Html exposing (Html, button, div, h1, input, label, li, p, section, text, ul)
import Html.Attributes exposing (checked, class, for, id, placeholder, style, type_, value)
import Html.Attributes.Aria exposing (ariaLabel)
import Html.Events exposing (onCheck, onClick, onInput)
import Html.Events.Extra exposing (onEnter)
import Task as ElmTask
import Time


main : Program () Model Msg
main =
    Browser.element
        { init = \_ -> ( init, Cmd.none )
        , view = view
        , update = update
        , subscriptions = \_ -> Sub.none
        }



--------------
--- MODELS ---
--------------


init : Model
init =
    let
        initialTasks =
            Dict.fromList
                [ ( "1794737613522", { id = "1794737613522", text = "Redesign Website", completed = False, editing = False } )
                , ( "1794737200701", { id = "1794737200701", text = "Do some nerdy stuff", completed = True, editing = False } )
                , ( "1794737890123", { id = "1794737890123", text = "Buy milk and coffee beans", completed = False, editing = False } )
                , ( "1794738123456", { id = "1794738123456", text = "Write unit tests for Elm architecture", completed = False, editing = True } )
                , ( "1794739567890", { id = "1794739567890", text = "Review pull requests", completed = True, editing = False } )
                ]
    in
    { todoText = ""
    , tasks = initialTasks
    , visibility = AllTasks
    }


type alias Model =
    { todoText : String
    , tasks : Dict TaskId Task
    , visibility : TaskVisibility
    }


type alias Task =
    { id : String
    , text : String
    , completed : Bool
    , editing : Bool
    }


type alias TaskId =
    String


type TaskVisibility
    = AllTasks
    | ActiveTasks
    | CompletedTasks


type Msg
    = TodoTextInputChanged String
    | TaskCreateRequested
    | TaskCreated Task
    | TimeReceivedForNewTask Time.Posix
    | TaskStatusToggled TaskId Bool
    | TaskEditing TaskId
    | TaskEdited TaskId String
    | TaskEditCancelled
    | TaskRemoved TaskId
    | CompletedTasksRemoved
    | ActiveTasksDisplayed
    | CompletedTasksDisplayed
    | AllTasksDisplayed



-------------
--- VIEWS ---
-------------


view : Model -> Html Msg
view model =
    let
        displayedTasks =
            filterTasks model.visibility (Dict.values model.tasks)
    in
    div
        [ style "display" "flex"
        , style "flex-direction" "column"
        , style "align-items" "center"
        , style "justify-content" "center"
        ]
        [ h1
            [ style "font-size" "80px"
            , style "font-weight" "200"
            , style "color" "#B83F45"
            , style "text-transform" "uppercase"
            ]
            [ text "Todos" ]
        , section
            [ style "min-width" "375px"
            , style "display" "flex"
            , style "flex-direction" "column"
            , style "align-items" "center"
            , style "gap" "8px"
            ]
            [ input
                [ id "todo-text"
                , placeholder "What need to be done?"
                , ariaLabel "Todo Text"
                , onInput TodoTextInputChanged
                , onEnter TaskCreateRequested
                , value model.todoText
                ]
                []
            , ul [ style "list-style" "none", style "display" "flex", style "flex-direction" "column", style "gap" "4px" ]
                (List.map toRenderedTaskItemWithCheckbox displayedTasks)
            , div
                [ class "todo-list--footer"
                , style "width" "100%"
                , style "display" "flex"
                , style "justify-content" "space-between"
                , style "align-items" "center"
                ]
                [ p [ style "margin" "0" ] [ text (Dict.values model.tasks |> activeTasks |> itemsLeftMessage) ]
                , div [ class "button-group", style "display" "flex", style "align-items" "center" ]
                    [ button [ onClick AllTasksDisplayed ] [ text "All" ]
                    , button [ onClick ActiveTasksDisplayed ] [ text "Active" ]
                    , button [ onClick CompletedTasksDisplayed ] [ text "Completed" ]
                    ]
                , button [ onClick CompletedTasksRemoved ] [ text "Clear completed" ]
                ]
            ]
        ]


toRenderedTaskItemWithCheckbox : Task -> Html Msg
toRenderedTaskItemWithCheckbox task =
    li [ class "todo-item" ]
        [ div [ class "todo-item__container", style "display" "flex" ]
            [ label
                [ class "todo-item__toggling-wrapper"
                , for task.id
                , style "cursor" "pointer"
                , style "padding" "8px 12px"
                , style "display" "flex"
                , style "gap" "4px"
                ]
                [ input
                    [ id task.id
                    , class "todo-item__checkbox"
                    , type_ "checkbox"
                    , checked task.completed
                    , onCheck (TaskStatusToggled task.id)
                    ]
                    []
                , p [ class "todo-item__text", style "display" "inline", style "margin" "0", lineThroughWhenCompletedFor task ]
                    [ text task.text ]
                ]
            , button
                [ class "todo-item__remove-btn"
                , style "padding" "4px"
                , ariaLabel "Remove Task"
                , onClick (TaskRemoved task.id)
                ]
                [ text "🗑️" ]
            ]
        ]


lineThroughWhenCompletedFor : Task -> Html.Attribute Msg
lineThroughWhenCompletedFor task =
    style "text-decoration"
        (if task.completed then
            "line-through"

         else
            "none"
        )



--------------
--- UPDATE ---
--------------


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        TaskStatusToggled targetId isChecked ->
            ( { model | tasks = toggleTaskStatusFor targetId isChecked model.tasks }, Cmd.none )

        TodoTextInputChanged newText ->
            ( { model | todoText = newText }, Cmd.none )

        TaskCreateRequested ->
            ( model, Time.now |> ElmTask.perform TimeReceivedForNewTask )

        TimeReceivedForNewTask currentTime ->
            update (TaskCreated (prepareTask model.todoText currentTime)) model

        TaskCreated task ->
            ( { model | tasks = addTask task model.tasks, todoText = "" }, Cmd.none )

        TaskRemoved targetId ->
            ( { model | tasks = discardTaskFor targetId model.tasks }, Cmd.none )

        CompletedTasksRemoved ->
            ( { model | tasks = discardCompletedTasks model.tasks }, Cmd.none )

        AllTasksDisplayed ->
            ( { model | visibility = AllTasks }, Cmd.none )

        ActiveTasksDisplayed ->
            ( { model | visibility = ActiveTasks }, Cmd.none )

        CompletedTasksDisplayed ->
            ( { model | visibility = CompletedTasks }, Cmd.none )

        _ ->
            ( model, Cmd.none )



----------------
--- HANDLERS ---
----------------


filterTasks : TaskVisibility -> List Task -> List Task
filterTasks visibility tasks =
    case visibility of
        AllTasks ->
            tasks

        ActiveTasks ->
            activeTasks tasks

        CompletedTasks ->
            List.filter isTaskCompleted tasks


activeTasks : List Task -> List Task
activeTasks tasks =
    List.filter isTaskActive tasks


isTaskCompleted : Task -> Bool
isTaskCompleted =
    .completed


isTaskActive : Task -> Bool
isTaskActive =
    not << isTaskCompleted


discardTaskFor : TaskId -> Dict TaskId Task -> Dict TaskId Task
discardTaskFor  =
    Dict.remove


discardCompletedTasks : Dict TaskId Task -> Dict TaskId Task
discardCompletedTasks tasks =
    Dict.filter (always isTaskActive) tasks


toggleTaskStatusFor : String -> Bool -> Dict TaskId Task -> Dict TaskId Task
toggleTaskStatusFor targetId isChecked tasks =
    Dict.update targetId (toggleStatus isChecked) tasks


toggleStatus : Bool -> Maybe Task -> Maybe Task
toggleStatus isChecked maybeTask =
    case maybeTask of
        Just task ->
            Just { task | completed = isChecked }

        _ ->
            Nothing


prepareTask : String -> Time.Posix -> Task
prepareTask todoText =
    flip createTaskFor todoText << idFromTime


createTaskFor : TaskId -> String -> Task
createTaskFor id todoText =
    { id = id, text = todoText, completed = False, editing = False }


addTask : Task -> Dict TaskId Task -> Dict TaskId Task
addTask newTask tasks =
    Dict.insert newTask.id newTask tasks


itemsLeftMessage : List Task -> String
itemsLeftMessage tasks =
    let
        count =
            List.length tasks

        words =
            [ String.fromInt count, pluralizeRegular "item" count, "left" ]
    in
    unwords words



-------------
--- UTILS ---
-------------


idFromTime : Time.Posix -> String
idFromTime =
    String.fromInt << Time.posixToMillis



{- flip from standard library was removed for some reasons -}


flip : (a -> b -> c) -> (b -> a -> c)
flip f a b =
    f b a


{-| Returns the word with a trailing "s" if count is not 1.

    NOTE: This is only for regular nouns that add "s" directly.
    Do not use this for irregular words (e.g., child -> children, fish -> fish)
    or words requiring spelling rule changes (e.g., spy -> spies, bus -> buses).

-}
pluralizeRegular : String -> Int -> String
pluralizeRegular text count =
    if count == 1 then
        text

    else
        text ++ "s"


unwords : List String -> String
unwords =
    String.join " "
