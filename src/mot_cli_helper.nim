import terminal, strutils
import mot_cli

type 
    CommandOptionHelper* = object
        KeyFgColor*: ForegroundColor
        KeyStyle*: Style
        HelpFgColor*: ForegroundColor
        HelpStyle*: Style
        DescriptionFgColor*: ForegroundColor
        DescriptionStyle*: Style
        getPrintHelpProc*: proc (oh: CommandOptionHelper): proc (o: var CommandOption)
        printHelp*: proc (o: var CommandOption)
    CommandHelper* = object
        NameFgColor*: ForegroundColor
        NameStyle*: Style
        HelpFgColor*: ForegroundColor
        HelpStyle*: Style
        DescriptionFgColor*: ForegroundColor
        DescriptionStyle*: Style
        optionHelper*: CommandOptionHelper
        getPrintHelpProc*: proc (ch: CommandHelper): proc (c: Command)
        printHelp*: proc (c: Command)
    CLIHelper* = object
        NameFgColor*: ForegroundColor
        NameStyle*: Style
        HelpFgColor*: ForegroundColor
        HelpStyle*: Style
        DescriptionFgColor*: ForegroundColor
        DescriptionStyle*: Style
        commandHelper*: CommandHelper
        getPrintHelpProc*: proc (ch: CLIHelper): proc (c: CLI)
        printHelp*: proc (c: CLI)

var tabulationCount* = 0
var show_options* = false
var show_commands* = false
var search*: string = ""

proc getPrintHelpProc*(oh: CommandOptionHelper): proc (o: var CommandOption) =
    return proc (o: var CommandOption) =
        stdout.styledWrite(oh.KeyFgColor, oh.KeyStyle, "--", o.key)
        stdout.styledWrite(oh.HelpFgColor, oh.HelpStyle, ": " & o.help_text)
        if o.default != "":
            stdout.styledWrite(oh.HelpFgColor, oh.HelpStyle, " (default: ")
            stdout.styledWrite(oh.HelpFgColor, oh.HelpStyle, o.default)
            stdout.styledWrite(oh.HelpFgColor, oh.HelpStyle, ")")
        stdout.styledWriteLine(oh.DescriptionFgColor, oh.DescriptionStyle, "")

proc getPrintHelpProc*(ch: CommandHelper): proc (c: Command) =
    return proc (c: Command) =
        stdout.styledWrite(ch.NameFgColor, ch.NameStyle, c.name)
        stdout.styledWriteLine(ch.HelpFgColor, ch.HelpStyle, ": " & c.help_text)
        if show_options:
            for i in 0..<c.options.len:
                stdout.setCursorXPos(tabulationCount + 2)
                ch.optionHelper.printHelp(c.options[i])
        if show_commands and c.sub_commands.len > 0:
            tabulationCount += 2
            stdout.setCursorXPos(tabulationCount)
            stdout.styledWriteLine(ch.HelpFgColor, ch.HelpStyle, "Subcommands: ")
            tabulationCount += 2
            for i in 0..<c.sub_commands.len:
                stdout.setCursorXPos(tabulationCount)
                ch.getPrintHelpProc(ch)(c.sub_commands[i])

proc getPrintHelpProc*(ch: CLIHelper): proc (c: CLI) =
    return proc (c: CLI) =
        stdout.styledWriteLine(ch.NameFgColor, ch.NameStyle, c.name)
        stdout.styledWriteLine("")
        stdout.styledWriteLine(ch.DescriptionFgColor, ch.DescriptionStyle, c.description)
        stdout.styledWriteLine("")
        stdout.styledWriteLine(ch.HelpFgColor, ch.HelpStyle, c.help_text)
        stdout.styledWriteLine("")
        stdout.styledWriteLine(ch.HelpFgColor, ch.HelpStyle, "Commands: ")
        tabulationCount += 2
        for i in 0..<c.commands.len :
            stdout.setCursorXPos(tabulationCount)
            ch.commandHelper.printHelp(c.commands[i])
        tabulationCount = 0

proc initCommandOptionHelper*(
    KeyFgColor: ForegroundColor = default(ForegroundColor),
    KeyStyle: Style = default(Style),
    HelpFgColor: ForegroundColor = default(ForegroundColor),
    HelpStyle: Style = default(Style),
    DescriptionFgColor: ForegroundColor = default(ForegroundColor),
    DescriptionStyle: Style = default(Style)
): CommandOptionHelper =
    result = CommandOptionHelper(
        KeyFgColor: KeyFgColor,
        KeyStyle: KeyStyle,
        HelpFgColor: HelpFgColor,
        HelpStyle: HelpStyle,
        DescriptionFgColor: DescriptionFgColor,
        DescriptionStyle: DescriptionStyle,
        getPrintHelpProc: getPrintHelpProc,
    )
    result.printHelp = result.getPrintHelpProc(result)

