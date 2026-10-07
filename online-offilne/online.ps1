Get-ChildItem -Path $PSScriptRoot -Filter *.exe -Recurse | ForEach-Object {
    #
    Remove-NetFirewallRule -DisplayName "Block_Out_$($_.Name)" -ErrorAction SilentlyContinue
    Remove-NetFirewallRule -DisplayName "Block_In_$($_.Name)" -ErrorAction SilentlyContinue
    #
}