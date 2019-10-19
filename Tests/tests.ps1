

class nodeutility {

    [node[]] static ParseFile ([string]$File) {
        $ParsedFile     = [System.Management.Automation.Language.Parser]::ParseFile($file, [ref]$null, [ref]$Null)
        $RawAstDocument = $ParsedFile.FindAll({$args[0] -is [System.Management.Automation.Language.Ast]}, $false)
        $x=$RawAstDocument | ForEach-Object{if ( $null -eq $_.parent.parent.parent ) { $t = [nodeutility]::SetNode($_); if ( $null -ne  $t) { $t} } }
        return $x
    }

    [node] static SetNode ([object]$e) {
        $node = $null
        Switch ( $e ) {
            { $psitem -is [System.Management.Automation.Language.IfStatementAst]      } { $node = [IfNode]::new($PSItem)      }
            { $psitem -is [System.Management.Automation.Language.ForEachStatementAst] } { $node = [ForeachNode]::new($PSItem) }
            { $psitem -is [System.Management.Automation.Language.WhileStatementAst]   } { $node = [WhileNode]::new($PSItem)   }
            { $psitem -is [System.Management.Automation.Language.SwitchStatementAst]  } { $node = [SwitchNode]::new($PSItem) }
            { $psitem -is [System.Management.Automation.Language.ForStatementAst]     } { $node = [ForNode]::new($PSItem)     }
            { $psitem -is [System.Management.Automation.Language.DoUntilStatementAst] } { $node = [DoUntilNode]::new($PSItem) }
            { $psitem -is [System.Management.Automation.Language.DoWhileStatementAst] } { $node = [DoWhileNode]::new($PSItem) }
            
        }
        return $node
    }

    ## override with parent, for sublevels
    [node] static SetNode ([object]$e,[node]$f) {
        $node = $null
        Switch ( $e ) {
            { $psitem -is [System.Management.Automation.Language.IfStatementAst]      } { $node = [IfNode]::new($PSItem,$f)      }
            { $psitem -is [System.Management.Automation.Language.ForEachStatementAst] } { $node = [ForeachNode]::new($PSItem,$f) }
            { $psitem -is [System.Management.Automation.Language.WhileStatementAst]   } { $node = [WhileNode]::new($PSItem,$f)   }
            { $psitem -is [System.Management.Automation.Language.SwitchStatementAst]  } { $node = [SwitchNode]::new($PSItem,$f) }
            { $psitem -is [System.Management.Automation.Language.ForStatementAst]     } { $node = [ForNode]::new($PSItem,$f)     }
            { $psitem -is [System.Management.Automation.Language.DoUntilStatementAst] } { $node = [DoUntilNode]::new($PSItem,$f) }
            { $psitem -is [System.Management.Automation.Language.DoWhileStatementAst] } { $node = [DoWhileNode]::new($PSItem,$f) }
            
        }
        return $node
    }

    [object[]] static GetASTitems () {
        return @(
            [System.Management.Automation.Language.ForEachStatementAst],
            [System.Management.Automation.Language.IfStatementAst],
            [System.Management.Automation.Language.WhileStatementAst],
            [System.Management.Automation.Language.SwitchStatementAst],
            [System.Management.Automation.Language.ForStatementAst],
            [System.Management.Automation.Language.DoUntilStatementAst],
            [System.Management.Automation.Language.DoWhileStatementAst]
        )
    }

}

class node {
    [string]$Type
    [string]$Statement
    [String]$Description
    $Children = [System.Collections.Generic.List[node]]::new()
    [node]$parent
    [int]$depth
    $file
    static $id = ([guid]::NewGuid()).Guid
    hidden $code
    hidden $NewContent
    hidden $raw

    node () {
        
    }

    ## override with parent, for sublevels
    [void] FindChildren ([System.Management.Automation.Language.Ast[]]$e,[node]$f) {
        foreach ( $d in $e ) {
            If ( $d.GetType() -in [nodeutility]::GetASTitems() ) {
                $this.Children.add([nodeutility]::SetNode($d,$f))
            }
        }
    }

