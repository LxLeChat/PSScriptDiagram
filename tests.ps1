$path = "C:\Users\Lx\GitPerso\PSScriptDiagram\sample.ps1"
$ParsedFile     = [System.Management.Automation.Language.Parser]::ParseFile($path, [ref]$null, [ref]$Null)
$RawAstDocument = $ParsedFile.FindAll({$args[0] -is [System.Management.Automation.Language.Ast]}, $true)

##Les IFS
$Ifs = $RawASTDocument.FindAll({$args[0] -is [System.Management.Automation.Language.IfStatementAst]})

## retourne les clauses des ifs
$ifs.Clauses

## retourne le contenu de la clause
$ifs.Clauses.Item1

## retourne le else
$Ifs.ElseClause

## liste des choses à remonter, evidemment il faudrait du recurisf dans chacun de ces élements
## pour trouver tous ces types...
[System.Management.Automation.Language.IfStatementAst]
[System.Management.Automation.Language.SwitchStatementAst]
[System.Management.Automation.Language.ForEachStatementAst]
[System.Management.Automation.Language.ForStatementAst]
[System.Management.Automation.Language.DoUntilStatementAst]
[System.Management.Automation.Language.DoWhileStatementAst]
[System.Management.Automation.Language.WhileStatementAst]
# pipelineast pour les foreach-object/where-object

## determiner des icones par type d'objet
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
    [System.Management.Automation.Language.LoopStatementAst],
    [System.Management.Automation.Language.IfStatementAst]
)

$plop = $RawAstDocument.FindAll({$args[0].GetType() -in $a})

$array = @()
foreach ( $item in $plop ) {
    switch ( $item ) {
        { $psitem -is [System.Management.Automation.Language.LoopStatementAst] } { 
            $array += $psitem | select @{l='Type';e={"Foreach"}},@{l='statement';e={"Foreach( "+ $psitem.Variable.extent.Text +" in " + $psitem.Condition.extent.Text + " )" }},@{l='start';e={$item.extent.StartOffset}},@{l='End';e={$item.extent.EndOffset}},@{l='description';e={}}
        }

        { $psitem -is [System.Management.Automation.Language.IfStatementAst] } {

            If ( $psitem.Clauses.Count -ge 1 ) {
                
                for( $i=0; $i -lt $psitem.Clauses.Count ; $i++ ) {
                    if ( $i -eq 0 ) {
                        $array += $psitem.Clauses[$i] | select @{l='Type';e={"If"}},@{l='statement';e={$_.item1.Extent.Text}},@{l='start';e={$_.Item2.extent.StartOffset}},@{l='End';e={$_.Item2.extent.EndOffset}},@{l='description';e={}}
                    } else {
                        $array +=  $psitem.Clauses[$i] | select @{l='Type';e={"ElseIf"}},@{l='statement';e={$_.item1.Extent.Text}},@{l='start';e={$_.Item2.extent.StartOffset}},@{l='End';e={$_.Item2.extent.EndOffset}},@{l='description';e={}}
                    }
                }
            }

            If ( $null -ne $psitem.ElseClause ) {
                $array +=  $psitem | select @{l='Type';e={"Else"}},@{l='statement';e={}},@{l='start';e={$_.ElseClause.extent.StartOffset}},@{l='End';e={$_.ElseClause.extent.EndOffset}},@{l='description';e={}}
            }

        }
    }
}


graph depencies @{rankdir='LR'}{
    Foreach ( $t in $array ) {
        if ( $t.type -eq 'if') {
            node -Name $t.description
        }
        
        node -Name $t.name -Attributes @{Color='green'}
    }
}