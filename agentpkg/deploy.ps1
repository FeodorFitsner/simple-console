try {
    throw
}
catch [exception]{
    Write-Host "Exception: " $_.exception.message
    throw
}

Write-Host "Some final message!"
