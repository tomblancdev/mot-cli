import strutils, terminal
import ../src/mot_cli
import ../src/mot_cli_helper


# Initialize the CLI
var cli = CLI(
    name: "mot-cli",
    help_text: "Wow this is a cool CLI 👌",
    description: "This is a cool CLI that can add and substract numbers"
)




# Working with helpers

let commandOptionHelper = initCommandOptionHelper(
    KeyFgColor=fgYellow,
    KeyStyle=styleBlink,
    HelpStyle=styleDim,
    DescriptionFgColor=fgBlue,
    DescriptionStyle=styleItalic
)

let commandHelper = initCommandHelper(
    NameFgColor=fgMagenta,
    NameStyle=styleBlink,
    HelpStyle=styleDim,
    DescriptionFgColor=fgBlue,
    DescriptionStyle=styleItalic,
    optionHelper=commandOptionHelper
)

let cliHelper = initCLIHelper(
    NameFgColor=fgYellow,
    NameStyle=styleBlink,
    HelpStyle=styleDim,
    DescriptionFgColor=fgBlue,
    DescriptionStyle=styleItalic,
    commandHelper= commandHelper
)
cli.action = cliHelper.printHelp


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
        action: commandHelper.addHelper(show_options=true, show_commands=true)
    )
)

cli.addHelpCommand(cliHelper, "help")

# Run the CLI
cli.run()