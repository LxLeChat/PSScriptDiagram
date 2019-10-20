function New-NodeGraph {
    [CmdletBinding()]
    param (
        [node[]]$node,
        [switch]$UseDescirption,
        [switch]$GroupAffiliatedNodes
    )
    
    begin {
        $arrayofnodes = @()
        If ( $PSBoundParameters["UseDescription"].isPresent ) {
            $FindBetterVariableName = "Description"
        } else {
            $FindBetterVariableName = "Statement"
        }
    }
    
    process {
        $arrayofnodes += $node
    }
    
    end {
        If ( ! $PSBoundParameters["GroupAffiliatedNodes"].isPresent ) {

            $graph = graph -Name "lol"  {
                for ( $i =0 ; $i -lt $arrayofnodes.count; $i++ ) {
                    subgraph _$i {
                        node -name $arrayofnodes[$i]::id -attributes @{label=$arrayofnodes[$i]."$FindBetterVariableName"}
                        foreach ( $n in $arrayofnodes[$i].GetChildren($true) ) {
                            node -name $n::id -attributes @{label=$n."$FindBetterVariableName"}
                            edge -From $n.parent::id -to $n::id
                        }
                    }
                    edge -from $arrayofnodes[$i].getchildren($true)[$arrayofnodes[$i].GetChildren($true).Count -1]::id -to $arrayofnodes[$i+1]::id -attributes @{ltail="cluster_$i";lhead="cluster_$($i+1)"}
                    
                }
            }

        } Else {

            $graph = graph -Name "lol" -attributes @{rankdir='LR'} {

                $arrayofnodes.foreach({
                    node $_::id -attributes @{label=$_."$FindBetterVariableName"}
                })
            
                $arrayofnodes.GetChildren($True).foreach({
                    node $_::id -attributes @{label=$_."$FindBetterVariableName"}
                })
            
                for ( $i=0;$i -lt $x.count ; $i++ ) {
                    edge -from $arrayofnodes[$i]::id -to $arrayofnodes[$i+1]::id
                }
            
                $arrayofnodes.foreach({
                    foreach ( $n in $_.getchildren($true) ) {
                        if ( $n.parent.statement -eq $arrayofnodes[$i].Statement ) {
                            edge -From $arrayofnodes[$i]::id -To $n::id
                        } else {
                            edge -from $n.parent::id -to $n::id
                        }
                    }
                })
            }

        }
        
        $graph
    }
}