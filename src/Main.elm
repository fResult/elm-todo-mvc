module Main exposing (main, unwords)

import Browser
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
            [ { id = "1794737613522", text = "Redesign Website", completed = False, editing = False }
            , { id = "1794737200701", text = "Do some nerdy stuff", completed = True, editing = False }
            ]
    in
    { todoText = ""
    , tasks = initialTasks
    , visibility = AllTasks
    }


type alias Model =
    { todoText : String
    , tasks : List Task
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
    | TaskToggled TaskId Bool
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
            filterTasks model.visibility model.tasks
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
            []
            [ input [ value model.todoText, placeholder "What need to be done?", onInput TodoTextInputChanged, onEnter TaskCreateRequested ] []
            , ul [] (List.map toRenderedTaskItemWithCheckbox displayedTasks)
            , div
                [ class "todo-list--footer"
                , style "width" "100%"
                , style "display" "flex"
                , style "justify-content" "space-between"
                ]
                [ p [] [ text (itemsLeftMessageFor (activeTasksFor model.tasks)) ]
                , div [ class "button-group", style "display" "flex", style "align-items" "center" ]
                    [ button [ onClick AllTasksDisplayed ] [ text "All" ]
                    , button [ onClick ActiveTasksDisplayed ] [ text "Active" ]
                    , button [ onClick CompletedTasksDisplayed ] [ text "Completed" ]
                    ]
                ]
            ]
        ]


toRenderedTaskItemWithCheckbox : Task -> Html Msg
toRenderedTaskItemWithCheckbox task =
    li []
        [ input [ id task.id, type_ "checkbox", checked task.completed, onCheck (TaskToggled task.id) ] []
        , label [ for task.id ]
            [ p
                [ style "display" "inline", lineThroughWhenCompletedFor task ]
                [ text task.text
                , button
                    [ style "padding" "4px"
                    , ariaLabel "Remove Task"
                    , onClick (TaskRemoved task.id)
                    ]
                    [ text "🗑️" ]
                ]
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
        TaskToggled targetId isChecked ->
            ( { model | tasks = toggleTaskStatusFor targetId isChecked model.tasks }, Cmd.none )

        TodoTextInputChanged newText ->
            ( { model | todoText = newText }, Cmd.none )

        TaskCreateRequested ->
            ( model, Time.now |> ElmTask.perform TimeReceivedForNewTask )

        TimeReceivedForNewTask currentTime ->
            update (TaskCreated (prepareTask model.todoText currentTime)) model

        TaskCreated task ->
            ( addTask task model, Cmd.none )

        TaskRemoved targetId ->
            ( { model | tasks = discardTaskFor targetId model.tasks }, Cmd.none )

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
            activeTasksFor tasks

        CompletedTasks ->
            List.filter isTaskCompleted tasks


activeTasksFor : List Task -> List Task
activeTasksFor tasks =
    List.filter isTaskActive tasks


isTaskCompleted : Task -> Bool
isTaskCompleted task =
    task.completed == True


isTaskActive : Task -> Bool
isTaskActive =
    not << isTaskCompleted


discardTaskFor : TaskId -> List Task -> List Task
discardTaskFor targetId tasks =
    List.filter (keepIfNotMatchFor targetId) tasks


keepIfNotMatchFor : TaskId -> Task -> Bool
keepIfNotMatchFor targetId task =
    task.id /= targetId


toggleTaskStatusFor : String -> Bool -> List Task -> List Task
toggleTaskStatusFor targetId isChecked tasks =
    let
        toggleStatusIfMatch task =
            if task.id == targetId then
                { task | completed = isChecked }

            else
                task
    in
    List.map toggleStatusIfMatch tasks


prepareTask : String -> Time.Posix -> Task
prepareTask todoText =
    flip createTaskFor todoText << idFromTime


createTaskFor : TaskId -> String -> Task
createTaskFor id todoText =
    { id = id, text = todoText, completed = False, editing = False }


addTask : Task -> Model -> Model
addTask newTask model =
    { model | tasks = newTask :: model.tasks, todoText = "" }


itemsLeftMessageFor : List Task -> String
itemsLeftMessageFor tasks =
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
