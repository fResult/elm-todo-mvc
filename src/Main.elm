--------------
--- MODELS ---
--------------


type alias Model =
    { todoText : String
    , tasks : List Task
    }


type alias Task =
    { text : String
    , completed : Bool
    , editing : Bool
    }