    [void] FindDescription () {
        $tokens=@()
        <#
        Switch ( $this.Type ) {
            "If" { [System.Management.Automation.Language.Parser]::ParseInput($this.raw.Clauses[0].Item2.Extent.Text,[ref]$tokens,[ref]$null) }
            ## Need to be populated
        }
        #>

        [System.Management.Automation.Language.Parser]::ParseInput($this.code,[ref]$tokens,[ref]$null)
        
        $c = $tokens | Where-Object kind -eq "comment"
        If ( $c.count -gt 0 ) {
            If ( $c[0].text -match '\<#\r\s+DiagramDescription:(?<description> .+)\r\s+#\>' ) { $this.Description = $Matches.description.Trim() }
        }
    }

    ## a revoir, avec comme base $code !
    [void] SetDescription ([string]$e) {
        $this.Description = $e
        $f = (($this.raw.Extent.Text -split '\r?\n')[0]).Length
        $g = "<#`n    DiagramDescription: $e`n#>`n"
        $this.NewContent = $this.raw.Extent.Text.Insert($f+2,$g)
    }

    ## a revoir, avec comme base $code !
    [void] SetDescription () {
        If ( $null -eq $this.Description ) {
            $this.Description = Read-Host -Prompt $("Description for {0}" -f $this.Statement)
        } Else { Break; }
        
        $f = (($this.raw.Extent.Text -split '\r?\n')[0]).Length
        $g = "<#`n    DiagramDescription: $($this.Description))`n#>`n"
        $this.NewContent = $this.raw.Extent.Text.Insert($f+2,$g)
    }

    [node[]] GetChildren ([bool]$recurse) {
        $a = @()
        If ( $recurse ) {
            If ( $this.Children.count -gt 0 ) {
                foreach ( $child in $this.Children ) {
                    $a += $child.getchildren($true)
                }
                $a += $this.Children
            } else {
                break;
            }
        } else {
            $a=$this.Children
        }
                
        return $a
    }
    
    ## Need override in case of switchnodecase, elseif, and else
    [void] SetDepth () {
        If ( $null -eq $this.parent ) {
            $this.Depth = 0
        } Else {
            If ( $this.type -in ("ElseNode","ElseIfNode","SwitchCaseNode") ) {
                $this.Depth = $this.Parent.depth
            } Else {
                $this.Depth = $this.Parent.Depth + 1
            }
        }
    }
}

Class IfNode : node {
    
    [string]$Type = "If"

    IfNode ([System.Management.Automation.Language.Ast]$e) {
        
        If ( $e.Clauses.Count -ge 1 ) {
            for( $i=0; $i -lt $e.Clauses.Count ; $i++ ) {
                if ( $i -eq 0 ) {
                    $this.Statement = "If ( {0} )" -f $e.Clauses[$i].Item1.Extent.Text
                    $this.Code = $e.Clauses[$i].Item2.Extent.Text
                } else {
                    $this.Children.Add([ElseIfNode]::new($e.clauses[$i].Item1,$this.Statement,$e.clauses[$i].Item2,$this))
                }
            }
        }

        If ( $null -ne $e.ElseClause ) {
            $this.Children.Add([ElseNode]::new($e.ElseClause,$this.Statement,$this))
        }

        $this.raw = $e
        $this.file = $e.extent.file
        $this.FindChildren($this.raw.Clauses[0].Item2.Statements,$this)
        $this.SetDepth()
        #$this.FindDescription()

    }

    IfNode ([System.Management.Automation.Language.Ast]$e,[node]$f) {

        If ( $e.Clauses.Count -ge 1 ) {
            for( $i=0; $i -lt $e.Clauses.Count ; $i++ ) {
                if ( $i -eq 0 ) {
                    $this.Statement = "If ( {0} )" -f $e.Clauses[$i].Item1.Extent.Text
                    $this.Code = $e.Clauses[$i].Item2.Extent.Text
                } else {
                    $this.Children.Add([ElseIfNode]::new($e.clauses[$i].Item1,$this.Statement,$e.clauses[$i].Item2,$this))
                }
            }
        }

        If ( $null -ne $e.ElseClause ) {
            $this.Children.Add([ElseNode]::new($e.ElseClause,$this.Statement,$this))
        }

        $this.raw = $e
        $this.parent = $f
        $this.file = $e.extent.file
        $this.SetDepth()
        $this.FindChildren($this.raw.Clauses[0].Item2.Statements,$this)
        #$this.FindDescription()

    }

}

