# Account switcher implementation plan

## Current Status
- [x] Updated global Git config to Kevin: `kevinseptiansss` / `kevinseptiansaputra@gmail.com`
- [x] Created `switch-gh.ps1` script in `c:\Users\kevin\SynologyDrive\FlowPOS\switch-gh.ps1`

## Next Steps

1.  **Add function to PowerShell Profile**: Update your `$PROFILE` to include the `switch-gh` function so it can be accessed from any path (like `C:\Users\kevin>`).
2.  **Initial Authentication**: Since `gh` auth requires manual login (browser/token), you should run the following commands once for each account to store them in your local keyring:
    *   `gh auth login --hostname github.com -u kevinseptianss` 
    *   `gh auth login --hostname github.com -u isysoftwareapp`

## Using the switcher
After setting it up, you can simply type:
```powershell
switch-gh kevin
# or
switch-gh isy
```
This will:
- Automatically update `git config --global user.name` and `user.email`.
- Automatically switch the `gh` account if already logged in.

## Profile addition script
I recommend adding the following to your profile (`C:\Users\kevin\OneDrive\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1`):
```powershell
function switch-gh {
    param (
        [Parameter(Mandatory=$true)]
        [ValidateSet("kevin", "isy")]
        $account
    )

    if ($account -eq "kevin") {
        Write-Host "Switching to Kevin (kevinseptianss)..." -ForegroundColor Cyan
        git config --global user.name "kevinseptianss"
        git config --global user.email "kevinseptiansaputra@gmail.com"
        gh auth switch --user kevinseptianss 2>$null
    }
    elseif ($account -eq "isysoftwareapp" -or $account -eq "isy") {
        Write-Host "Switching to ISY (isysoftwareapp)..." -ForegroundColor Cyan
        git config --global user.name "isysoftwareapp"
        git config --global user.email "info.isysoftware@gmail.com"
        gh auth switch --user isysoftwareapp 2>$null
    }
    
    Write-Host "`nUpdated Git Config:" -ForegroundColor Gray
    Write-Host "User: $(git config user.name)"
    Write-Host "Email: $(git config user.email)"
    Write-Host "`nGH CLI Status:" -ForegroundColor Gray
    gh auth status
}
```
