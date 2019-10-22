function New-NodeGraph {
    [CmdletBinding()]
    param (
        [node[]]$node,
        [switch]$UseDescription,
        [switch]$GroupAffiliatedNodes
    )
    
    begin {
        $arrayofnodes = @()
        If ( $PSBoundParameters["UseDescription"].isPresent ) {
            $labelscript = { If ( $null -eq $args[0].Description ){ $args[0].Statement } else { $args[0].Description } }
        } else {
            $labelscript = { $args[0].Statement }
        }

    }
    
    process {
        $arrayofnodes += $node
    }
    
    end {

        If ( $PSBoundParameters["GroupAffiliatedNodes"].isPresent ) {

            graph -Name "lol" @{rankdir='LR'}  {
                for ( $i =0 ; $i -lt $arrayofnodes.count; $i++ ) {
                    subgraph _$i {
                        node -name $arrayofnodes[$i].NodeId -attributes @{label=$labelscript.Invoke($arrayofnodes[$i])}
                        foreach ( $n in $arrayofnodes[$i].GetChildren($true) ) {
                            node -name $n.NodeId -attributes @{label=$labelscript.Invoke($n)}
                            edge -From $n.parent.NodeId -to $n.NodeId
                        }
                    }
                    edge -from $arrayofnodes[$i].getchildren($true)[$arrayofnodes[$i].GetChildren($true).Count -1].NodeId -to $arrayofnodes[$i+1].NodeId -attributes @{ltail="cluster_$i";lhead="cluster_$($i+1)"}
                    
                }
            }

        } Else {

            graph -Name "lol" -attributes @{rankdir='LR'} {

                $arrayofnodes.foreach({
                    node $_.NodeId -attributes @{label=$labelscript.Invoke($_)}
                })
            
                $arrayofnodes.GetChildren($True).foreach({
                    node $_.NodeId -attributes @{label=$labelscript.Invoke($_)}
                })
            
                for ( $i=0;$i -lt $x.count ; $i++ ) {
                    edge -from $arrayofnodes[$i].NodeId -to $arrayofnodes[$i+1].NodeId
                }
            
                $arrayofnodes.foreach({
                    foreach ( $n in $_.getchildren($true) ) {
                        if ( $n.parent.statement -eq $arrayofnodes[$i].Statement ) {
                            edge -From $arrayofnodes[$i].NodeId -To $n.NodeId
                        } else {
                            edge -from $n.parent.NodeId -to $n.NodeId
                        }
                    }
                })
            }

        }

    }
}
