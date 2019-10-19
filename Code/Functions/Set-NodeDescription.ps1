function Set-NodeDescription {
    [CmdletBinding()]
    param (
        [node[]]$Node,
        [Switch]$Modify
    )
    
    begin {
        
    }
    
    process {
        $Node.SetDescription()
    }
    
    end {
        
    }
}