import parseopt, sequtils

type 
    ValidatorError* = object 
        message*: string
        option*: CommandOption

    ValidatorProc* = proc (o: var CommandOption)
    CommandOption* = ref object of RootObj
        key*: string
        value*: string
        default*: string
        help_text*: string
        required*: bool
        validators*: seq[ValidatorProc]
        errors*: seq[ValidatorError]

    CommandExecutor* = proc (c: Command)
    Command* = ref object of RootObj
        name*: string
        sub_commands*: seq[Command]
        options*: seq[CommandOption]
        help_text*: string
        action*: CommandExecutor
        args*: seq[string]

    CLIExecutor* = proc (c: CLI)
    CLI* = ref object of RootObj
        commands*: seq[Command]
        name*: string
        version*: string
        help_text*: string
        description*: string
        action*: CLIExecutor
        given_string*: string
        args*: seq[string]
        options*: seq[(string, string)]

proc `$`*(e: ValidatorError): string =
    ## Return string representation of the error
    return "[Error] " & e.option.key & ": " & e.message

proc addCommand*(c: var CLI, cmd: Command) =
    ## Add a command to the CLI
    c.commands.add(cmd)

proc addSubCommand*(c: var Command, cmd: Command) =
    ## Add a subcommand to the command
    c.sub_commands.add(cmd)

proc addOption*(c: var Command, opt: CommandOption) =
    ## Add an option to the command
    c.options.add(opt)

proc addValidator*(c: var CommandOption, v: ValidatorProc) =
    ## Add a validator to the option
    c.validators.add(v)

proc addError*(o: var CommandOption, message: string) =
    ## Add an error to the option
    o.errors.add(ValidatorError(message: message, option: o))

proc parse*(c: var CLI) =
    ## Parse the given string and return the command
    for kind, key, value in getopt():
        case kind
        of cmdLongOption, cmdShortOption:
            c.options.add((key, value))
        of cmdArgument:
            c.args.add(key)
        else:
            raise newException(ValueError, "Invalid option")

proc getOption*(c: Command, key: string): CommandOption =
    ## Get the option from the given key
    var related_options = c.options.filterIt(it.key == key)
    if related_options.len != 1:
        return nil
    return related_options[0]

proc getCommand(c: Command): Command =
    ## Get the command from the given string
    if c.args.len == 0:
        return c
    let str_cmd = c.args[0]
    var related_commands = c.sub_commands.filterIt(it.name == str_cmd)
    if related_commands.len != 1:
        return nil
    return related_commands[0]

proc getCommand*(c: CLI): Command =
    ## Get the command from the given string
    if c.args.len == 0:
        return nil
    let str_cmd = c.args[0]
    let related_commands = c.commands.filterIt(it.name == str_cmd)
    if related_commands.len != 1:
        return nil
    var command = related_commands[0]
    if c.args.len > 1:
        command.args = c.args[1..^1]
        return command.getCommand()
    return command

proc getErrors*(c: Command): seq[ValidatorError] =
    ## Get the errors from the command
    for opt in c.options:
        result.add(opt.errors)

proc initOption*(o: var CommandOption) =
    ## Initialize the option
    o.value = o.default
    if o.required and o.value.len == 0:
        o.addError("Option is required")

proc initOption*(o: var CommandOption, v: string) =
    ## Initialize the option
    o.value = v
    if o.required and o.value.len == 0:
        o.addError("Option is required")

proc initOptions*(c: var Command, o: seq[(string, string)]) =
    ## Initialize the options
    for i in 0..<c.options.len:
        let given_option = o.filterIt(it[0] == c.options[i].key)
        if given_option.len == 1:
            let option_value = given_option[0][1]
            c.options[i].initOption(option_value)
        else:
            c.options[i].initOption()



proc validate*(o: var CommandOption): seq[ValidatorError] =
    ## Validate the option
    for v in o.validators:
        v(o)
    return o.errors

proc validate*(c: Command, throw_error: bool = false): seq[ValidatorError] =
    ## Validate the command
    for i in 0..<c.options.len:
        var opt = c.options[i]
        result.add(opt.validate())
    if throw_error:
        for opt in c.options:
            for e in opt.errors:
                echo e
        return

proc execute*(c: Command) =
    ## Execute the command
    if c.validate().len > 0:
        return
    c.action(c)

proc run*(c: var CLI) =
    ## Execute the command
    c.parse()
    var command = c.getCommand()
    if (command == nil) and (c.action == nil):
        echo "Command not found"
        return
    if command == nil:
        c.action(c)
        return
    command.initOptions(c.options)
    command.execute()
    if command.getErrors().len > 0:
        for e in command.getErrors():
            echo e
        return
