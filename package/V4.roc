module [fromU128]

import Uuid exposing [Uuid]

fromU128 : U128 -> Uuid
fromU128 = \int ->
    Uuid.fromU128 int
    |> Uuid.setVersion V4
    |> Uuid.setVariant

expect
    fromU128 0
    |> Uuid.toStr
    == "00000000-0000-4000-8000-000000000000"
