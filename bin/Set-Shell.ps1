$__source = @"
using System;
using System.Drawing;
using System.Runtime.InteropServices;

namespace Netzwerker.Shell.Console
{
    public static class ConsoleHelper
    {
        [DllImport("kernel32")]
        private static extern bool SetConsoleIcon(IntPtr hIcon);

        /// <summary>
        /// Sets the current Icon to use.
        /// </summary>
        /// <param name="icon">The Icon to set. The icon class has a constuctor that accepts the path to the Icon file.</param>
        /// <returns>Whether setting the icon succeded or not.</returns>
        public static bool SetConsoleIcon(Icon icon)
        {
            return SetConsoleIcon(icon.Handle);
        }
    }
}
"@
Add-Type -AssemblyName System.Drawing
$__Par = New-Object System.CodeDom.Compiler.CompilerParameters
$__Par.GenerateInMemory = $true
[appdomain]::CurrentDomain.GetAssemblies() | %{ if ($_.Location -ne $null) { $__Par.ReferencedAssemblies.Add($_.Location) | Out-Null } }
Add-Type $__source -CompilerParameters $__Par
Remove-Variable "__Par","__source"

function Set-Shell
{
	<#
		.SYNOPSIS
			Changes the PowerShell Window.
	
		.DESCRIPTION
			Changes the PowerShell Window. It allows changing colors, width and backlog.
	
			Valid color parameters:
			Black, DarkBlue, DarkGreen, DarkCyan, DarkRed, DarkMagenta, DarkYellow,
			Gray, DarkGray, Blue, Green, Cyan, Red, Magenta, Yellow, White.
	
			Supports the PSReadline Module.
	
		.PARAMETER WindowWidth
			Changes the width of the PowerShell Window. Default is usually 80
			140 is on the fairly wide side.
	
		.PARAMETER BackgroundColor
			Changes the background-color.
			Clear the screen (cls) to avoid graphical errors.
	
		.PARAMETER ForegroundColor
			Changes the font color
	
		.PARAMETER BufferLength
			Changes the lines the shell backlogs (remembers)
	
		.PARAMETER WindowTitle
			Changes the text at the top of the PowerShell-Window
			You don't really need this, do you?
	
		.PARAMETER Icon
			Sets the Icon of the console window.
	
		.EXAMPLE
			PS C:\> Set-Shell WindowWidth 200
	
			Sets the width of the powershell console window to 200 (if your screen can handle it)
	
		.EXAMPLE
			PS C:\> Set-Shell -BufferLength 2000
	
			Sets the length of the console buffer (the "memory", how far you can scroll upwards) to 2000 lines.
	
		.EXAMPLE
			PS C:\> Set-Shell -WindowWidth 140 -BackgroundColor Blue -ForegroundColor Cyan -BufferLength 2000 -WindowTitle "This looks wicked" -Icon "C:\temp\Example.ico"
	
			This sets window width to 140, background color to blue, foreground to cyan, buffer length to 2000 the Title to "This looks wicked" (it does!) and changes the console Icon to whatever is in the example icon file.
	
		.NOTES
			Supported Interfaces:
			------------------------
			
			Author:			Friedrich Weinmann
			Company:		die netzwerker Computernetze GmbH
			Created:		11.11.2013
			LastChanged:	02.09.2014
			Version:		1.2
	#>
	[CmdletBinding()]
	Param (
		[int]
		$WindowWidth,
		
		[System.ConsoleColor]
		$BackgroundColor,
		
		[System.ConsoleColor]
		$ForegroundColor,
		
		[ValidateScript({ $_ -ge $host.ui.rawui.WindowSize.Height })]
		[int]
		$BufferLength,
		
		[string]
		$WindowTitle,
		
		[ValidateScript({ Test-Path $_ -PathType "Leaf" })]
		[string]
		$Icon
	)
	
	# Test whether the PSReadline Module is loaded
	$PSReadline = (Get-Module PSReadline) -ne $null
	
	#region Set Buffer
	if ($PSBoundParameters["BufferLength"])
	{
		$currentBuffer = $host.ui.rawui.Buffersize
		$currentBuffer.Height = $BufferLength
		$host.ui.rawui.Buffersize = $currentBuffer
	}
	#endregion Set Buffer
	
	#region Set Foreground Color
	if ($PSBoundParameters["ForegroundColor"])
	{
		$host.ui.rawui.ForegroundColor = $ForegroundColor
		
		if ($PSReadline)
		{
			Set-PSReadlineOption -ContinuationPromptForegroundColor $ForegroundColor
			Set-PSReadlineOption -ForegroundColor $ForegroundColor -TokenKind 'Comment'
		}
	}
	#endregion Set Foreground Color
	
	#region Set Background Color
	if ($PSBoundParameters["BackgroundColor"])
	{
		$host.ui.rawui.BackgroundColor = $BackgroundColor
		if ($PSReadline)
		{
			Set-PSReadlineOption -ContinuationPromptBackgroundColor $BackgroundColor
			Set-PSReadlineOption -BackgroundColor $BackgroundColor -TokenKind 'Comment'
			Set-PSReadlineOption -BackgroundColor $BackgroundColor -TokenKind 'Keyword'
			Set-PSReadlineOption -BackgroundColor $BackgroundColor -TokenKind 'String'
			Set-PSReadlineOption -BackgroundColor $BackgroundColor -TokenKind 'Operator'
			Set-PSReadlineOption -BackgroundColor $BackgroundColor -TokenKind 'Variable'
			Set-PSReadlineOption -BackgroundColor $BackgroundColor -TokenKind 'Command'
			Set-PSReadlineOption -BackgroundColor $BackgroundColor -TokenKind 'Type'
			Set-PSReadlineOption -BackgroundColor $BackgroundColor -TokenKind 'Number'
			Set-PSReadlineOption -BackgroundColor $BackgroundColor -TokenKind 'Member'
			Set-PSReadlineOption -BackgroundColor $BackgroundColor -TokenKind 'Parameter'
			Set-PSReadlineOption -EmphasisBackgroundColor $BackgroundColor
		}
	}
	#endregion Set Background Color
	
	#region Set Window Title
	if ($PSBoundParameters["WindowTitle"])
	{
		$host.ui.rawui.Windowtitle = $WindowTitle
	}
	#endregion Set Window Title
	
	#region Set Window Width
	if ($PSBoundParameters["WindowWidth"])
	{
		$maxWidth = $host.ui.rawui.MaxPhysicalWindowSize.Width
		if ($WindowWidth -gt $maxWidth) { Write-Warning "Window Width out of bounds. Maximum width allowed: $maxWidth" }
		else
		{
			$currentWindow = $host.ui.rawui.WindowSize
			$currentBuffer = $host.ui.rawui.Buffersize
			
			if ($currentBuffer.Width -gt $WindowWidth)
			{
				# Set Window
				$currentWindow.Width = $WindowWidth
				$host.ui.rawui.WindowSize = $currentWindow
				
				# Set Buffer
				$currentBuffer.Width = $WindowWidth
				$host.ui.rawui.Buffersize = $currentBuffer
			}
			else
			{
				# Set Buffer
				$currentBuffer.Width = $WindowWidth
				$host.ui.rawui.Buffersize = $currentBuffer
				
				# Set Window
				$currentWindow.Width = $WindowWidth
				$host.ui.rawui.WindowSize = $currentWindow
			}
		}
	}
	#endregion Set Window Width
	
	#region Set Icon
	if ($PSBoundParameters["Icon"])
	{
		try { [Netzwerker.Shell.Console.ConsoleHelper]::SetConsoleIcon($Icon) | Out-Null }
		catch
		{
			Write-Warning "Invalid Icon: $($_.Exception.Message)"
		}
	}
	#endregion Set Icon
}