Class ElseNode : node {
    [String]$Type = "Else"

    ElseNode ([System.Management.Automation.Language.Ast]$e,[string]$d,[node]$f) {
        $this.Statement = "Else From {0}" -f $d
        $this.raw = $e
        $this.file = $e.extent.Text
        $this.parent = $f
        $this.file = $e.extent.file
        $this.FindChildren($this.raw.statements,$this)
        $this.SetDepth()
        $this.code = $e.extent.Text
    }
}

Class ElseIfNode : node {
    [String]$Type = "ElseIf"
    #$f represente l element2 du tuple donc si on veut chercher ce qu il y a en dessous il faut utiliser ça

    ElseIfNode ([System.Management.Automation.Language.Ast]$e,[string]$d,[System.Management.Automation.Language.Ast]$f,[node]$j) {
        $this.Statement = "ElseIf ( {0} ) From {1}" -f $e.Extent.Text,$d
        $this.raw = $e
        $this.parent = $j
        $this.file = $e.extent.file
        $this.SetDepth()
        $item1ToSearch = $this.raw.extent.text
        $this.Code = ($this.raw.Parent.Clauses.where({$_.Item1.extent.text -eq $item1ToSearch})).Item2.Extent.Text

        $this.FindChildren($this.raw.Parent.Clauses.where({$_.item1.extent.text -eq $this.raw.extent.text}).item2.Statements,$this)
    }

}

Class SwitchNode : node {
    [String]$Type = "Switch"

    SwitchNode ([System.Management.Automation.Language.Ast]$e) {
        $this.Statement = "Switch ( "+ $e.Condition.extent.Text + " )"
        $this.raw = $e
        $this.file = $e.extent.file

        for( $i=0; $i -lt $e.Clauses.Count ; $i++ ) {
            $this.Children.Add([SwitchCaseNode]::new($e.clauses[$i].Item1,$this.Statement,$e.clauses[$i].Item2,$this))
        }

        $this.SetDepth()

    }

    SwitchNode ([System.Management.Automation.Language.Ast]$e,[node]$f) {
        $this.Statement = "Switch ( "+ $e.Condition.extent.Text + " )"
        $this.raw = $e
        $this.parent = $f
        $this.file = $e.extent.file

        for( $i=0; $i -lt $e.Clauses.Count ; $i++ ) {
            $this.Children.Add([SwitchCaseNode]::new($e.clauses[$i].Item1,$this.Statement,$e.clauses[$i].Item2,$this))
        }

        $this.SetDepth()

    }

    ## pas réussi a chopper le "code" du switch .. du coup la description ne sra pas settable dans le script
    ## la description ne sera utilisable que pour le graph
    [void]SetDescription([string]$e) {
        $this.Description = $e
    }
}

Class SwitchCaseNode : node {
    [String]$Type = "SwitchCase"

    SwitchCaseNode ([System.Management.Automation.Language.Ast]$e,[string]$d,[System.Management.Automation.Language.Ast]$f,[node]$j) {
        $this.raw = $e
        $this.FindChildren($f.statements,$this)
        $this.parent = $j
        $this.file = $e.extent.file
        $this.Statement = "Case: {1} for Switch {0}" -f $d,$this.raw.Extent.Text

        $item1ToSearch = $this.raw.Value
        $this.Code = ($this.raw.Parent.Clauses.where({$_.Item1.Value -eq $item1ToSearch})).Item2.Extent.Text

        $this.SetDepth()
    }

}

Class ForeachNode : node {
    [String]$Type = "Foreach"

    ForeachNode ([System.Management.Automation.Language.Ast]$e) {
        $this.Statement = "Foreach ( "+ $e.Variable.extent.Text +" in " + $e.Condition.extent.Text + " )"
        $this.code = $e.body.Extent.Text
        $this.raw = $e
        $this.file = $e.extent.file
        $this.SetDepth()
        $this.FindChildren($this.raw.Body.Statements,$this)
    }

    ForeachNode ([System.Management.Automation.Language.Ast]$e,[node]$f) {
        $this.Statement = "Foreach ( "+ $e.Variable.extent.Text +" in " + $e.Condition.extent.Text + " )"
        $this.raw = $e
        $this.code = $e.body.extent.Text
        $this.parent = $f
        $this.file = $e.extent.file
        $this.SetDepth()
        $this.FindChildren($this.raw.Body.Statements,$this)
    }
}

