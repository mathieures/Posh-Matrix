# Posh-Matrix
A Powershell implementation of the Matrix effect.

## Features
- Parameters:
	- **SleepTime**: Opposite of speed. Lower this parameter to make the script run faster.
	- **DropChance**: Chance a character will spawn spontaneously.
	- **StickChance**: Chance a character will spawn if there is already a character above it.
	- **Color**: The color used, from the default Powershell color list: `Black, DarkBlue, DarkGreen, DarkCyan, DarkRed, DarkMagenta, DarkYellow, Gray, DarkGray, Blue, Green, Cyan, Red, Magenta, Yellow, White`.
	- **EraseQuota**: Percentage of characters erased from each randomly picked line.
	- **LeaveUntouchedChance**: Chance of keeping a character intact when the new ones are created (replacing others).
	- **NumberOfLinesToReplace**: Randomly pick this much lines to erase characters from.
- Switches:
	- **DynamicErasing**: Always erase half of the lines above the new one. Overwrites the NumberOfLinesToReplace parameter.
	- **FullScreen**: Toggle fullscreen mode before and after the execution (unless `Ctrl+C` is pressed; although it could be fixable by wrapping a `try-catch` block around the mainloop).
	- **NoClearBefore**: Don't clear the screen before execution. Will keep the current on-screen characters (for example another command output).
	- **NoClearAfter**: Don't clear the screen after execution. Will keep the colored characters displayed, and probably show the console prompt in the middle of them.
	- **NoAdaptiveSize**: by default, if the window is resized during execution, the next loop will adapt and print characters depending on the new size. This switch disable this behaviour.
- Keys:
	- Press P while the script is running to pause it. Press P again to resume.
	- Press any other key to exit.

## To-do
- Make the cursor invisible
- Add an option to specify a custom characters set
- Balance the default parameters

## Known issues
- The `-DynamicErasing` switch slows the script down quite a bit

## Update notes
- v1.0: Initial release
- v1.01: Rearranged parameters, added examples
- v1.02: Changed the `-AdaptiveSize` switch to `-NoAdaptiveSize`, to enable the adaptiveness by default