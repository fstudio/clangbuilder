Function Invoke-FlashWindow {
    <#
        .SYSNOPSIS
            Flashes a window that has been hidden or minimized to the taskbar

        .DESCRIPTION
            Flashes a window that has been hidden or minimized to the taskbar

        .PARAMETER MainWindowHandle
            Handle of the window that will be set to flash

        .PARAMETER FlashRate
            The rate at which the window is to be flashed, in milliseconds.

            Default value is: 0 (Default cursor blink rate)

        .PARAMETER FlashCount
            The number of times to flash the window.

            Default value is: 2147483647

        .NOTES
            Name: Invoke-FlashWindow
            Author: Boe Prox
            Created: 26 AUG 2013
            Version History
                1.0 -- 26 AUG 2013 -- Boe Prox
                    -Initial Creation

        .LINK
            http://pinvoke.net/default.aspx/user32/FlashWindowEx.html
            http://msdn.microsoft.com/en-us/library/windows/desktop/ms679347(v=vs.85).aspx

        .EXAMPLE
            Start-Sleep -Seconds 5; Get-Process -Id $PID | Invoke-FlashWindow
            #Minimize or take focus off of console
 
            Description
            -----------
            PowerShell console taskbar window will begin flashing. This will only work if the focus is taken
            off of the console, or it is minimized.

        .EXAMPLE
            Invoke-FlashWindow -MainWindowHandle 565298 -FlashRate 150 -FlashCount 10

            Description
            -----------
            Flashes the window of handle 565298 for a total of 10 cycles while blinking every 150 milliseconds.
    #>
    [cmdletbinding()]
    Param (
        [parameter(ValueFromPipeline=$True,ValueFromPipeLineByPropertyName=$True)]
        [intptr]$MainWindowHandle,
        [parameter()]
        [int]$FlashRate = 0,
        [parameter()]
        [int]$FlashCount = ([int]::MaxValue)
    )
    Begin {        
        Try {
            $null = [Window]
        } Catch {
            Add-Type -TypeDefinition @"
            using System;
            using System.Collections.Generic;
            using System.Text;
            using System.Runtime.InteropServices;

            public class Window
            {
                [StructLayout(LayoutKind.Sequential)]
                public struct FLASHWINFO
                {
                    public UInt32 cbSize;
                    public IntPtr hwnd;
                    public UInt32 dwFlags;
                    public UInt32 uCount;
                    public UInt32 dwTimeout;
                }

                //Stop flashing. The system restores the window to its original state. 
                const UInt32 FLASHW_STOP = 0;
                //Flash the window caption. 
                const UInt32 FLASHW_CAPTION = 1;
                //Flash the taskbar button. 
                const UInt32 FLASHW_TRAY = 2;
                //Flash both the window caption and taskbar button.
                //This is equivalent to setting the FLASHW_CAPTION | FLASHW_TRAY flags. 
                const UInt32 FLASHW_ALL = 3;
                //Flash continuously, until the FLASHW_STOP flag is set. 
                const UInt32 FLASHW_TIMER = 4;
                //Flash continuously until the window comes to the foreground. 
                const UInt32 FLASHW_TIMERNOFG = 12; 


                [DllImport("user32.dll")]
                [return: MarshalAs(UnmanagedType.Bool)]
                static extern bool FlashWindowEx(ref FLASHWINFO pwfi);

                public static bool FlashWindow(IntPtr handle, UInt32 timeout, UInt32 count)
                {
                    IntPtr hWnd = handle;
                    FLASHWINFO fInfo = new FLASHWINFO();

                    fInfo.cbSize = Convert.ToUInt32(Marshal.SizeOf(fInfo));
                    fInfo.hwnd = hWnd;
                    fInfo.dwFlags = FLASHW_ALL | FLASHW_TIMERNOFG;
                    fInfo.uCount = count;
                    fInfo.dwTimeout = timeout;

                    return FlashWindowEx(ref fInfo);
                }
            }
"@
        }
    }
    Process {
        ForEach ($handle in $MainWindowHandle) {
            Write-Verbose ("Flashing window: {0}" -f $handle)
            $null = [Window]::FlashWindow($handle,$FlashRate,$FlashCount)
        }
    }
}