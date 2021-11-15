# Posh-Matrix v2.03 by mathieures
function Start-Matrix {
    # Function to replicate a Matrix effect
    [CmdletBinding(DefaultParameterSetName='Time')]
    param(
        # Time: when the user specifies the SleepTime as first argument
        [Parameter(ParameterSetName='Time', Position=0)]
        # Color: when the user specifies the color first, then SleepTime, etc
        [Parameter(ParameterSetName='Color', Position=1)]
        [Alias('Sleep','S')]
            [int]$SleepTime = 50, # milliseconds
        [Parameter(ParameterSetName='Time', Position=1)]
        [Parameter(ParameterSetName='Color', Position=2)]
        [Alias('Drop','DC')]
            [int]$DropChance = 2, # Chance a character has to be created spontaneously (percentage)
        [Parameter(ParameterSetName='Time', Position=2)]
        [Parameter(ParameterSetName='Color', Position=3)]
        [Alias('Stick','SC')]
            [int]$StickChance = 55, # Chance a character has to appear when there is one above it (percentage)
        [Parameter(ParameterSetName='Time', Position=3)]
        [Parameter(ParameterSetName='Color', Position=0, Mandatory)]
        [Alias('Colour','C')]
            [string]$Color = 'Green', # Color used for all the characters
        [Parameter(Position=4)]
        [Alias('LeaveUntouched','Leave','Untouched','LUC','L')]
            [int]$LeaveUntouchedChance = 30, # Chance of keeping a character untouched when the new line is created (percentage)
        
        ## Other, non-positional, parameters ##
        [Alias('Full','FS','F')]
            [switch]$FullScreen, # Toggle fullscreen mode at the beginning and at the end
        [Alias('NCB')]
            [switch]$NoClearBefore, # Do not clear the screen before execution
        [Alias('NCA')]
            [switch]$NoClearAfter, # Do not clear the screen after execution
        [Alias('NoAdaptive','NoAdaptative','NoAdapt','NoResize')]
            [switch]$NoAdaptiveSize, # Disable the auto-resizing of the effect when the window shape is changed
        [Alias('Rainbow','M')]
            [switch]$Multicolor # Random colors for all characters. Overwrites $Color
    )

    ## Toggle fullscreen ##

    Add-Type -AssemblyName System.Windows.Forms
    if ($FullScreen) {
        [System.Windows.Forms.SendKeys]::SendWait("{F11}")
        # Start-Sleep -Milliseconds 100 # Wait a bit to get the right WindowSize afterwards
        [Threading.Thread]::Sleep(100) # Wait a bit to get the right WindowSize afterwards
    }

    # Window info
    $WS = $Host.UI.RawUI.WindowSize
    $windowWidth, $windowHeight = $WS.Width, $WS.Height
    $maxHoriz = $windowWidth - 1
    $maxVertic = $windowHeight - 1

    # Constants
    $MINUNICODE = 21
    $MAXUNICODE = 7610
    # if ($Multicolor) { $colors = 16, 231}
    if ($Multicolor) {
        $colors = 16, 231
        $randomColors = $colors[0]..$colors[1] | Sort-Object {Get-Random}
    }

    # Variables
    $randomGen = [Random]::New() # Immensely faster than Get-Random

    # The characters supported by the Consolas font (plus some more)
    $supportedChars = ($MINUNICODE,126),(161,1299),(7425,$MAXUNICODE) # ,(7681,etc)
    # $notSupportedChars = (127,160),(1300,7424),(7611,7680)
    
    # Save the console cursor visibility
    $oldCursorVisible = [Console]::CursorVisible

    # Initialize the matrix to a list of lists of chars (all spaces)
    $matrix = [Collections.Generic.List[Object]]::New($maxVertic)
    for ($i = 0; $i -lt $maxVertic; ++$i) {
        $matrix.Add([Collections.Generic.List[Char]]::New(' '*$maxHoriz))
    }

    # Note: we can create it there even with adaptive size, Lists being automatically resized
    $currentLine = 0
    $prevLine = $matrix[0] # a list of chars ; not necessary, but useful

    # Clear the console to let all the place for the effect, although this could be an unwanted behaviour
    if (!($NoClearBefore)) { Clear-Host }

    # Note: the label is necessary to break this precise loop from the nested loops
    :mainLoop while ($true) {
        ## Check if a key was pressed ##

        if ([Console]::KeyAvailable) {
            $keyInfo = [Console]::ReadKey($true) # Consume the pressed key

            # If the key was P, we pause
            if ($keyInfo.Key -eq 'P') {
                [Console]::SetCursorPosition($0,$maxVertic)
                [Console]::Write('[Paused]')
                # We wait for another P pressed to resume
                while ($true)
                {
                    [Threading.Thread]::Sleep(100) # Pause for a bit to not overuse the processor
                    if ([Console]::KeyAvailable) {
                        $keyInfo = [Console]::ReadKey($true) # Consume the pressed key

                        # If it is P again, resume; else, exit
                        if ($keyInfo.Key -eq 'P') {
                            [Console]::SetCursorPosition(0,$maxVertic)
                            [Console]::Write(' '*8) # Erase the pause message
                            # Note: no need to replace the cursor since it is done before every writing
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

        ## Fill the line with characters or spaces ##

        # Loop through the columns
        for ($j = 0; $j -lt $matrix[$currentLine].Count; $j++) {
            # si on est sur un caractère, on le garde ou l'enlève
            if ($matrix[$currentLine][$j] -ne ' ') {
                # Si la proba est trop basse, on enlève le char
                if ($randomGen.Next(100) -ge $LeaveUntouchedChance) {
                # if (!((Get-Random -Maximum 100) -lt $LeaveUntouchedChance))
                # if ((Get-Random -Maximum 100) -ge $LeaveUntouchedChance)
                    $matrix[$currentLine][$j] = ' '
                    if ($Multicolor) {
                        # Fails if the window is resized, so exit the loop
                        try {
                            [Console]::SetCursorPosition($j, $currentLine)
                        }
                        catch [System.Management.Automation.MethodInvocationException] {
                            break
                        }
                        [Console]::CursorVisible = $false
                        # Write-Host ' ' -NoNewLine
                        [Console]::Write(' ')
                    }
                }
            }
            else {
                # If a character was above, we may stick another one to it; if there wasn't, we may drop one
                # if (($prevLine[$j] -ne ' ' -and (Get-Random -Maximum 100) -lt $StickChance) -or
                #     (Get-Random -Maximum 100) -lt $DropChance)
                if (($prevLine[$j] -ne ' ' -and $randomGen.Next(100) -lt $StickChance) -or
                    $randomGen.Next(100) -lt $DropChance)
                {
                    $charIsGood = $false
                    do {
                        $uni = $randomGen.Next($MINUNICODE, $MAXUNICODE)
                        foreach ($interval in $supportedChars)
                        {
                            if ($uni -ge $interval[0] -and
                                $uni -le $interval[1])
                            {
                                $charIsGood = $true
                                break # Note: exit only foreach loop
                            }
                        }
                    } until ($charIsGood)

                    $matrix[$currentLine][$j] = [char]$uni
                    if ($Multicolor) {
                        # Fails if the window is resized, so exit the for loop
                        try {
                            [Console]::SetCursorPosition($j, $currentLine)
                        }
                        catch [System.Management.Automation.MethodInvocationException] {
                            break
                        }
                        [Console]::CursorVisible = $false
                        # $randomColor = Get-Random -Minimum $colors[0] -Maximum ($colors[1] + 1)

                        # $randomColor = $randomGen.Next($colors[0], $colors[1] + 1)
                        $randomColor = $randomColors[($j -bxor $currentLine -bor $uni) -band $randomColors.Count] # For randomness

                        # Write-Host "`e[38;5;${randomColor}m$($matrix[$currentLine][$j])" -NoNewLine # 38: foreground
                        # [Console]::Write("`e[38;5;${randomColor}m$($matrix[$currentLine][$j])`e[0m") # 38: foreground, 0: reset
                        Write-Host "`e[38;5;${randomColor}m$($matrix[$currentLine][$j])`e[0m" -NoNewLine # 38: foreground, 0: reset
                    }
                    # Else, do nothing yet (the whole line is written afterwards)
                }
            }
        }

        if (!$Multicolor) {
            # Fails if the window is resized, so don't Write if it does
            try {
                [Console]::SetCursorPosition(0, $currentLine)
                [Console]::CursorVisible = $false
                Write-Host "$($matrix[$currentLine] -join '')" -Foreground $Color -NoNewLine # The entire line
            }
            catch [System.Management.Automation.MethodInvocationException] {
                # Do nothing
            }
        }

        # After all columns are parsed
        $prevLine = $matrix[$currentLine]

        # If the currentLine is 'in the middle' of the screen
        if ($currentLine -ne ($maxVertic - 1)) {
            $currentLine++
        }
        # Else reset the currentLine to the top of the window
        else {
            $currentLine = 0
            
            # If the window size is not the same as before
            if (!$NoAdaptiveSize -and $WS -ne $Host.UI.RawUI.WindowSize) {
                $WS = $Host.UI.RawUI.WindowSize # The new size

                $diffHeight = $WS.Height - $windowHeight
                $diffWidth = $WS.Width - $windowWidth

                # If the difference is positive, the window is taller so we add lines to the matrix
                if ($diffHeight -gt 0) {
                    # Add $diffHeight lines
                    for ($i = 0; $i -lt $diffHeight; $i++) {
                        $matrix.Add([Collections.Generic.List[Char]]::New(' '*$maxHoriz))
                        # Note: if Width changed too, the lines will be resized in the second `if`, so $maxHoriz is good
                    }
                }
                # Else there are less lines now, so we reduce the matrix
                else {
                    $newHeight = $matrix.Count + $diffHeight # '+' since $diffHeight is negative
                    $end = [Math]::Abs($diffHeight)
                    # Remove $diffHeight lines
                    $matrix.RemoveRange($newHeight, $end) # truncate the list so the length is $newHeight
                }

                # If the difference is positive, the window is larger so we add columns to the matrix
                if ($diffWidth -gt 0) {
                    # Loop through the lines to add spaces
                    for ($i = 0; $i -lt $matrix.Count; $i++) {
                        $matrix[$i].AddRange(' '*$diffWidth)
                    }
                }
                # Else there are less characters now, so we reduce the lines' length
                else {
                    $newWidth = $matrix[0].Count + $diffWidth # '+' since $diffWidth is negative
                    $end = [Math]::Abs($diffWidth)

                    # Loop through the lines to remove characters
                    for ($i = 0; $i -lt $matrix.Count; $i++) {
                        $matrix[$i].RemoveRange($newWidth, $end) # truncate the list so the length is $newWidth
                    }
                }                
                $prevLine = $matrix[0]

                $windowHeight, $windowWidth = $WS.Height, $WS.Width
                $maxVertic = $windowHeight - 1
                $maxHoriz = $windowWidth - 1
            }
        }

        [Threading.Thread]::Sleep($SleepTime)
    }
    
    ## After the mainLoop ##

    if (!($NoClearAfter)) { Clear-Host }
    # Restore the previous cursor visibility
    [Console]::CursorVisible = $oldCursorVisible
}