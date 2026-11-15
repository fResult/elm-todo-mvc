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
