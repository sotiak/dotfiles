# This profile is used only on Windows.

Import-Module PSReadLine

function which {
    Get-Command -ShowCommandInfo $args | ForEach-Object { $_.Definition }
}

Set-Alias -Name e -Value explorer.exe
Set-Alias -Name tig -Value "C:\Program Files\Git\usr\bin\tig.exe"

# zoxide

if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& {
        (zoxide init --hook pwd powershell | Out-String)
    })
}

Set-PSReadlineOption -BellStyle None # No more beep
Set-PSReadlineOption -HistoryNoDuplicates
Set-PSReadLineOption -PredictionSource History # Auto suggestions
Set-PSReadlineOption -EditMode Emacs
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete # Show Tab completion menu
Set-PSReadLineKeyHandler -Key Ctrl+n -Function TabCompleteNext
Set-PSReadLineKeyHandler -Key Ctrl+p -Function TabCompletePrevious