Class WhileNode : node {
    [string]$Type = "While"

    WhileNode ([System.Management.Automation.Language.Ast]$e) {
        $this.Statement = "While ( "+ $e.Condition.extent.Text + " )"
        $this.code = $e.body.extent.Text
        $this.raw = $e
        $this.file = $e.extent.file
        $this.SetDepth()
        $this.FindChildren($this.raw.Body.Statements,$this)
        
    }

    WhileNode ([System.Management.Automation.Language.Ast]$e,[node]$f) {
        $this.Statement = "While ( "+ $e.Condition.extent.Text + " )"
        $this.code = $e.body.extent.Text
        $this.raw = $e
        $this.parent = $f
        $this.file = $e.extent.file
        $this.SetDepth()
        $this.FindChildren($this.raw.Body.Statements,$this)
        
    }
}

Class ForNode : node {
    [string]$Type = "For"

    ForNode ([System.Management.Automation.Language.Ast]$e) {
        $this.Statement = "For ( "+ $e.Condition.extent.Text + " )"
        $this.code = $e.body.extent.Text
        $this.raw = $e
        $this.file = $e.extent.file
        $this.SetDepth()
        $this.FindChildren($this.raw.Body.Statements,$this)
    }

    ForNode ([System.Management.Automation.Language.Ast]$e,[node]$f) {
        $this.Statement = "For ( "+ $e.Condition.extent.Text + " )"
        $this.code = $e.body.extent.Text
        $this.raw = $e
        $this.parent = $f
        $this.file = $e.extent.file
        $this.SetDepth()
        $this.FindChildren($this.raw.Body.Statements,$this)
    }
}

Class DoUntilNode : node {
    [string]$Type = "DoUntil"

    DoUntilNode ([System.Management.Automation.Language.Ast]$e) {
        $this.Statement = "Do Until ( "+ $e.Condition.extent.Text + " )"
        $this.code = $e.body.extent.Text
        $this.raw = $e
        $this.file = $e.extent.file
        $this.SetDepth()
        $this.FindChildren($this.raw.Body.Statements,$this)
    }

    DoUntilNode ([System.Management.Automation.Language.Ast]$e,[node]$f) {
        $this.Statement = "Do Until ( "+ $e.Condition.extent.Text + " )"
        $this.code = $e.body.extent.Text
        $this.raw = $e
        $this.parent = $f
        $this.file = $e.extent.file
        $this.SetDepth()
        $this.FindChildren($this.raw.Body.Statements,$this)
    }
}

Class DoWhileNode : node {
    [string]$Type = "DoWhile"

    DoWhileNode ([System.Management.Automation.Language.Ast]$e) {
        $this.Statement = "Do While ( "+ $e.Condition.extent.Text + " )"
        $this.code = $e.body.extent.Text
        $this.raw = $e
        $this.file = $e.extent.file
        $this.SetDepth()
        $this.FindChildren($this.raw.Body.Statements,$this)
    }

    DoWhileNode ([System.Management.Automation.Language.Ast]$e,[node]$f) {
        $this.Statement = "Do While ( "+ $e.Condition.extent.Text + " )"
        $this.code = $e.body.extent.Text
        $this.raw = $e
        $this.parent = $f
        $this.file = $e.extent.file
        $this.SetDepth()    
        $this.FindChildren($this.raw.Body.Statements,$this)
    }
}



## Exampple
$x=[nodeutility]::ParseFile("C:\users\lx\gitperso\PSScriptDiagram\sample.ps1")

<#
$graph = graph -Name "lol" -attributes @{rankdir='LR'} {

    $x.foreach({
        node $_.id -attributes @{label=$_.statement}
    })

    $x.GetChildren($True).foreach({
        node $_.id -attributes @{label=$_.statement}
    })

    for ( $i=0;$i -lt $x.count ; $i++ ) {
        edge -from $x[$i].id -to $x[$i+1].id
    }

   $x.foreach({
        foreach ( $node in $_.getchildren($true) ) {
            if ( $node.parent.statement -eq $x[$i].Statement ) {
                edge -From $x[$i].id -To $node.id
            } else {
                edge -from $node.parent.id -to $node.id
            }
        }
    })
}

$a=$graph | show-psgraph

#>
