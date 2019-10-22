using namespace System.Management.Automation.Language

class nodeutility {

    [node[]] static ParseFile ([string]$File) {
        $ParsedFile     = [Parser]::ParseFile($file, [ref]$null, [ref]$Null)
        $RawAstDocument = $ParsedFile.FindAll({$args[0] -is [Ast]}, $false)
        $x=$RawAstDocument | ForEach-Object{if ( $null -eq $_.parent.parent.parent ) { $t = [nodeutility]::SetNode($_); if ( $null -ne  $t) { $t} } }
        return $x
    }

    [node[]] static ParseString ([string[]]$String) {
        $ParsedFile     = [Parser]::ParseInput($String, [ref]$null, [ref]$Null)
        $RawAstDocument = $ParsedFile.FindAll({$args[0] -is [Ast]}, $false)
        $x=$RawAstDocument | ForEach-Object{if ( $null -eq $_.parent.parent.parent ) { $t = [nodeutility]::SetNode($_); if ( $null -ne  $t) { $t} } }
        return $x
    }

    [node] static SetNode ([object]$e) {
        $node = $null
        Switch ( $e ) {
            { $psitem -is [IfStatementAst]      } { $node = [IfNode]::new($PSItem)      }
            { $psitem -is [ForEachStatementAst] } { $node = [ForeachNode]::new($PSItem) }
            { $psitem -is [WhileStatementAst]   } { $node = [WhileNode]::new($PSItem)   }
            { $psitem -is [SwitchStatementAst]  } { $node = [SwitchNode]::new($PSItem) }
            { $psitem -is [ForStatementAst]     } { $node = [ForNode]::new($PSItem)     }
            { $psitem -is [DoUntilStatementAst] } { $node = [DoUntilNode]::new($PSItem) }
            { $psitem -is [DoWhileStatementAst] } { $node = [DoWhileNode]::new($PSItem) }
            
        }
        return $node
    }

    ## override with parent, for sublevels
    [node] static SetNode ([object]$e,[node]$f) {
        $node = $null
        Switch ( $e ) {
            { $psitem -is [IfStatementAst]      } { $node = [IfNode]::new($PSItem,$f)      }
            { $psitem -is [ForEachStatementAst] } { $node = [ForeachNode]::new($PSItem,$f) }
            { $psitem -is [WhileStatementAst]   } { $node = [WhileNode]::new($PSItem,$f)   }
            { $psitem -is [SwitchStatementAst]  } { $node = [SwitchNode]::new($PSItem,$f) }
            { $psitem -is [ForStatementAst]     } { $node = [ForNode]::new($PSItem,$f)     }
            { $psitem -is [DoUntilStatementAst] } { $node = [DoUntilNode]::new($PSItem,$f) }
            { $psitem -is [DoWhileStatementAst] } { $node = [DoWhileNode]::new($PSItem,$f) }
            
        }
        return $node
    }

    [object[]] static GetASTitems () {
        return @(
            [ForEachStatementAst],
            [IfStatementAst],
            [WhileStatementAst],
            [SwitchStatementAst],
            [ForStatementAst],
            [DoUntilStatementAst],
            [DoWhileStatementAst]
        )
    }

    [String] static SetDefaultShape ([String]$e) {
        $Shape = $Null
        Switch ( $e ) {
            "If"       { $Shape = "diamond"       }
            "ElseIf"   { $Shape = "diamond"       }
            "Foreach"  { $Shape = "parallelogram" }
            "While"    { $Shape = "parallelogram" }
            "DoWhile"  { $Shape = "parallelogram" }
            "DoUntil"  { $Shape = "parallelogram" }
            "For"      { $Shape = "parallelogram" }
            Defaut     { $Shape = "box" }
            
        }
        return $Shape
    }

}

class node {
    [string]$Type
    [string]$Statement
    [String]$Description
    $Children = [System.Collections.Generic.List[node]]::new()
    [node]$Parent
    [int]$Depth
    $File
    hidden $DefaultShape
    hidden $Nodeid
    hidden $code
    hidden $NewContent
    hidden $raw

    node () {
        
    }

    node ([Ast]$e) {
        $this.raw = $e
        $this.file = $e.extent.file
        $this.SetDepth()
        $this.Guid()
        $this.DefaultShape = [nodeutility]::SetDefaultShape($this.Type)
    }

    node ([Ast]$e,[node]$f) {
        $this.raw = $e
        $this.parent = $f
        $this.file = $e.extent.file
        $this.SetDepth()
        $this.Guid()
        $this.DefaultShape = [nodeutility]::SetDefaultShape($this.Type)
    }

    ## override with parent, for sublevels
    [void] FindChildren ([Ast[]]$e,[node]$f) {
        foreach ( $d in $e ) {
            If ( $d.GetType() -in [nodeutility]::GetASTitems() ) {
                $this.Children.add([nodeutility]::SetNode($d,$f))
            }
        }
    }

