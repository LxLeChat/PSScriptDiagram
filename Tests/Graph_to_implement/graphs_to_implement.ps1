
<# graph sans subgraph ! graph "normal"
$graph = graph -Name "lol" -attributes @{rankdir='LR'} {

    $x.foreach({
        node $_::id -attributes @{label=$_.statement}
    })

    $x.GetChildren($True).foreach({
        node $_::id -attributes @{label=$_.statement}
    })

    for ( $i=0;$i -lt $x.count ; $i++ ) {
        edge -from $x[$i]::id -to $x[$i+1]::id
    }

   $x.foreach({
        foreach ( $node in $_.getchildren($true) ) {
            if ( $node.parent.statement -eq $x[$i].Statement ) {
                edge -From $x[$i]::id -To $node::id
            } else {
                edge -from $node.parent::id -to $node::id
            }
        }
    })
}
#>

<#
# graph avec subgraph
$graph = graph -Name "lol"  {
    for ( $i =0 ; $i -lt $x.count; $i++ ) {
        subgraph _$i {
            node -name $x[$i]::id -attributes @{label=$x[$i].statement}
            foreach ( $node in $x[$i].GetChildren($true) ) {
                node -name $node::id -attributes @{label=$node.statement}
                edge -From $node.parent::id -to $node::id
            }
        }

        edge -from $x[$i].getchildren($true)[$x[$i].GetChildren($true).Count -1]::id -to $x[$i+1]::id -attributes @{ltail="cluster_$i";lhead="cluster_$($i+1)"}
        
    }
}
#>
