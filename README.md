## NEED TO TRANSLATE TO ENGLISH :)
GO CHECK FLOWCHART --> https://github.com/LxLeChat/FLowChart
## Reminder: it's a work in progress !

# PSScriptDiagram
Idea of the modyle: Fetching all ifs,loops etc ... to graph a diagram of an entire script (not a module...)
Behind the scene: working with AST, created my own siplified AST (i think ...) 
What it's not at the moment: a flowchart ... I think it's pretty complicated to code a flowchart from an existing script ... but i'll try !

## TODO
RenameCmdlets
work on valuefrompipeline for each function
Create a buildscript to create a unique psm1 file ... at the moment you have to load the classes, then then functions manually ...

example of i what i want to achieve
![plopy](Images/sample_subgraphs_lastchild_to_firstparent.png)


## Cmdletq available at the moment
$x = Find-Node -file .\script.ps1
Set-NodeDescription -node $x
New-NodeGraph -node $x -UseDescription -GroupAffiliatedNodes

test
