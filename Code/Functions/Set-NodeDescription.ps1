function Set-NodeDescription {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline)]
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
        $node
    }
    
    end {
        
    }
}