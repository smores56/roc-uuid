module [sha1]

# Note 1: All variables are unsigned 32-bit quantities and wrap modulo 232 when calculating, except for
#         ml, the message length, which is a 64-bit quantity, and
#         hh, the message digest, which is a 160-bit quantity.
# Note 2: All constants in this pseudo code are in big endian.
#         Within each word, the most significant byte is stored in the leftmost byte position

# Initialize variables:

sha1 : Str -> List U8
sha1 = \message ->
    messageLength =
        List.len bytes
        |> Num.mul 8

    bytes =
        message
        |> Str.toUtf8
        |> List.append 0x80

    chunkSize = 64
    chunkCount =
        List.len bytes
        |> Num.divCeil chunkSize

    # Pre-processing:
    # append the bit '1' to the message e.g. by adding 0x80 if message length is a multiple of 8 bits.
    # append 0 ≤ k < 512 bits '0', such that the resulting message length in bits
    #    is congruent to −64 ≡ 448 (mod 512)
    # append ml, the original message length in bits, as a 64-bit big-endian integer.
    #    Thus, the total length is a multiple of 512 bits.
    chunks =
        List.range { start: At 0, end: Before chunkCount }
        |> List.map \chunkIndex ->
            chunkBytes =
                bytes
                |> List.sublist { start: chunkIndex * chunkSize, len: chunkSize }
            bufferLength =
                chunkSize - List.len chunkBytes

            chunkBytes
            |> List.concat (List.repeat 0 bufferLength)

    baseHash =
        (0x67452301, 0xefcdab89, 0x98badcfe, 0x10325476, 0xc3d2e1f0)

    (hash1, hash2, hash3, hash4, hash5) =
        chunks
        |> List.walk baseHash \(a, b, c, d, e), _chunk ->
            (a, b, c, d, e)

    # Process the message in successive 512-bit chunks:
    # break message into 512-bit chunks
    # for each chunk
    #     break chunk into sixteen 32-bit big-endian words w[i], 0 ≤ i ≤ 15

    #     Message schedule: extend the sixteen 32-bit words into eighty 32-bit words:
    #     for i from 16 to 79
    #         Note 3: SHA-0 differs by not having this leftrotate.
    #         w[i] = (w[i-3] xor w[i-8] xor w[i-14] xor w[i-16]) leftrotate 1

    #     Initialize hash value for this chunk:
    #     a = h0
    #     b = h1
    #     c = h2
    #     d = h3
    #     e = h4

    #     Main loop:[3][57]
    #     for i from 0 to 79
    #         if 0 ≤ i ≤ 19 then
    #             f = (b and c) or ((not b) and d)
    #             k = 0x5A827999
    #         else if 20 ≤ i ≤ 39
    #             f = b xor c xor d
    #             k = 0x6ED9EBA1
    #         else if 40 ≤ i ≤ 59
    #             f = (b and c) or (b and d) or (c and d)
    #             k = 0x8F1BBCDC
    #         else if 60 ≤ i ≤ 79
    #             f = b xor c xor d
    #             k = 0xCA62C1D6

    #         temp = (a leftrotate 5) + f + e + k + w[i]
    #         e = d
    #         d = c
    #         c = b leftrotate 30
    #         b = a
    #         a = temp

    #     Add this chunk's hash to result so far:
    #     h0 = h0 + a
    #     h1 = h1 + b
    #     h2 = h2 + c
    #     h3 = h3 + d
    #     h4 = h4 + e

    [hash1, hash2, hash3, hash4, hash5]
    |> List.joinMap \int ->
        [
            int |> Num.shiftRightZfBy 24,
            int |> Num.shiftRightZfBy 16,
            int |> Num.shiftRightZfBy 8,
            int,
        ]
        |> List.map Num.toU8

# break chunk into sixteen 32-bit big-endian words w[i], 0 ≤ i ≤ 15
breakChunkIntoBytePairs : List U8 -> List (U8, U8)
breakChunkIntoBytePairs = \bytes ->
    getByte = \index ->
        bytes
        |> List.get index
        |> Result.withDefault 0

    List.range { start: At 0, end: Before (List.len bytes // 2) }
    |> List.map \index ->
        (getByte (index * 2), getByte (index * 2 + 1))

