## NEED TO TRANSLATE TO ENGLISH :)
## Reminder: it's a work in progress !

# PSScriptDiagram
Idea: Fetching all ifs,loops etc ... to graph a diagram of an entire script (not a module...)

![plop](classes.png)

example of i what i want to achieve
![plopy](example.png)

# A regler
- Si on a un script "avancé", propre en somme .. avec des blocs ça chie ... donc  faut trouver un moyen, et encore pire si y a des blocs begin/process etc... limite on pourrait appliquer ça à des fonctions aussi .. !  en tout cas y a une base !
- pour des scripts "lambda" ça à l air de fonctionner correctement...

```powershell
#Method qui set la description, lorsqu'un format de commentaire special est utilisé
# le format étant le suivant
<#
    DiagramDescription: Blalalalala
#>

#ce commentaire doit être le premier commentaire qui apparait dans le corps du noeud

## a mettre dans la classe node, et faire les différents cas pour les différents type de node
SetDescription () {
        $tokens=@()
        
        Switch ( $this.Type ) {
            "If" { [System.Management.Automation.Language.Parser]::ParseInput($this.raw.Clauses[0].Item2.Extent.Text,[ref]$tokens,[ref]$null) }
        }
        
        $c = $tokens | Where-Object kind -eq "comment"
        If ( $c.count -gt 0 ) {
            If ( $c[0].text -match '\<#\r\s+DiagramDescription:(?<description> .+)\r\s+#\>' ) { $this.Description = $Matches.description.Trim() }
        }
    }
```
