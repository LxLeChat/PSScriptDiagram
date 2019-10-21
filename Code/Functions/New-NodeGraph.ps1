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
                        node -name $arrayofnodes[$i].Guid -attributes @{label=$arrayofnodes[$i]."$FindBetterVariableName"}
                        If ($arrayofnodes[$i].Children.Count -gt 0 ) {
                            foreach ( $n in $arrayofnodes[$i].GetChildren($true) ) {
                                node -name $n.Guid -attributes @{label=$n."$FindBetterVariableName"}
                                edge -From $n.parent.Guid -to $n.Guid
                            }
                        }

                    }
                    If ($arrayofnodes[$i].Children.Count -gt 0 ) {
                        edge -from $arrayofnodes[$i].getchildren($true)[$arrayofnodes[$i].GetChildren($true).Count -1].Guid -to $arrayofnodes[$i+1].Guid -attributes @{ltail="cluster_$i";lhead="cluster_$($i+1)"}
                    } Else {
                        edge -from $arrayofnodes[$i].Guid -to $arrayofnodes[$i+1].Guid -attributes @{ltail="cluster_$i";lhead="cluster_$($i+1)"}
                    }
                }
            }

        } Else {

            $graph = graph -Name "lol" -attributes @{rankdir='LR'} {

                $arrayofnodes.foreach({
                    node $_.Guid -attributes @{label=$_."$FindBetterVariableName"}
                })
            
                $arrayofnodes.GetChildren($True).foreach({
                    node $_.Guid -attributes @{label=$_."$FindBetterVariableName"}
                })
            
                for ( $i=0;$i -lt $x.count ; $i++ ) {
                    edge -from $arrayofnodes[$i].Guid -to $arrayofnodes[$i+1].Guid
                }
            
                $arrayofnodes.foreach({
                    foreach ( $n in $_.getchildren($true) ) {
                        if ( $n.parent.statement -eq $arrayofnodes[$i].Statement ) {
                            edge -From $arrayofnodes[$i].Guid -To $n.Guid
                        } else {
                            edge -from $n.parent.Guid -to $n.Guid
                        }
                    }
                })
            }

        }
        
        $graph
    }
}
