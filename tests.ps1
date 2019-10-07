<## determiner des icones par type d'objet
## essayer de faire un deroulement simple dans un premier temps
## moi ce que je vois:
## 1° temps: essayer de créer un tableau de ces objets dans une premiere phase du script
## 2° temps: pour chaque objet ajotuer une description
## 3° temps: grapher dans l ordre, en mettant la description dans l objets (objet du graph)

## stephane
## se baser sur des commentaires spéciaux ?


$a = @([System.Management.Automation.Language.IfStatementAst],
[System.Management.Automation.Language.SwitchStatementAst],
[System.Management.Automation.Language.ForEachStatementAst],
[System.Management.Automation.Language.ForStatementAst],
[System.Management.Automation.Language.DoUntilStatementAst],
[System.Management.Automation.Language.DoWhileStatementAst],
[System.Management.Automation.Language.WhileStatementAst])

$b = @(
    [System.Management.Automation.Language.ForEachStatementAst],
    [System.Management.Automation.Language.IfStatementAst]
)

##########################>

class nodeutility {

    [node] static SetNode ([object]$e) {
        $node = $null
        Switch ( $e ) {
            { $psitem -is [System.Management.Automation.Language.IfStatementAst] }      { $node = [IfNode]::new($PSItem) }
            { $psitem -is [System.Management.Automation.Language.ForEachStatementAst] } { $node = [ForeachNode]::new($PSItem) }
            { $psitem -is  [System.Management.Automation.Language.WhileStatementAst] }  { $node = [WhileNode]::new($PSItem) }
            #{ $psitem -is [System.Management.Automation.Language.SwitchStatementAst] }  { $node = [Node]::new($PSItem) }
            #{ $psitem -is [System.Management.Automation.Language.ForStatementAst] }     { $node = [Node]::new($PSItem) }
            #{ $psitem -is [System.Management.Automation.Language.DoUntilStatementAst] } { $node = [Node]::new($PSItem) }
            #{ $psitem -is [System.Management.Automation.Language.DoWhileStatementAst] } { $node = [Node]::new($PSItem) }
            
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

Class ForeachNode : node {
    [String]$Type = "Foreach"

    ForeachNode ([System.Management.Automation.Language.Ast]$e) {
        $this.Statement = "Foreach( "+ $e.Variable.extent.Text +" in " + $e.Condition.extent.Text + " )"
        $this.OffsetStart = $e.extent.StartOffset
        $this.OffsetEnd = $e.extent.EndOffset
        $this.raw = $e

        $this.FindChildren($this.raw.Body.Statements)
    }
}

Class WhileNode : node {
    [string]$Type = "While"

    WhileNode ([System.Management.Automation.Language.Ast]$e) {
        $this.Statement = "While( "+ $e.Condition.extent.Text + " )"
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