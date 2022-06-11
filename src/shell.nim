#[
    Shell: interactively processes commands from the user

    Responsibilities:
    - for valid commands, dispatches the command to the appropriate handler
    - for invalid commands, show an error message

    Requires:
    - a way to receive input from keyboard
    - a way to send output to the screen

    Provides
    - shell
]#

import console

proc start*() {.cdecl.} =

    # loop
    writeln("] ")

        # read input

        # find handler

        # dispatch

    discard
