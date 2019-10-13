

class nodeutility {

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
    [int]$OffsetStart
    [int]$OffsetEnd
    [String]$Description
    $Children = [System.Collections.Generic.List[node]]::new()
    [node]$parent
    hidden $raw

    node () {
        
    }

    ## override with parent, for sublevels
    [void] FindChildren ([System.Management.Automation.Language.Ast[]]$e,[node]$f) {
        foreach ( $d in $e ) {
            #write-host "ok..."
            If ( $d.GetType() -in [nodeutility]::GetASTitems() ) {
                #Write-Host "plop"
                $this.Children.add([nodeutility]::SetNode($d,$f))
            }
        }
    }

    # normalement on en a plus besoin
    #inutile
    [void] FindChildren ([System.Management.Automation.Language.Ast[]]$e) {
        foreach ( $d in $e ) {
            #write-host "ok..."
            If ( $d.GetType() -in [nodeutility]::GetASTitems() ) {
                #Write-Host "plop"
                $this.Children.add([nodeutility]::SetNode($d,$this))
            }
        }
    }

    [void] SetDescription () {
        $tokens=@()
        Switch ( $this.Type ) {
            "If" { [System.Management.Automation.Language.Parser]::ParseInput($this.raw.Clauses[0].Item2.Extent.Text,[ref]$tokens,[ref]$null) }
            ## Need to be populated
        }
        
        $c = $tokens | Where-Object kind -eq "comment"
        If ( $c.count -gt 0 ) {
            If ( $c[0].text -match '\<#\r\s+DiagramDescription:(?<description> .+)\r\s+#\>' ) { $this.Description = $Matches.description.Trim() }
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
                    $this.OffsetStart = $e.Clauses[$i].Item2.extent.StartOffset
                    $this.OffsetEnd = $e.Clauses[$i].Item2.extent.EndOffset
                } else {
                    $this.Children.Add([ElseIfNode]::new($e.clauses[$i].Item1,$this.Statement,$e.clauses[$i].Item2,$this))
                }
            }
        }

        If ( $null -ne $e.ElseClause ) {
            $this.Children.Add([ElseNode]::new($e.ElseClause,$this.Statement,$this))
        }

        $this.raw = $e

        $this.FindChildren($this.raw.Clauses[0].Item2.Statements,$this)

        $this.SetDescription()

    }

    IfNode ([System.Management.Automation.Language.Ast]$e,[node]$f) {
        
        If ( $e.Clauses.Count -ge 1 ) {
            for( $i=0; $i -lt $e.Clauses.Count ; $i++ ) {
                if ( $i -eq 0 ) {
                    $this.Statement = "If ( {0} )" -f $e.Clauses[$i].Item1.Extent.Text
                    $this.OffsetStart = $e.Clauses[$i].Item2.extent.StartOffset
                    $this.OffsetEnd = $e.Clauses[$i].Item2.extent.EndOffset
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

        #$this.FindChildren($this.raw.Clauses[0].Item2.Statements)
        $this.FindChildren($this.raw.Clauses[0].Item2.Statements,$this)

        $this.SetDescription()

    }

}

Class ElseNode : node {
    [String]$Type = "Else"

    ElseNode ([System.Management.Automation.Language.Ast]$e,[string]$d,[node]$f) {
        $this.Statement = "Else From {0}" -f $d
        $this.OffsetStart = $e.extent.StartOffset
        $this.OffsetEnd = $e.extent.EndOffset
        $this.raw = $e
        $this.parent = $f
        $this.FindChildren($this.raw.statements,$this)
    }
}

Class ElseIfNode : node {
    [String]$Type = "ElseIf"
    #$f represente l element2 du tuple donc si on veut chercher ce qu il y a en dessous il faut utiliser ça
    #inutile
    ElseIfNode ([System.Management.Automation.Language.Ast]$e,[string]$d,[System.Management.Automation.Language.Ast]$f) {
        $this.Statement = "ElseIf ( {0} ) From {1}" -f $e.Extent.Text,$d
        $this.OffsetStart = $e.extent.StartOffset
        $this.OffsetEnd = $e.extent.EndOffset
        $this.raw = $e

        #$ast = $this.raw.Parent.Clauses.where({$_.item1.extent.text -eq $this.raw.extent.text}).item2.Statements

        $this.FindChildren($this.raw.Parent.Clauses.where({$_.item1.extent.text -eq $this.raw.extent.text}).item2.Statements,$this)
    }

    ElseIfNode ([System.Management.Automation.Language.Ast]$e,[string]$d,[System.Management.Automation.Language.Ast]$f,[node]$j) {
        $this.Statement = "ElseIf ( {0} ) From {1}" -f $e.Extent.Text,$d
        $this.OffsetStart = $e.extent.StartOffset
        $this.OffsetEnd = $e.extent.EndOffset
        $this.raw = $e
        $this.parent = $j

        #$ast = $this.raw.Parent.Clauses.where({$_.item1.extent.text -eq $this.raw.extent.text}).item2.Statements

        #$this.FindChildren($this.raw.Parent.Clauses.where({$_.item1.extent.text -eq $this.raw.extent.text}).item2.Statements)
        $this.FindChildren($this.raw.Parent.Clauses.where({$_.item1.extent.text -eq $this.raw.extent.text}).item2.Statements,$this)
    }

}

Class SwitchNode : node {
    [String]$Type = "Switch"

    SwitchNode ([System.Management.Automation.Language.Ast]$e) {
        $this.Statement = "Switch ( "+ $e.Condition.extent.Text + " )"
        $this.OffsetStart = $e.extent.StartOffset
        $this.OffsetEnd = $e.extent.EndOffset
        $this.raw = $e

        for( $i=0; $i -lt $e.Clauses.Count ; $i++ ) {
            #$this.Children.Add([SwitchCaseNode]::new($e.clauses[$i].Item1,$this.Statement,$e.clauses[$i].Item2))
            $this.Children.Add([SwitchCaseNode]::new($e.clauses[$i].Item1,$this.Statement,$e.clauses[$i].Item2,$this))
        }

    }

    SwitchNode ([System.Management.Automation.Language.Ast]$e,[node]$f) {
        $this.Statement = "Switch ( "+ $e.Condition.extent.Text + " )"
        $this.OffsetStart = $e.extent.StartOffset
        $this.OffsetEnd = $e.extent.EndOffset
        $this.raw = $e
        $this.parent = $f

        for( $i=0; $i -lt $e.Clauses.Count ; $i++ ) {
            #$this.Children.Add([SwitchCaseNode]::new($e.clauses[$i].Item1,$this.Statement,$e.clauses[$i].Item2))
            $this.Children.Add([SwitchCaseNode]::new($e.clauses[$i].Item1,$this.Statement,$e.clauses[$i].Item2,$this))
        }

    }
}

Class SwitchCaseNode : node {
    [String]$Type = "SwitchCase"

    #inutile
    SwitchCaseNode ([System.Management.Automation.Language.Ast]$e,[string]$d,[System.Management.Automation.Language.Ast]$f) {
        $this.OffsetStart = $e.extent.StartOffset
        $this.OffsetEnd = $e.extent.EndOffset
        $this.raw = $e
        $this.FindChildren($f.statements,$this)
        $this.Statement = "Case: {1} for Switch {0}" -f $d,$this.raw.Extent.Text
    }

    SwitchCaseNode ([System.Management.Automation.Language.Ast]$e,[string]$d,[System.Management.Automation.Language.Ast]$f,[node]$j) {
        $this.OffsetStart = $e.extent.StartOffset
        $this.OffsetEnd = $e.extent.EndOffset
        $this.raw = $e
        $this.FindChildren($f.statements,$this)
        $this.parent = $j
        $this.Statement = "Case: {1} for Switch {0}" -f $d,$this.raw.Extent.Text
    }
}

Class ForeachNode : node {
    [String]$Type = "Foreach"

    ForeachNode ([System.Management.Automation.Language.Ast]$e) {
        $this.Statement = "Foreach ( "+ $e.Variable.extent.Text +" in " + $e.Condition.extent.Text + " )"
        $this.OffsetStart = $e.extent.StartOffset
        $this.OffsetEnd = $e.extent.EndOffset
        $this.raw = $e

        $this.FindChildren($this.raw.Body.Statements,$this)
    }

    ForeachNode ([System.Management.Automation.Language.Ast]$e,[node]$f) {
        $this.Statement = "Foreach ( "+ $e.Variable.extent.Text +" in " + $e.Condition.extent.Text + " )"
        $this.OffsetStart = $e.extent.StartOffset
        $this.OffsetEnd = $e.extent.EndOffset
        $this.raw = $e
        $this.parent = $f

        $this.FindChildren($this.raw.Body.Statements,$this)
    }
}

Class WhileNode : node {
    [string]$Type = "While"

    WhileNode ([System.Management.Automation.Language.Ast]$e) {
        $this.Statement = "While ( "+ $e.Condition.extent.Text + " )"
        $this.OffsetStart = $e.extent.StartOffset
        $this.OffsetEnd = $e.extent.EndOffset
        $this.raw = $e

        $this.FindChildren($this.raw.Body.Statements,$this)
        
    }

    WhileNode ([System.Management.Automation.Language.Ast]$e,[node]$f) {
        $this.Statement = "While ( "+ $e.Condition.extent.Text + " )"
        $this.OffsetStart = $e.extent.StartOffset
        $this.OffsetEnd = $e.extent.EndOffset
        $this.raw = $e
        $this.parent = $f

        $this.FindChildren($this.raw.Body.Statements,$this)
        
    }
}

Class ForNode : node {
    [string]$Type = "For"

    ForNode ([System.Management.Automation.Language.Ast]$e) {
        $this.Statement = "For ( "+ $e.Condition.extent.Text + " )"
        $this.OffsetStart = $e.extent.StartOffset
        $this.OffsetEnd = $e.extent.EndOffset
        $this.raw = $e

       $this.FindChildren($this.raw.Body.Statements,$this)
    }

    ForNode ([System.Management.Automation.Language.Ast]$e,[node]$f) {
        $this.Statement = "For ( "+ $e.Condition.extent.Text + " )"
        $this.OffsetStart = $e.extent.StartOffset
        $this.OffsetEnd = $e.extent.EndOffset
        $this.raw = $e
        $this.parent = $f

       $this.FindChildren($this.raw.Body.Statements,$this)
    }
}

Class DoUntilNode : node {
    [string]$Type = "DoUntil"

    DoUntilNode ([System.Management.Automation.Language.Ast]$e) {
        $this.Statement = "Do Until ( "+ $e.Condition.extent.Text + " )"
        $this.OffsetStart = $e.extent.StartOffset
        $this.OffsetEnd = $e.extent.EndOffset
        $this.raw = $e

       $this.FindChildren($this.raw.Body.Statements,$this)
    }

    DoUntilNode ([System.Management.Automation.Language.Ast]$e,[node]$f) {
        $this.Statement = "Do Until ( "+ $e.Condition.extent.Text + " )"
        $this.OffsetStart = $e.extent.StartOffset
        $this.OffsetEnd = $e.extent.EndOffset
        $this.raw = $e
        $this.parent = $f

       $this.FindChildren($this.raw.Body.Statements,$this)
    }
}

Class DoWhileNode : node {
    [string]$Type = "DoWhile"

    DoWhileNode ([System.Management.Automation.Language.Ast]$e) {
        $this.Statement = "Do While ( "+ $e.Condition.extent.Text + " )"
        $this.OffsetStart = $e.extent.StartOffset
        $this.OffsetEnd = $e.extent.EndOffset
        $this.raw = $e

       $this.FindChildren($this.raw.Body.Statements,$this)
    }

    DoWhileNode ([System.Management.Automation.Language.Ast]$e,[node]$f) {
        $this.Statement = "Do While ( "+ $e.Condition.extent.Text + " )"
        $this.OffsetStart = $e.extent.StartOffset
        $this.OffsetEnd = $e.extent.EndOffset
        $this.raw = $e
        $this.parent = $f
        

       $this.FindChildren($this.raw.Body.Statements,$this)
    }
}


## Working example

$path = "C:\users\lx\gitperso\PSScriptDiagram\sample.ps1"
$ParsedFile     = [System.Management.Automation.Language.Parser]::ParseFile($path, [ref]$null, [ref]$Null)
$RawAstDocument = $ParsedFile.FindAll({$args[0] -is [System.Management.Automation.Language.Ast]}, $false)


$x=$RawAstDocument | %{if ( $null -eq $_.parent.parent.parent ) { $t = [nodeutility]::SetNode($_); if ( $null -ne  $t) { $t} } }
$x

graph "tes" {
    $x | ForEach-Object { node $_.Statement ; if ( $_.Children.count ) { node $_.GetChildren().Statement }}
    edge $x.Statement
    $x | ForEach-Object { if ( $_.Children.count -gt 0 ) { edge -from $_.Statement -to $_.GetChildren().Statement }}
} |Show-PSGraph
