# PSScriptDiagram

l idée est de récupe tous les if/where/foreach etc... et à chaque fois qu'on en trouve un, on peut ajouter une description, afin de créer un diagrame !

![plop](classes.png)


```powershell
## trouver les comments dans un script block précis, il faut utiliser la tokenization:
## imaginons qu'on cherche un comment de type : #--DiagramDescription: ceci est un IF!
## on recupère le text du 1° if, par exemple
$z=$x[0].raw.Clauses[0].Item2.Extent.Text
$tokens=@()
[System.Management.Automation.Language.Parser]::ParseInput($z,[ref]$tokens,[ref]$null)
$c = $tokens | where kind -eq "comment"
## on recup le premier parce que il faut qu'il soit en dessous du if. pseudo règle ... !
```
