# Posh-Matrix
A Powershell implementation of the Matrix effect.

## Features
- Parameters:
	- **SleepTime**: Opposite of speed. Lower this parameter to make the script run faster.
	- **DropChance**: Chance a character will spawn spontaneously.
	- **StickChance**: Chance a character will spawn if there is already a character above it.
	- **Color**: The color used, from the default Powershell color list: `Black, DarkBlue, DarkGreen, DarkCyan, DarkRed, DarkMagenta, DarkYellow, Gray, DarkGray, Blue, Green, Cyan, Red, Magenta, Yellow, White`.
	- **LeaveUntouchedChance**: Chance of keeping a character intact when the new ones are created. Influences the rate at which characters are erased too.
- Switches:
	- **FullScreen**: Toggle fullscreen mode before and after the execution (unless `Ctrl+C` is pressed; although it could be fixable by wrapping a `try-catch` block around the mainloop).
	- **NoClearBefore**: Don't clear the screen before execution. Will keep the current on-screen characters (for example another command output).
	- **NoClearAfter**: Don't clear the screen after execution. Will keep the colored characters displayed, and probably show the console prompt in the middle of them.
	- **NoAdaptiveSize**: by default, if the window is resized during execution, the next loop will adapt and print characters depending on the new size. This switch disable this behaviour.
	- **Multicolor**: pick a random color for every character. Overwrites $Color.
- Keys:
	- Press P while the script is running to pause it. Press P again to resume.
	- Press any other key to exit.

## To-do
- Add an option to specify a custom characters set
- Balance the default parameters
- Fix the Writing issue (copying the Writing process from the `Multicolor` mode would work, but would slow the script down)

## Execution examples
- `Start-Matrix` (starts the script with the default parameters)
- `Start-Matrix 100 -FullScreen` (equivalent of `Start-Matrix -SleepTime 100 -FullScreen`)
- `Start-Matrix 10 -NoAdaptiveSize -NoClearBefore`
- `Start-Matrix -DropChance 1 -StickChance 60 -Leave 75`
- `Start-Matrix -DropChance 1 -StickChance 60 -Untouched 65 -Multicolor`
- `Start-Matrix -SleepTime 100 -DropChance 1 -StickChance 80 -LeaveUntouchedChance 60`

## Changelog
- **v1.0**: Initial release
- v1.01: Rearranged parameters, added examples
- v1.02: Changed the `-AdaptiveSize` switch to `-NoAdaptiveSize`, to enable the adaptiveness by default
- v1.03: Made the cursor invisible
- **v2.0**:
	- Entirely changed the data structure: it is now a List of Lists of Characters (or *matrix*). The script is in consequence much faster.
	- Since `LeaveUntouchedChance` handles the erasing now, removed the following parameters:
		- `NumberOfLinesToReplace`
		- `EraseQuota`
		- `DynamicErasing`
	- Added the `-Multicolor` switch.
	- Removed some redondant Parameters' Aliases
- v2.01: Fixes issue #1
- v2.02: Balanced the default parameters a little