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