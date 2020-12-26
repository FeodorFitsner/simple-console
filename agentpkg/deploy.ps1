try {
    throw
}
catch [exception]{
    Write-Host "Exception: " $_.exception.message
    throw
}

dir

Write-Host "Some final message!"
