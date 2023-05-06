# This script will discover the current monitors, find the latest *.rpd file in the current user's download folder, 
# and (by default) open the remote session with the 2 leftmost available monitors. The script assumes all monitors
# are on the same level (configurations with monitors placed above top of each other are not supported).
#
# Arguments:
# monitors: Number of desired monitors. Defaults to 2.
# offset: Number of monitors to skip from the left. Defaults to 0 (meaning we will start from the leftmost monitor).
param(
    [Int32]$monitors=2,
    [Int32]$offset=0
)

add-type -AssemblyName System.Windows.Forms

# Get the latest .rdp file from the downloads folder
$downloadFolder = (New-Object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path
$rdpFile = (Get-ChildItem $downloadFolder *.rdp | Sort-Object -Descending -Property LastWriteTime | Select-Object -First 1).FullName
if ($null -eq $rdpFile) {
    Write-Host "Error: No RDP file found in directory $downloadFolder"
    return
}

# Start mstsc.exe /l to get the monitors, copy the result using CTRL-C, and get it from the clipboard
$process = Start-Process mstsc.exe -ArgumentList "/l" -PassThru
do {
    Start-Sleep -Milliseconds 10
} while ($process.MainWindowHandle -eq 0)
[System.Windows.Forms.SendKeys]::SendWait("^{c}") 
Stop-Process -Id $process.Id
$text = Get-Clipboard

# From the result, parse the x coordinate of each monitor
$pattern = '\(([0-9\-]*)'
$regexMatches = [regex]::Matches($text, $pattern)
$order = @()
$i = 0
foreach ($regexMatch in $regexMatches) {
    $xValue = $regexMatch.Groups[1].Value -as [int];
    $order += [pscustomobject]@{x = $xValue; order = $i}
    $i++
}

# Sort the monitors by x coordinate and build the string to put in the RDP file
$order = $order | Sort-Object -Property x
$selectedMonitors = 'selectedmonitors:s:'
for ($i = $offset; $i -lt $monitors -and $i -lt $order.Count; $i++) {
    $selectedMonitors += ($order[$i].order -as [string]) + ','
}
$selectedMonitors = $selectedMonitors.Substring(0, $selectedMonitors.Length - 1)

# Add the value to the RDP file and invoke it
Add-Content -Path $rdpFile -Value $selectedMonitors
Invoke-Item $rdpFile
