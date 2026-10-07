Get-ChildItem -Path $PSScriptRoot -Filter *.exe -Recurse | ForEach-Object {
    #
    Remove-NetFirewallRule -DisplayName "Block_Out_$($_.Name)" -ErrorAction SilentlyContinue
    Remove-NetFirewallRule -DisplayName "Block_In_$($_.Name)" -ErrorAction SilentlyContinue
    #
    New-NetFirewallRule -DisplayName "Block_Out_$($_.Name)" -Direction Outbound -Program $_.FullName -Action Block
    New-NetFirewallRule -DisplayName "Block_In_$($_.Name)" -Direction Inbound -Program $_.FullName -Action Block
}
