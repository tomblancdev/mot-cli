import strutils, terminal
import ../src/mot_cli


# Initialize the CLI
var cli = CLI(
    name: "mot-cli",
    help_text: "Wow this is a cool CLI 👌",
    description: "This is a cool CLI that can add and substract numbers"
)

# Create a help function for the CLI

proc echoHelp(o: CommandOption) = 
    stdout.styledWrite(fgMagenta, "\n\t--", o.key)
    stdout.styledWrite(fgMagenta, styleDim, ": " & o.help_text)

proc echoHelp(c: Command, show_subcommands: bool, show_options: bool ) =
    stdout.styledWrite(fgCyan, c.name)
    stdout.styledWrite(fgCyan, styleDim, ": " & c.help_text)
    if show_options :
        for option in c.options:
            echoHelp(option)
    if c.sub_commands.len > 0:
        stdout.styledWrite(fgCyan, styleDim, "\n\nSubcommands: \n")
    if show_subcommands:
        for command in c.sub_commands:
            echoHelp(command, false, false)
    stdout.styledWriteLine("")

proc echoHelp(c: Command) = 
    stdout.styledWrite(fgCyan, c.name)
    stdout.styledWrite(fgCyan, styleDim, ": " & c.help_text)
    for option in c.options:
        echoHelp(option)
    if c.sub_commands.len > 0:
        stdout.styledWrite(fgYellow, styleBright, "\n\nSubcommands: \n")
    for command in c.sub_commands:
        stdout.write("\t")
        echoHelp(command, false, true)

proc echoHelp(c: var CLI) = 
    stdout.styledWrite(fgCyan, c.name)
    stdout.styledWriteLine(fgCyan, styleDim, ": " & c.help_text)
    stdout.styledWriteLine(fgGreen, styleDim, c.description)
    stdout.styledWriteLine(fgCyan, styleDim, "\n\nCommands: ")
    for command in c.commands:
        stdout.write("\n\t")
        echoHelp(command)    


# Register the help function to the cli
cli.action = echoHelp

# Register a help command
cli.addCommand(
    Command(
        name: "help",
        help_text: "Prints the help tree",
        # Here we register the action directly into the command
        action: proc (c: Command) =
            cli.echoHelp()
    )
)


# Create a validator for numbers

# We can create a validator that from a variable 
let validateNumber: ValidatorProc = proc (o: var CommandOption) =
    try :
        discard o.value.parseInt()
    except :
        o.addError("The value must be a number")

# Or we can create a validator generator that returns a validator
proc validateMaxLen(max_len: int): proc (o: var CommandOption) =
    return proc (o: var CommandOption) =
        if o.value.len > max_len:
            o.addError("The value must be less than " & $max_len & " characters")


# Lets create a dd Command that adds two numbers
let add = Command(
    name: "add",
    help_text: "Add two numbers",
    options: @[
        CommandOption(
            key: "a",
            help_text: "The first number",
            required: true,
            validators: @[validateNumber]
        ),
        CommandOption(
            key: "b",
            help_text: "The second number",
            required: true,
            validators: @[validateNumber]
        )
    ],
    action: proc (c: Command) =
        var a = c.getOption("a").value.parseInt()
        var b = c.getOption("b").value.parseInt()
        stdout.writeLine(a + b)
)

# Lets create a sub Command that substract two numbers
let sub = Command(
    name: "sub",
    help_text: "Substract two numbers",
    options: @[
        CommandOption(
            key: "a",
            help_text: "The first number",
            required: true
        ),
        CommandOption(
            key: "b",
            help_text: "The second number",
            required: true
        )
    ],
    action: proc (c: Command) =
        var a = c.getOption("a").value.parseInt()
        var b = c.getOption("b").value.parseInt()
        stdout.writeLine(a - b)
)

cli.addCommand(
    Command(
        name: "mot-cli",
        help_text: "This is the same name as the CLI 😒",
        options: @[
            CommandOption(
                key: "verbose",
                help_text: "Prints more information but does not really works 😅",
            )
        ],
        sub_commands: @[
            add, # We can add the command directly as the variable is already defined
            sub,
            Command( # Or we can create the command directly
                name: "talk",
                help_text: "Talk to the CLI",
                options: @[
                    CommandOption(
                        key: "message",
                        help_text: "The message to say",
                        required: true,
                        validators: @[validateMaxLen(10)]
                    )
                ],
                action: proc (c: Command) =
                    var message = c.getOption("message").value
                    stdout.writeLine("You said: " & message)
                    while true:
                        stdout.write("Say something (exit to quit): ")
                        var message = stdin.readLine()
                        if message == "exit":
                            break
                        stdout.writeLine("You said: " & message)
            )
        ],
        action: echoHelp # In case of not passing argument to this command it will print the help
    )
)

# Run the CLI
cli.run()