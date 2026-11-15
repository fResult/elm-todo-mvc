--------------
--- MODELS ---
--------------


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
