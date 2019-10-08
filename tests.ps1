

##########################>

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

    [object[]] static GetASTitems () {
        return @(
            [System.Management.Automation.Language.ForEachStatementAst],
            [System.Management.Automation.Language.IfStatementAst]
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
    hidden $raw

    node () {
        
    }

    
    [void]FindChildren ([System.Management.Automation.Language.Ast[]]$e) {
        foreach ( $d in $e ) {
            #write-host "ok..."
            If ( $d.GetType() -in [nodeutility]::GetASTitems() ) {
                #Write-Host "plop"
                $this.Children.add([nodeutility]::SetNode($d))
            }
        }
    }

    [node[]] GetChildren () {
        return $this.Children
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
                    $this.Children.Add([ElseIfNode]::new($e.clauses[$i].Item1,$this.Statement,$e.clauses[$i].Item2))
                }
            }
        }

        If ( $null -ne $e.ElseClause ) {
            $this.Children.Add([ElseNode]::new($e.ElseClause,$this.Statement))
        }

        $this.raw = $e

        $this.FindChildren($this.raw.Clauses[0].Item2.Statements)

    }

}

Class ElseNode : node {
    [String]$Type = "Else"

    ElseNode ([System.Management.Automation.Language.Ast]$e,[string]$d) {
        $this.Statement = "Else From {0}" -f $d
        $this.OffsetStart = $e.extent.StartOffset
        $this.OffsetEnd = $e.extent.EndOffset
        $this.raw = $e
        $this.FindChildren($this.raw.statements)
    }
}

Class ElseIfNode : node {
    [String]$Type = "ElseIf"
    #$f represente l element2 du tuple donc si on veut chercher ce qu il y a en dessous il faut utiliser ça
    ElseIfNode ([System.Management.Automation.Language.Ast]$e,[string]$d,[System.Management.Automation.Language.Ast]$f) {
        $this.Statement = "ElseIf ( {0} ) From {1}" -f $e.Extent.Text,$d
        $this.OffsetStart = $e.extent.StartOffset
        $this.OffsetEnd = $e.extent.EndOffset
        $this.raw = $e

        #$ast = $this.raw.Parent.Clauses.where({$_.item1.extent.text -eq $this.raw.extent.text}).item2.Statements

        $this.FindChildren($this.raw.Parent.Clauses.where({$_.item1.extent.text -eq $this.raw.extent.text}).item2.Statements)
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
            $this.Children.Add([SwitchCaseNode]::new($e.clauses[$i].Item1,$this.Statement,$e.clauses[$i].Item2))
        }

    }
}

Class SwitchCaseNode : node {
    [String]$Type = "SwitchCase"

    SwitchCaseNode ([System.Management.Automation.Language.Ast]$e,[string]$d,[System.Management.Automation.Language.Ast]$f) {
        $this.OffsetStart = $e.extent.StartOffset
        $this.OffsetEnd = $e.extent.EndOffset
        $this.raw = $e
        $this.FindChildren($f.statements)
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

        $this.FindChildren($this.raw.Body.Statements)
    }
}

Class WhileNode : node {
    [string]$Type = "While"

    WhileNode ([System.Management.Automation.Language.Ast]$e) {
        $this.Statement = "While ( "+ $e.Condition.extent.Text + " )"
        $this.OffsetStart = $e.extent.StartOffset
        $this.OffsetEnd = $e.extent.EndOffset
        $this.raw = $e

        $this.FindChildren($this.raw.Body.Statements)
    }
}

Class ForNode : node {
    [string]$Type = "For"

    ForNode ([System.Management.Automation.Language.Ast]$e) {
        $this.Statement = "For ( "+ $e.Condition.extent.Text + " )"
        $this.OffsetStart = $e.extent.StartOffset
        $this.OffsetEnd = $e.extent.EndOffset
        $this.raw = $e

       $this.FindChildren($this.raw.Body.Statements)
    }
}

Class DoUntilNode : node {
    [string]$Type = "DoUntil"

    DoUntilNode ([System.Management.Automation.Language.Ast]$e) {
        $this.Statement = "Do Until ( "+ $e.Condition.extent.Text + " )"
        $this.OffsetStart = $e.extent.StartOffset
        $this.OffsetEnd = $e.extent.EndOffset
        $this.raw = $e

       $this.FindChildren($this.raw.Body.Statements)
    }
}

Class DoWhileNode : node {
    [string]$Type = "DoWhile"

    DoWhileNode ([System.Management.Automation.Language.Ast]$e) {
        $this.Statement = "Do While ( "+ $e.Condition.extent.Text + " )"
        $this.OffsetStart = $e.extent.StartOffset
        $this.OffsetEnd = $e.extent.EndOffset
        $this.raw = $e

       $this.FindChildren($this.raw.Body.Statements)
    }
}


## Working example

$path = "C:\users\lx\gitperso\PSScriptDiagram\sample.ps1"
$ParsedFile     = [System.Management.Automation.Language.Parser]::ParseFile($path, [ref]$null, [ref]$Null)
$RawAstDocument = $ParsedFile.FindAll({$args[0] -is [System.Management.Automation.Language.Ast]}, $false)


$x=$RawAstDocument | %{if ( $null -eq $_.parent.parent.parent ) { $t = [nodeutility]::SetNode($_); if ( $null -ne  $t) { $t} } }
$x
