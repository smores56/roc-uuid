module [V1Params, newV1]

import Uuid

##  0                   1                   2                   3
##  0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
## +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
## |                           time_low                            |
## +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
## |           time_mid            |  ver  |       time_high       |
## +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
## |var|         clock_seq         |             node              |
## +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
## |                              node                             |
## +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
##
## Figure 6: UUIDv1 Field and Bit Layout
##
## time_low:
##     The least significant 32 bits of the 60 bit starting timestamp. Occupies bits 0 through 31 (octets 0-3).
## time_mid:
##     The middle 16 bits of the 60 bit starting timestamp. Occupies bits 32 through 47 (octets 4-5).
## ver:
##     The 4 bit version field as defined by Section 4.2, set to 0b0001 (1). Occupies bits 48 through 51 of octet 6.
## time_high:
##     12 bits that will contain the most significant 12 bits from the 60 bit starting timestamp. Occupies bits 52 through 63 (octets 6-7).
## var:
##     The 2 bit variant field as defined by Section 4.1, set to 0b10. Occupies bits 64 and 65 of octet 8.
## clock_seq:
##     The 14 bits containing the clock sequence. Occupies bits 66 through 79 (octets 8-9).
## node:
##     48 bit spatially unique identifier. Occupies bits 80 through 127 (octets 10-15).
x = 1

## timestamp:
##     A 60 bit UTC timestamp as a count of 100- nanosecond intervals since 00:00:00.00,
##     15 October 1582 (the date of Gregorian reform to the Christian calendar).
## clock_sequence:
##     A clock sequence field which is used to help avoid duplicates that could arise
##     when the clock is set backwards in time or if the node ID changes
## node:
##     A 48-bit spatially unique identifier.
V1Params : {
    timestamp : U64,
    clockSequence : U16,
    node : U64,
}

newV1 : V1Params -> Uuid.Uuid
newV1 = \{ timestamp, clockSequence, node } ->
    integer = 0

    Uuid.fromU128 integer