    [void] FindDescription () {
        $tokens=@()
        [Parser]::ParseInput($this.code,[ref]$tokens,[ref]$null)
        
        $c = $tokens | Where-Object kind -eq "comment"
        If ( $c.count -gt 0 ) {
            #If ( $c[0].text -match '\<#\r\s+DiagramDescription:(?<description> .+)\r\s+#\>' ) {
            If ( $c[0].text -match 'DiagramDescription:(?<description>\s?[\w\s]+)' ) {
                $this.Description = $Matches.description.Trim() 
            } Else {
                $this.Description = $this.Statement
            }
        }
    }

    ## a revoir, avec comme base $code !
    #[void] SetDescription ([string]$e) {
    #    $this.Description = $e
    #    $f = (($this.raw.Extent.Text -split '\r?\n')[0]).Length
    #    $g = "<#`n    DiagramDescription: $e`n#>`n"
    #    $this.NewContent = $this.raw.Extent.Text.Insert($f+2,$g)
    #}

    ## a revoir, avec comme base $code !
    [void] SetDescription () {
        If ( $null -eq $this.Description ) {
            $this.Description = Read-Host -Prompt $("Description for {0}" -f $this.Statement)
        } Else { 
            $d = Read-Host -Prompt $("Actual description for {0} is: {1}" -f $this.Statement,$this.Description)
            if ( $null -ne $d ) {
                $this.Description = $d
            } else {
                $this.Description = $this.Statement
            }
         }
        
        # USE code Property !
        if ( $null -ne $this.Description ) {
            #$f = (($this.raw.Extent.Text -split '\r?\n')[0]).Length
            #$g = "<#`n    DiagramDescription: $($this.Description))`n#>`n"
            #$this.NewContent = $this.raw.Extent.Text.Insert($f+2,$g)
        }
        
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
            $this.Depth = 1
        } Else {
            If ( $this.type -in ("ElseNode","ElseIfNode","SwitchCaseNode") ) {
                $this.Depth = $this.Parent.depth
            } Else {
                $this.Depth = $this.Parent.Depth + 1
            }
        }

    }

    hidden [void] Guid (){
        $this.Nodeid = ([guid]::NewGuid()).Guid
    }
}

Class IfNode : node {
    
    [string]$Type = "If"

    IfNode ([Ast]$e) : base ($e) {
        
        If ( $e.Clauses.Count -ge 1 ) {
            for( $i=0; $i -lt $e.Clauses.Count ; $i++ ) {
                if ( $i -eq 0 ) {
                    $this.Statement = "If ( {0} )" -f $e.Clauses[$i].Item1.Extent.Text
                    $this.Code = $e.Clauses[$i].Item2.Extent.Text
                } else {
                    $this.Children.Add([ElseIfNode]::new($e.clauses[$i].Item1,$this,$this.Statement,$e.clauses[$i].Item2))
                }
            }
        }

        If ( $null -ne $e.ElseClause ) {
            $this.Children.Add([ElseNode]::new($e.ElseClause,$this,$this.Statement))
        }
        
        $this.FindChildren($this.raw.Clauses[0].Item2.Statements,$this)

    }

    IfNode ([Ast]$e,[node]$f) : base ($e,$f) {

        If ( $e.Clauses.Count -ge 1 ) {
            for( $i=0; $i -lt $e.Clauses.Count ; $i++ ) {
                if ( $i -eq 0 ) {
                    $this.Statement = "If ( {0} )" -f $e.Clauses[$i].Item1.Extent.Text
                    $this.Code = $e.Clauses[$i].Item2.Extent.Text
                } else {
                    $this.Children.Add([ElseIfNode]::new($e.clauses[$i].Item1,$this,$this.Statement,$e.clauses[$i].Item2))
                }
            }
        }

        If ( $null -ne $e.ElseClause ) {
            $this.Children.Add([ElseNode]::new($e.ElseClause,$this,$this.Statement))
        }


        $this.FindChildren($this.raw.Clauses[0].Item2.Statements,$this)

    }

}

Class ElseNode : node {
    [String]$Type = "Else"

    ElseNode ([Ast]$e,[node]$f,[string]$d)  : base ($e,$f) {
        $this.Statement = "Else From {0}" -f $d
        $this.FindChildren($this.raw.statements,$this)
        $this.code = $e.extent.Text
    }
}

Class ElseIfNode : node {
    [String]$Type = "ElseIf"
    #$f represente l element2 du tuple donc si on veut chercher ce qu il y a en dessous il faut utiliser ça

    ElseIfNode ([Ast]$e,[node]$j,[string]$d,[Ast]$f) : base ($e,$j) {
        $this.Statement = "ElseIf ( {0} ) From {1}" -f $e.Extent.Text,$d
        $item1ToSearch = $this.raw.extent.text
        $this.Code = ($this.raw.Parent.Clauses.where({$_.Item1.extent.text -eq $item1ToSearch})).Item2.Extent.Text

        $this.FindChildren($this.raw.Parent.Clauses.where({$_.item1.extent.text -eq $this.raw.extent.text}).item2.Statements,$this)
    }

}

