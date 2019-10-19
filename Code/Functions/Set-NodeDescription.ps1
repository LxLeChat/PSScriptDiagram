function Set-NodeDescription {
    [CmdletBinding()]
    param (
        [node[]]$Node,
        [switch]$Recurse
    )
    
    begin {
        
    }
    
    process {
        $Node.SetDescription()
        If ( $PSboundParameters['Recurse'].IsPresent ) {
            $Node.GetChildren($True).SetDescription()
        }
    }
    
    end {
        
    }
}