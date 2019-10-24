# Depth 1
if($x -le 1) {
    Write-Output 'Ok'
    If ( $PWD -like 'C:\Windows' ){
        Write-Output "You are in the good way!"
    }
}

# Depth 2
if($x -le 2) {
    Write-Output 'Ok'
    if ($PWD -like 'C:\Windows'){
        Write-Output "You are in the good way!"
    }

    foreach ($u in $All){
        Write-Output "In foreach Depth 2"
    }
}