function Start-Matrix {
    # Tentative de faire le défilement vers le bas au lieu de vers le haut
    # Function to replicate a Matrix effect
    [CmdletBinding(DefaultParameterSetName='Time')]
    param(
        [Parameter(ParameterSetName='Time', Position=0)]
        # Time: when the user specifies the SleepTime as first argument
        [Parameter(ParameterSetName='Color', Position=1)]
        # Color: when the user specifies the color first, then SleepTime, etc
        [Alias('Sleep','S')]
            [int]$SleepTime = 15, # milliseconds
        [Parameter(ParameterSetName='Time', Position=1)]
        [Parameter(ParameterSetName='Color', Position=2)]
        [Alias('Drop','DC')]
            [int]$DropChance = 5, # Chance a character has to be created spontaneously (percentage)
        [Parameter(ParameterSetName='Time', Position=2)]
        [Parameter(ParameterSetName='Color', Position=3)]
        [Alias('Stick','SC')]
            [int]$StickChance = 60, # Chance a character has to appear when there is one above it (percentage)
        [Parameter(ParameterSetName='Time', Position=3)]
        [Parameter(ParameterSetName='Color', Position=0, Mandatory)]
        [Alias('Colour','C')]
            [string]$Color = 'Green',
        ## Other, non-positional, parameters ##
        [Alias('Erase','Quota','EQ')]
            [int]$EraseQuota = 5, # Percentage of characters erased in each selected line; depends on the number of characters
        [Alias('LeaveUntouched','Leave','Untouched')]
            [int]$LeaveUntouchedChance = 20, # Chance of keeping a character untouched when the new line is created (percentage)
        [Alias('Lines','L')]
            [int]$NumberOfLinesToReplace = 10, # Number of lines where to erase characters
        [Alias('Dynamic','DE')]
            [switch]$DynamicErasing, # Dynamic mode to erase characters: more lines => more erasing. Overwrites $NumberOfLinesToReplace
        [Alias('Full','FS','F')]
            [switch]$FullScreen, # Toggle fullscreen mode at the beginning and at the end
        [Alias('NoClear','NoClean')]
            [switch]$NoClearScreenAfterExecution, # Clear the screen after execution to not let the characters
        [Alias('Adaptive','Adaptative','Resize')]
            [switch]$AdaptiveSize
    )


    # Constants
    $MINUNICODE = 21
    $MAXUNICODE = 7610

    # The characters supported by the Consolas font (plus some more)
    $supportedChars = ($MINUNICODE,126),(161,1299),(7425,$MAXUNICODE) # ,(7681,etc)
    # $notSupportedChars = (127,160),(1300,7424),(7611,7680)


    ## Toggle fullscreen ##

    Add-Type -AssemblyName System.Windows.Forms
    if ($FullScreen) { [System.Windows.Forms.SendKeys]::SendWait("{F11}") }
    Start-Sleep -Milliseconds 100 # Wait a bit to get the right WindowSize afterwards

    $WS = $Host.UI.RawUI.WindowSize
    $windowWidth, $windowHeight = $WS.Width, $WS.Height
    $maxHoriz = $windowWidth - 1
    $maxVertic = $windowHeight - 1


    ## Resize the buffer to not overload it ## (not needed, but may be useful)
    # $oldBufferSize = $host.UI.RawUI.BufferSize
    # $host.UI.RawUI.BufferSize = New-Object System.Management.Automation.Host.Size($windowWidth,$windowHeight)
    # Note: doesn't work in Windows Terminal



    # Initialize the matrix to an array of strings, all full of spaces
    $matrix = @(
        for ($i=0; $i -lt $maxVertic; $i++) { ' '*$maxHoriz }
    )
    $prevLine = $matrix[0]
    $next = 0

    # Clear the console to let all the place for the effect, although this could be an unwanted behaviour
    Clear-Host

    # Note: the label is necessary to break this precise loop from the nested loops
    :mainLoop while ($true)
    {
        ## Check if a key was pressed ##

        if ([Console]::KeyAvailable)
        {
            $keyInfo = [Console]::ReadKey($true) # Consume the pressed key

            # If the key was P, we pause
            if($keyInfo.Key -eq 'P')
            {
                [Console]::SetCursorPosition($0,$maxVertic)
                [Console]::Write('[Paused]')
                # We wait for another P pressed to resume
                while ($true)
                {
                    Start-Sleep -Milliseconds 100 # Pause for a bit to not overuse the processor
                    if ([Console]::KeyAvailable)
                    {
                        $keyInfo = [Console]::ReadKey($true) # Consume the pressed key

                        # IF it is P again, resume; else, exit
                        if ($keyInfo.Key -eq 'P')
                        {
                            [Console]::SetCursorPosition(0,$maxVertic)
                            [Console]::Write(' '*8) # Erase the pause message
                            [Console]::SetCursorPosition(0,$next) # a verif
                            break
                        }
                        else { if ($FullScreen) { [System.Windows.Forms.SendKeys]::SendWait("{F11}") } ; break mainLoop }
                    }
                }
            }
            # Note: other features (associated with other keys) may be added here
            
            # If it is another key, exit fullscreen and return
            else { if ($FullScreen) { [System.Windows.Forms.SendKeys]::SendWait("{F11}") } ; break mainLoop }
        }

        ## Fill the new line with characters or spaces ##
        
        $newLine = ''
        for ($j = 0; $j -lt $maxHoriz; $j++)
        {
            # If there was a character, try to keep it
            # Note: I don't know why indexing $matrix[$next] sometimes gives $null, so I added a condition
            if (($matrix[$next][$j] -ne $null) -and ($matrix[$next][$j] -ne ' ') -and (Get-Random -Maximum 100) -lt $LeaveUntouchedChance)
            {
                $newLine += $matrix[$next][$j]
            }
            # If there was nothing or the probability was too low, try to create a new one
            elseif ((Get-Random -Maximum 100) -lt $DropChance -or (
                ($prevLine[$j] -ne ' ') -and ((Get-Random -Maximum 100) -lt $StickChance)))
            {
                $charIsGood = $false
                do {
                    $uni = Get-Random -Minimum $MINUNICODE -Maximum $MAXUNICODE
                    foreach ($interval in $supportedChars)
                    {
                        if ($uni -ge $interval[0] -and
                            $uni -le $interval[1])
                        {
                            $charIsGood = $true
                            break # Note: exit only foreach loop
                        }
                    }
                } while (!($charIsGood))

                $newLine += [char]$uni # Convert the unicode number into a character
            }
            else { $newLine += ' ' }

        }

        ## Randomly remove characters from past lines ##

        if ($EraseQuota -gt 0)
        {
            if ($DynamicErasing) { $NumberOfLinesToReplace = [int]($next / 2) + 1 }

            # Pick random lines
            # $linesToReplace = @(Get-Random -Maximum ($next + 1) -Count $NumberOfLinesToReplace) # $next+1 to avoid Maximum = 0
            # OR:
            $linesToReplace = @((Get-Random -Maximum ($next + 1) -Count $NumberOfLinesToReplace) | Sort-Object)
            # Note: Sort-Object makes the program slightly faster

            foreach ($lineToReplace in $linesToReplace)
            {
                # Look for the characters' positions
                $currentLine = $matrix[$lineToReplace]
                $colsWithChar = (0..$currentLine.Length | Where-Object { $currentLine[$_] -ne ' ' }) # Columns where there is a character

                # Do something only if the line has characters
                if ($colsWithChar.Count -ne 0)
                {
                    $numberOfColsToReplace = [int](($colsWithChar.Count * $EraseQuota) / 100)
                    # If the EraseQuota is not high enough but still > 0, erase only 1 character
                    if ($numberOfColsToReplace -eq 0) { $numberOfColsToReplace = 1 }

                    # Pick random columns
                    # $colsToReplace = @(Get-Random -InputObject $colsWithChar -Count $numberOfColsToReplace)
                    # OR:
                    $colsToReplace = @((Get-Random -InputObject $colsWithChar -Count $numberOfColsToReplace) | Sort-Object)
                    # Note: Sort-Object makes the program slightly faster

                    # Actually replace the characters in the picked columns
                    foreach ($col in $colsToReplace)
                    {
                        # Terrible coding, but I still have to figure out the formula for SubString…
                        try {
                            $currentLine = $currentLine.SubString(0, $col) + ' ' + $currentLine.SubString($col + 1)
                            # Note: since columns start at 0, the length is $col, not $col-1
                        }
                        catch {
                            # Do nothing
                        }
                    }
                    $matrix[$lineToReplace] = $currentLine
                    # Move to the right position to replace the line
                    [Console]::SetCursorPosition(0, $lineToReplace)
                    Write-Host $matrix[$lineToReplace] -Foreground $Color
                }
            }
        }

        [Console]::SetCursorPosition(0, $next)
        $matrix[$next] = $newLine
        Write-Host $newLine -Foreground $Color
        
        $prevLine = $newLine
        # Note: $prevLine could be replaced by `[Math]::Abs($next-1) % $maxVertic` (I think)
        $next++
        if ($next -eq $maxVertic)
        {
            $next = 0
            if ($AdaptiveSize -and $WS -ne $Host.UI.RawUI.WindowSize)
            {
                $WS = $Host.UI.RawUI.WindowSize
                # Resize the matrix
                $minHeigth = [Math]::Min($windowHeight, $WS.Height)
                $minWidth = [Math]::Min($windowWidth, $WS.Width)
                $maxHeight = [Math]::Max($windowHeight, $WS.Height)
                $maxWidth = [Math]::Max($windowWidth, $WS.Width)
                $diffWidth = [Math]::Abs($windowWidth - $WS.Width)

                $matrix = @(
                    # From 0 to the biggest common line, we extend lines of how much is between the two
                    for ($i = 0; $i -lt $minHeigth; $i++)
                    {
                        $matrix[$i] + (' '*$diffWidth) # Not entirely sure about the diff formula, but totally works
                    }
                    # The rest, being 0 or the difference
                    for ($i = $minHeigth; $i -lt $maxHeight; $i++)
                    {
                        ' '*$maxWidth
                    }
                )
                $prevLine = $matrix[0]
                
                $windowWidth, $windowHeight = $WS.Width, $WS.Height
                $maxHoriz = $windowWidth - 1
                $maxVertic = $windowHeight - 1
            }
        }

        Start-Sleep -Milliseconds $SleepTime
    }
    # Reset the buffer size (warning: this will fail if the window is resized during execution)
    # $host.UI.RawUI.BufferSize = $oldBufferSize
    # Note: doesn't work in Windows Terminal
    if (!($NoClearScreenAfterExecution)) { Clear-Host }
}

# Start-Matrix 10 -AdaptiveSize