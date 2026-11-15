module Main exposing (main)

import Browser
import Html exposing (Html, div, h1, input, label, li, p, section, text, ul)
import Html.Attributes exposing (checked, for, id, placeholder, style, type_, value)
import Html.Events exposing (onCheck, onInput)
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
    }


type alias Model =
    { todoText : String
    , tasks : List Task
    }


type alias Task =
    { id : String
    , text : String
    , completed : Bool
    , editing : Bool
    }


type Msg
    = TodoTextInputChanged String
    | TaskAddRequested
    | TaskAdded Time.Posix String
    | TaskToggled String Bool
    | TaskEditing
    | TaskRemoved
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
            model.tasks
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
            , style "color" "#b83f45"
            , style "text-transform" "uppercase"
            ]
            [ text "Todos" ]
        , section
            []
            [ input [ value model.todoText, placeholder "What need to be done?", onInput TodoTextInputChanged, onEnter TaskAddRequested ] []
            , ul [] (List.map toRenderedTaskItemWithCheckbox displayedTasks)
            ]
        ]


toRenderedTaskItemWithCheckbox : Task -> Html Msg
toRenderedTaskItemWithCheckbox task =
    li []
        [ input [ id task.id, type_ "checkbox", checked task.completed, onCheck (TaskToggled task.id) ] []
        , label [ for task.id ]
            [ p
                [ style "display" "inline", lineThroughWhenCompletedFor task ]
                [ text task.text ]
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
            let
                toggleStatusIfMatch task =
                    if task.id == targetId then
                        { task | completed = isChecked }

                    else
                        task
            in
            ( { model | tasks = List.map toggleStatusIfMatch model.tasks }, Cmd.none )

        TodoTextInputChanged newText ->
            ( { model | todoText = newText }, Cmd.none )

        TaskAddRequested ->
            ( model, ElmTask.perform (\time -> TaskAdded time model.todoText) Time.now )

        TaskAdded time newText ->
            let
                idFromTime =
                    (String.fromInt << Time.posixToMillis) time

                newTask =
                    { id = idFromTime, text = newText, completed = False, editing = False }
            in
            ( { model
                | tasks = newTask :: model.tasks
                , todoText = ""
              }
            , Cmd.none
            )

        _ ->
            ( model, Cmd.none )
