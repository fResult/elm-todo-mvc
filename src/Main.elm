module Main exposing (main)

import Browser
import Html exposing (Html, h1, text)


main : Program () Model Msg
main =
    Browser.sandbox
        { init = init
        , view = view
        , update = update
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
    , displayedTasks = initialTasks
    }


type alias Model =
    { todoText : String
    , tasks : List Task
    , displayedTasks : List Task
    }


type alias Task =
    { id : String
    , text : String
    , completed : Bool
    , editing : Bool
    }


type Msg
    = TodoTextInputChanged String
    | TaskAdded
    | TaskToggled
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
    h1
        [ style "font-size" "80px"
        , style "font-weight" "200"
        , style "color" "#b83f45"
        , style "text-transform" "uppercase"
        ]
        [ text "Todos" ]



--------------
--- UPDATE ---
--------------


update : Msg -> Model -> Model
update msg model =
    case msg of
        _ ->
            model