proc initCommandHelper*(
    NameFgColor: ForegroundColor = default(ForegroundColor),
    NameStyle: Style = default(Style),
    HelpFgColor: ForegroundColor = default(ForegroundColor),
    HelpStyle: Style = default(Style),
    DescriptionFgColor: ForegroundColor = default(ForegroundColor),
    DescriptionStyle: Style = default(Style),
    optionHelper: CommandOptionHelper = initCommandOptionHelper()
): CommandHelper =
    result = CommandHelper(
        NameFgColor: NameFgColor,
        NameStyle: NameStyle,
        HelpFgColor: HelpFgColor,
        HelpStyle: HelpStyle,
        DescriptionFgColor: DescriptionFgColor,
        DescriptionStyle: DescriptionStyle,
        optionHelper: optionHelper,
        getPrintHelpProc: getPrintHelpProc,
    )
    result.printHelp = result.getPrintHelpProc(result)

proc initCLIHelper*(
    NameFgColor: ForegroundColor = default(ForegroundColor),
    NameStyle: Style = default(Style),
    HelpFgColor: ForegroundColor = default(ForegroundColor),
    HelpStyle: Style = default(Style),
    DescriptionFgColor: ForegroundColor = default(ForegroundColor),
    DescriptionStyle: Style = default(Style),
    commandHelper: CommandHelper = initCommandHelper()
): CLIHelper =
    result = CLIHelper(
        NameFgColor: NameFgColor,
        NameStyle: NameStyle,
        HelpFgColor: HelpFgColor,
        HelpStyle: HelpStyle,
        DescriptionFgColor: DescriptionFgColor,
        DescriptionStyle: DescriptionStyle,
        commandHelper: commandHelper,
        getPrintHelpProc: getPrintHelpProc,
    )
    result.printHelp = result.getPrintHelpProc(result)


proc searchCommand(c: Command, search_command: string): seq[Command] =
    for i in 0..<c.sub_commands.len:
        if search_command in c.sub_commands[i].name.toLower():
            result.add(c.sub_commands[i])
    for i in 0..<c.sub_commands.len:
        result.add(searchCommand(c.sub_commands[i], search_command))

proc searchCommand*(c: CLI, search_command: string): seq[Command] =
    for i in 0..<c.commands.len:
        if search_command in c.commands[i].name.toLower():
            result.add(c.commands[i])
    for i in 0..<c.commands.len:
        result.add(searchCommand(c.commands[i], search_command))

proc addHelper*(ch: CommandHelper, show_options: bool = show_options, show_commands: bool = show_commands): proc (c: Command) =
    return proc (c: Command) =
        if show_options:
            mot_cli_helper.show_options = true
        if show_commands:
            mot_cli_helper.show_commands = true
        ch.getPrintHelpProc(ch)(c)
        mot_cli_helper.show_commands = false
        mot_cli_helper.show_options = false


proc createHelpCommand*(ch: CommandHelper, command: Command, name: string, help_text: string): Command =
    result = Command()
    result.name = name
    result.help_text = help_text
    result.addOption(CommandOption(key: "show-options", help_text: "Show options", default: "false"))
    result.addOption(CommandOption(key: "show-commands", help_text: "Show commands", default: "false"))
    result.addOption(CommandOption(key: "search", help_text: "Search command"))
    result.action = proc (c: Command) =
        if not (c.getOption("show-options").value.toLower() in ["false", "0"]):
            show_options = true
        if not (c.getOption("show-commands").value.toLower() in ["false", "0"]):
            show_commands = true
        if c.getOption("search") != nil and c.getOption("search").value != "":
            search = c.getOption("search").value.toLower()
            var r = command.searchCommand(search)
            if r.len == 0:
                stdout.styledWriteLine(fgRed, styleBlink, "Command not found")
            else:
                for i in 0..<r.len:
                    ch.printHelp(r[i])
            return
        ch.printHelp(command)

proc createHelpCommand*(ch: CLIHelper, cli: CLI, name: string, help_text: string): Command =
    result = Command()
    result.name = name
    result.help_text = help_text
    result.addOption(CommandOption(key: "show-options", help_text: "Show options", default: "false"))
    result.addOption(CommandOption(key: "show-commands", help_text: "Show commands", default: "false"))
    result.addOption(CommandOption(key: "search", help_text: "Search command"))
    result.action = proc (c: Command) =
        if not (c.getOption("show-options").value.toLower() in ["false", "0"]):
            show_options = true
        if not (c.getOption("show-commands").value.toLower() in ["false", "0"]):
            show_commands = true
        if c.getOption("search") != nil and c.getOption("search").value != "":
            search = c.getOption("search").value.toLower()
            var r = cli.searchCommand(search)
            if r.len == 0:
                stdout.styledWriteLine(fgRed, styleBlink, "Command not found")
            else:
                for i in 0..<r.len:
                    ch.commandHelper.printHelp(r[i])
            return
        ch.printHelp(cli)

proc addHelpCommand*(c: var Command, ch: CommandHelper, name: string, help_text: string = "Show help") = 
    c.addSubCommand(createHelpCommand(ch, c, name, help_text))

proc addHelpCommand*(c: var CLI, ch: CLIHelper, name: string, help_text: string = "Show help") =
    c.addCommand(createHelpCommand(ch, c, name, help_text))