Class SwitchNode : node {
    [String]$Type = "Switch"

    SwitchNode ([Ast]$e) : base ($e) {
        $this.Statement = "Switch ( "+ $e.Condition.extent.Text + " )"

        for( $i=0; $i -lt $e.Clauses.Count ; $i++ ) {
            $this.Children.Add([SwitchCaseNode]::new($e.clauses[$i].Item1,$this,$this.Statement,$e.clauses[$i].Item2))
        }

    }

    SwitchNode ([Ast]$e,[node]$f) : base ($e,$f) {
        $this.Statement = "Switch ( "+ $e.Condition.extent.Text + " )"

        for( $i=0; $i -lt $e.Clauses.Count ; $i++ ) {
            $this.Children.Add([SwitchCaseNode]::new($e.clauses[$i].Item1,$this.Statement,$e.clauses[$i].Item2,$this))
        }

    }

    ## pas réussi a chopper le "code" du switch .. du coup la description ne sra pas settable dans le script
    ## la description ne sera utilisable que pour le graph
    [void]SetDescription([string]$e) {
        $this.Description = $e
    }
}

Class SwitchCaseNode : node {
    [String]$Type = "SwitchCase"

    SwitchCaseNode ([Ast]$e,[node]$j,[string]$d,[Ast]$f) : base ($e,$j) {
        $this.Statement = "Case: {1} for Switch {0}" -f $d,$this.raw.Extent.Text

        $item1ToSearch = $this.raw.Value
        $this.Code = ($this.raw.Parent.Clauses.where({$_.Item1.Value -eq $item1ToSearch})).Item2.Extent.Text
    }

}

Class ForeachNode : node {
    [String]$Type = "Foreach"

    ForeachNode ([Ast]$e) : base ($e) {
        $this.Statement = "Foreach ( "+ $e.Variable.extent.Text +" in " + $e.Condition.extent.Text + " )"
        $this.code = $e.body.Extent.Text
        $this.FindChildren($this.raw.Body.Statements,$this)
    }

    ForeachNode ([Ast]$e,[node]$f) : base ($e,$f) {
        $this.Statement = "Foreach ( "+ $e.Variable.extent.Text +" in " + $e.Condition.extent.Text + " )"
        $this.code = $e.body.extent.Text
        $this.FindChildren($this.raw.Body.Statements,$this)
    }
}

Class WhileNode : node {
    [string]$Type = "While"

    WhileNode ([Ast]$e) : base ($e) {
        $this.Statement = "While ( "+ $e.Condition.extent.Text + " )"
        $this.code = $e.body.extent.Text
        $this.FindChildren($this.raw.Body.Statements,$this)
        
    }

    WhileNode ([Ast]$e,[node]$f) : base ($e,$f) {
        $this.Statement = "While ( "+ $e.Condition.extent.Text + " )"
        $this.code = $e.body.extent.Text
        $this.FindChildren($this.raw.Body.Statements,$this)
        
    }
}

Class ForNode : node {
    [string]$Type = "For"

    ForNode ([Ast]$e) : base ($e) {
        $this.Statement = "For ( "+ $e.Condition.extent.Text + " )"
        $this.code = $e.body.extent.Text
        $this.FindChildren($this.raw.Body.Statements,$this)
    }

    ForNode ([Ast]$e,[node]$f) : base($e,$f) {
        $this.Statement = "For ( "+ $e.Condition.extent.Text + " )"
        $this.code = $e.body.extent.Text
        $this.FindChildren($this.raw.Body.Statements,$this)
    }
}

Class DoUntilNode : node {
    [string]$Type = "DoUntil"

    DoUntilNode ([Ast]$e) : base($e) {
        $this.Statement = "Do Until ( "+ $e.Condition.extent.Text + " )"
        $this.code = $e.body.extent.Text
        $this.FindChildren($this.raw.Body.Statements,$this)
    }

    DoUntilNode ([Ast]$e,[node]$f) : base($e,$f) {
        $this.Statement = "Do Until ( "+ $e.Condition.extent.Text + " )"
        $this.code = $e.body.extent.Text
        $this.FindChildren($this.raw.Body.Statements,$this)
    }
}

Class DoWhileNode : node {
    [string]$Type = "DoWhile"

    DoWhileNode ([Ast]$e) : base($e) {
        $this.Statement = "Do While ( "+ $e.Condition.extent.Text + " )"
        $this.code = $e.body.extent.Text
        $this.FindChildren($this.raw.Body.Statements,$this)
    }

    DoWhileNode ([Ast]$e,[node]$f) : base($e,$f) {
        $this.Statement = "Do While ( "+ $e.Condition.extent.Text + " )"
        $this.code = $e.body.extent.Text
        $this.FindChildren($this.raw.Body.Statements,$this)
    }
}
