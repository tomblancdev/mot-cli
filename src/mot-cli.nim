## cli-maker is a simple generation tool for creating command line interfaces with nim.
import strutils, parseopt

type
    CommandOption* = object
        key*: string
        value*: string
        default*: string
        required*: bool
        help*: string
        validators*: seq[proc(value: string): bool]
    CommandConfig* = ref object of RootObj
        mainCommand*: string
        subCommands*: seq[CommandConfig] 
        help*: string
        options*: seq[CommandOption]
        `proc`*: proc(args: seq[string], options: seq[CommandOption])        
    CLIConfig* = ref object of RootObj
        commands*: seq[CommandConfig]
        help*: string
        description*: string
        name*: string
        version*: string


proc addTabulation(s: string) : string =
    ## Add tabulation to each line of a string
    ## This is useful for tabulation display with childrens that include many lines
    result = s.replace("\n", "\n\t")

proc register*(config: CLIConfig, command: CommandConfig) =
    ## Register a command to the CLIConfig
    config.commands.add(command)

proc getHelp*(config: CommandOption): string =
    ## Get the help string for a CommandOption
    result = config.key
    if config.required:
        result.add("*")
    if config.help != "":
        result.add(" - ")
        result.add(config.help)
    if config.default != "":
        result.add(" (default: ")
        result.add(config.default)
        result.add(")")

proc getHelp*(config: CommandConfig, deapth: int = 1): string =
    ## Get the help string for a CommandConfig
    result = config.mainCommand
    result.add(" - ")
    result.add(config.help)
    if config.options.len > 0:
        result.add("\nArguments:")
        for option in config.options:
            result.add("\n\t" & getHelp(option))
    if deapth == 0:
        return result
    if config.subCommands.len > 0:
        result.add("\nSubcommands:")
    for subCommand in config.subCommands:
        result.add("\n\t")
        result.add(addTabulation(getHelp(subCommand, deapth - 1)))

proc getHelp*(config: CLIConfig, deapth: int = 1): string =
    ## Get the help string for a CLIConfig
    result = config.help
    result.add("\n")
    if deapth == 0:
        return result
    for command in config.commands:
        result.add("\n\n")
        result.add(addTabulation(getHelp(command, deapth - 1)))

proc checkOptions*(config: CommandConfig, options: seq[(string, string)]) =
    ## Check if all required options are present
    ## If not, print the missing options and the help string
    for confOption in config.options:
        if confOption.required:
            var found = false
            for option in options:
                if option[0] == confOption.key:
                    found = true
                    break
            if not found:
                echo "Missing required argument ", confOption.key
                echo config.getHelp()
                quit(1)

proc getOption*(seq: seq[(string, string)], key: string): string =
    ## Get the value of an option from a sequence of options
    for option in seq:
        if option[0] == key:
            return option[1]
    return ""

proc getOption*(seq: seq[(string, string)], key: string, config: CommandConfig): string =
    ## Get the value of an option from a sequence of options
    for option in seq:
        if option[0] == key:
            return option[1]
    for confOption in config.options:
        if confOption.key == key:
            if confOption.required:
                echo "Missing required argument ", key
                echo config.getHelp()
                quit(1)
    return ""

proc get*(options: seq[CommandOption], key: string): CommandOption =
    ## Get the value of an option from a sequence of options
    for option in options:
        if option.key == key:
            return option
    raise newException(Exception, "Option not found")

proc generateOtions*(config: CommandConfig, opts: seq[(string, string)]): seq[CommandOption] =
    ## Generate the CommandOptions from the options sequence
    result = @[]
    for option in config.options:
        var value = getOption(opts, option.key)
        if value == "":
            value = option.default
        result.add(CommandOption(key: option.key, value: value, default: option.default, required: option.required))

proc run*(config: CommandConfig, args: seq[string] = @[], options: seq[(string, string)] = @[]) =
    ## Run the command with the given arguments and options
    # if there are args find the appropriate subcommand
    if args.len > 0:
        var command: CommandConfig
        for cmd in config.subCommands:
            if cmd.mainCommand == args[0]:
                command = cmd
                break
        if command == nil:
            echo "Command not found for ", args[0]
            quit(1)
        if command.`proc` == nil:
            echo command.getHelp()
            quit(1)
        command.checkOptions(options)
        let newOptions = generateOtions(command, options)
        command.`proc`(args[1 .. args.len - 1], newOptions)
    else:
        if config.`proc` == nil:
            echo config.getHelp()
            quit(1)
        config.checkOptions(options)
        let newOptions = generateOtions(config, options)
        config.`proc`(args, newOptions)

proc run*(config: CLIConfig, cmd: string) =
    ## Run the command with the given arguments and options
    # parse command 
    var args: seq[string] = @[]
    var options: seq[(string, string)] = @[]
    var opts = cmd.initOptParser()
    for kind, key, value in opts.getopt():
        case kind
        of cmdLongOption, cmdShortOption:
            options.add((key, value))
        of cmdArgument:
            args.add(key)
        else:
            echo "Invalid option"
            quit(1)
    # find appropriate command
    var command: CommandConfig
    for cmd in config.commands:
        if cmd.mainCommand == args[0]:
            command = cmd
            break
    if command == nil:
        echo "Command not found for ", args[0]
        quit(1)
    # run command
    command.run(args[1 .. args.len - 1], options)


