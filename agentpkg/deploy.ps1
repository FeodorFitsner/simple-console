
try {
    throw "Hello!"
}
catch [exception]{
    Write-Host "Exception occured!"
    throw
}

Write-Host "Some final message!"
