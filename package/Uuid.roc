module [
    Uuid,
    Version,
    fromU128,
    toU128,
    fromBytes,
    toStr,
    setVersion,
    getVersion,
    setVariant,
    nil,
    max,
]

# Saving UUIDs to binary format is done by sequencing all fields in big-endian format.
#
## A universally unique identifier, as specified by the IETF.
##
## <https://www.ietf.org/id/draft-ietf-uuidrev-rfc4122bis-14.html>
Uuid := U128 implements [Eq]

Version : [V1, V2, V3, V4, V5, V6, V7, V8]

nil = @Uuid 0
max = @Uuid Num.maxU128

zeroAscii = 48
lowerAAscii = 97
dashAscii = 45
uuidStrLength = 36

fromU128 : U128 -> Uuid
fromU128 = @Uuid

toU128 : Uuid -> U128
toU128 = \@Uuid uuid -> uuid

rollUpBytesIntoUuid = \remaining ->
    when remaining is
        [] -> 0
        [.. as rest, last] ->
            rollUpBytesIntoUuid rest
            |> Num.shiftLeftBy 8
            |> Num.add (Num.toU128 last)

fromBytes : List U8 -> Result Uuid [IncorrectByteCount]
fromBytes = \bytes ->
    if List.len bytes == 16 then
        Ok (@Uuid (rollUpBytesIntoUuid bytes))
    else
        Err IncorrectByteCount

byteToHexUtf8 : U8 -> List U8
byteToHexUtf8 = \byte ->
    toHexUtf8 = \val ->
        if val < 10 then
            val + zeroAscii
        else
            val - 10 + lowerAAscii

    left = byte |> Num.shiftRightZfBy 4
    right = byte |> Num.rem 16

    [toHexUtf8 left, toHexUtf8 right]

# TODO: what type should byte be?
setByteAt : Uuid, U8, U8 -> Uuid
setByteAt = \@Uuid uuid, byte, index ->
    bitOffset = 120 - 8 * index
    zeroMask =
        255
        |> Num.shiftLeftBy bitOffset
        |> Num.bitwiseNot
    byteMask =
        byte
        |> Num.toU128
        |> Num.shiftLeftBy bitOffset

    uuid
    |> Num.bitwiseAnd zeroMask
    |> Num.bitwiseOr byteMask
    |> @Uuid

getByteAt : Uuid, U8 -> Result U8 [OutOfBounds]
getByteAt = \@Uuid uuid, index ->
    if index > 16 then
        Err OutOfBounds
    else
        bitOffset = 120 - 8 * index

        uuid
        |> Num.shiftRightZfBy bitOffset
        |> Num.toU8
        |> Ok

setVersion : Uuid, Version -> Uuid
setVersion = \uuid, version ->
    versionByte =
        when version is
            V1 -> 0x10
            V2 -> 0x20
            V3 -> 0x30
            V4 -> 0x40
            V5 -> 0x50
            V6 -> 0x60
            V7 -> 0x70
            V8 -> 0x80

    uuid
    |> setByteAt versionByte 6
    |> setByteAt 0 7 # TODO: is this necessary?

getVersion : Uuid -> Result Version [UnknownVersion]
getVersion = \uuid ->
    versionByte =
        uuid
        |> getByteAt 6
        |> Result.withDefault 0

    when versionByte is
        0x10 -> Ok V1
        0x20 -> Ok V2
        0x30 -> Ok V3
        0x40 -> Ok V4
        0x50 -> Ok V5
        0x60 -> Ok V6
        0x70 -> Ok V7
        0x80 -> Ok V8
        _other -> Err UnknownVersion

setVariant : Uuid -> Uuid
setVariant = \@Uuid uuid ->
    bitOffset = 62
    zeroMask =
        3
        |> Num.shiftLeftBy bitOffset
        |> Num.bitwiseNot
    byteMask =
        2
        |> Num.shiftLeftBy bitOffset

    uuid
    |> Num.bitwiseAnd zeroMask
    |> Num.bitwiseOr byteMask
    |> @Uuid

toStr : Uuid -> Str
toStr = \@Uuid uuid ->
    octetHexUtf8 = \index ->
        uuid
        |> Num.shiftRightZfBy (120 - index * 8)
        |> Num.rem 256
        |> Num.toU8
        |> byteToHexUtf8

    List.withCapacity uuidStrLength
    |> List.concat (octetHexUtf8 0)
    |> List.concat (octetHexUtf8 1)
    |> List.concat (octetHexUtf8 2)
    |> List.concat (octetHexUtf8 3)
    |> List.append dashAscii
    |> List.concat (octetHexUtf8 4)
    |> List.concat (octetHexUtf8 5)
    |> List.append dashAscii
    |> List.concat (octetHexUtf8 6)
    |> List.concat (octetHexUtf8 7)
    |> List.append dashAscii
    |> List.concat (octetHexUtf8 8)
    |> List.concat (octetHexUtf8 9)
    |> List.append dashAscii
    |> List.concat (octetHexUtf8 10)
    |> List.concat (octetHexUtf8 11)
    |> List.concat (octetHexUtf8 12)
    |> List.concat (octetHexUtf8 13)
    |> List.concat (octetHexUtf8 14)
    |> List.concat (octetHexUtf8 15)
    |> Str.fromUtf8
    |> Result.withDefault ""

expect toStr nil == "00000000-0000-0000-0000-000000000000"
expect toStr max == "ffffffff-ffff-ffff-ffff-ffffffffffff"

expect
    @Uuid 339896630043467510691065695327037234084
    |> toStr
    == "ffb5b5b4-1f61-48fc-a627-e00cc8211ba4"

expect
    nil
    |> setVersion V4
    |> toStr
    == "00000000-0000-4000-0000-000000000000"

expect
    Num.maxU8
    |> List.repeat 16
    |> fromBytes
    == Ok max

expect
    Num.maxU8
    |> List.repeat 17
    |> fromBytes
    == Err IncorrectByteCount

expect
    rollUpBytesIntoUuid [0x12, 0x34, 0x56, 0x78]
    == 0x12345678
