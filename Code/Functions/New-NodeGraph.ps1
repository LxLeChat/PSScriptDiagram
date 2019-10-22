function New-NodeGraph {
    [CmdletBinding()]
    param (
        [node[]]$node,
        [switch]$UseDescription,
        [switch]$GroupAffiliatedNodes,
        [Switch]$UseFlowShapes
    )
    
    begin {
        $arrayofnodes = @()
        If ( $PSBoundParameters["UseDescription"].isPresent ) {
            $labelscript = { If ( $null -eq $args[0].Description ){ $args[0].Statement } else { $args[0].Description } }
        } else {
            $labelscript = { $args[0].Statement }
        }

        If ( $PSBoundParameters["UseFlowShapes"].isPresent ) {
            $Shapes = { $args[0].DefaultShape }
        } else {
            $Shapes = { "Box" }
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
                        node -name $arrayofnodes[$i].NodeId -attributes @{label=$labelscript.Invoke($arrayofnodes[$i]);shape=$Shapes.invoke($arrayofnodes[$i])}
                        foreach ( $n in $arrayofnodes[$i].GetChildren($true) ) {
                            node -name $n.NodeId -attributes @{label=$labelscript.Invoke($n);shape=$Shapes.invoke($arrayofnodes[$i])}
                            edge -From $n.parent.NodeId -to $n.NodeId
                        }
                    }
                    edge -from $arrayofnodes[$i].getchildren($true)[$arrayofnodes[$i].GetChildren($true).Count -1].NodeId -to $arrayofnodes[$i+1].NodeId -attributes @{ltail="cluster_$i";lhead="cluster_$($i+1)"}
                    
                }
            }

        } Else {

            graph -Name "lol" -attributes @{rankdir='LR'} {

                $arrayofnodes.foreach({
                    node $_.NodeId -attributes @{label=$labelscript.Invoke($_);shape=$Shapes.invoke($arrayofnodes[$i])}
                })
            
                $arrayofnodes.GetChildren($True).foreach({
                    node $_.NodeId -attributes @{label=$labelscript.Invoke($_);shape=$Shapes.invoke($arrayofnodes[$i])}
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
