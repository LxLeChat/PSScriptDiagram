using module ..\Code\Classes\classes.psm1
$TestsPath = Split-Path $MyInvocation.MyCommand.Path

$SampleLocation = Join-Path -Path $TestsPath -ChildPath 'scripts_samples'

$ItemSampleLocation = Get-Item -Path $SampleLocation

Push-Location -Path $ItemSampleLocation.FullName

set-location -Path $ItemSampleLocation.FullName

#InModuleScope -ModuleName classes -ScriptBlock {

Describe '[nodeutility] Test IfNode interpretation'{
    Context "Test If wihtout children"{
        $IfSamplePath = (Get-Item -Path './ifsampleWithoutChild.ps1').FullName
        $Result = [nodeutility]::ParseFile($IfSamplePath)
        It "Testing object type"{
            $Result -is [Node[]] | Should be $true
            $Result[0] -is [IfNode] | Should be $true
            $Result[0].Children -is [System.Collections.Generic.List[Node]] | Should be $true
        }

        It "Testing object property"{
            $Result[0].Statement -eq 'If ( $x -le 1 )' | Should be $true
            $Result[0].Depth -eq 1 | Should be $true
            $Result[0].Children.Count -eq 0
        }
    }

    Context "Test If with children"{
        $IfSamplePath = (Get-Item -Path './ifsampleWithChild.ps1').FullName
        $Result = [nodeutility]::ParseFile($IfSamplePath)
        It "[FirstIf]Testing parent object type"{
            $Result -is [Node[]] | Should be $true
            $Result[0] -is [IfNode] | Should be $true
            $Result[0].Children -is [System.Collections.Generic.List[Node]] | Should be $true
        }

        It "[FirstIf]Testing parent object property"{
            $Result[0].Statement -eq 'If ( $x -le 1 )' | Should be $true
            $Result[0].Depth -eq 1 | Should be $true
            $Result[0].Children.Count -eq 1
        }

        It "[FirstIf]Testing child If object type"{
            $Result[0].Children[0] -is [IfNode] | Should be $true
            $Result[0].Children[0].Children -is [System.Collections.Generic.List[Node]] | Should be $true
        }
        
        It "[FirstIf]Testing child If object property"{
            $Result[0].Children[0].Statement -eq "If ( `$PWD -like 'C:\Windows' )" | Should be $true
            $Result[0].Children[0].Depth -eq 2 | Should be $true
            $Result[0].Children[0].Children.Count -eq 0
        }

        It "[SecondIf]Testing parent object type"{
            $Result -is [Node[]] | Should be $true
            $Result[1] -is [IfNode] | Should be $true
            $Result[1].Children -is [System.Collections.Generic.List[Node]] | Should be $true
        }

        It "[SecondIf]Testing parent If object property"{
            $Result[1].Statement -eq 'If ( $x -le 2 )' | Should be $true
            $Result[1].Depth -eq 1 | Should be $true
            $Result[1].Children.Count -eq 1
        }

        It "[SecondIf]Testing child If object type"{
            $Result[1].Children[0] -is [IfNode] | Should be $true
            $Result[1].Children[0].Children -is [System.Collections.Generic.List[Node]] | Should be $true
        }
        
        It "[SecondIf]Testing child If object property"{
            $Result[1].Children[0].Statement -eq "If ( `$PWD -like 'C:\Windows' )" | Should be $true
            $Result[1].Children[0].Depth -eq 2 | Should be $true
            $Result[1].Children[0].Children.Count -eq 0
        }

        It "[SecondIf]Testing child foreach object type"{
            $Result[1].Children[1] -is [ForeachNode] | Should be $true
            $Result[1].Children[1].Children -is [System.Collections.Generic.List[Node]] | Should be $true
        }
        
        It "[SecondIf]Testing child foreach object property"{
            $Result[1].Children[1].Statement -eq "Foreach ( `$u in `$All )" | Should be $true
            $Result[1].Children[1].Depth -eq 2 | Should be $true
            $Result[1].Children[1].Children.Count -eq 0
        }
    }

}# end of Describe block

<#
Describe '[node]-[Constructors]'{

It '[node]-[Constructor] - Parameterless should Not Throw' {

# -- Arrange

# -- Act

# -- Assert

{[node]::New()} | Should Not Throw 

}# end of it block


It '[node]-[Constructor]([Ast]e) should Not Throw' {

# -- Arrange


[Ast]$e=''

# -- Act

# -- Assert

{[node]::New($e)} | Should Not Throw 

}# end of it block


It '[node]-[Constructor]([Ast]e,[node]f) should Not Throw' {

# -- Arrange


[Ast]$e=''


[node]$f=''

# -- Act

# -- Assert

{[node]::New($e,$f)} | Should Not Throw 

}# end of it block


}# end of Describe block
Describe '[IfNode]-[Constructors]'{

It '[IfNode]-[Constructor]([Ast]e) should Not Throw' {

# -- Arrange


[Ast]$e=''

# -- Act

# -- Assert

{[IfNode]::New($e)} | Should Not Throw 

}# end of it block


It '[IfNode]-[Constructor]([Ast]e,[node]f) should Not Throw' {

# -- Arrange


[Ast]$e=''


[node]$f=''

# -- Act

# -- Assert

{[IfNode]::New($e,$f)} | Should Not Throw 

}# end of it block


}# end of Describe block
Describe '[ElseNode]-[Constructors]'{

It '[ElseNode]-[Constructor]([Ast]e,[node]f,[string]d) should Not Throw' {

# -- Arrange


[Ast]$e=''


[node]$f=''


[string]$d=''

# -- Act

# -- Assert

{[ElseNode]::New($e,$f,$d)} | Should Not Throw 

}# end of it block


}# end of Describe block
Describe '[ElseIfNode]-[Constructors]'{

It '[ElseIfNode]-[Constructor]([Ast]e,[node]j,[string]d,[Ast]f) should Not Throw' {

# -- Arrange


[Ast]$e=''


[node]$j=''


[string]$d=''


[Ast]$f=''

# -- Act

# -- Assert

{[ElseIfNode]::New($e,$j,$d,$f)} | Should Not Throw 

}# end of it block


}# end of Describe block
Describe '[SwitchNode]-[Constructors]'{

It '[SwitchNode]-[Constructor]([Ast]e) should Not Throw' {

# -- Arrange


[Ast]$e=''

# -- Act

# -- Assert

{[SwitchNode]::New($e)} | Should Not Throw 

}# end of it block


It '[SwitchNode]-[Constructor]([Ast]e,[node]f) should Not Throw' {

# -- Arrange


[Ast]$e=''


[node]$f=''

# -- Act

# -- Assert

{[SwitchNode]::New($e,$f)} | Should Not Throw 

}# end of it block


}# end of Describe block
Describe '[SwitchCaseNode]-[Constructors]'{

It '[SwitchCaseNode]-[Constructor]([Ast]e,[node]j,[string]d,[Ast]f) should Not Throw' {

# -- Arrange


[Ast]$e=''


[node]$j=''


[string]$d=''


[Ast]$f=''

# -- Act

# -- Assert

{[SwitchCaseNode]::New($e,$j,$d,$f)} | Should Not Throw 

}# end of it block


}# end of Describe block
Describe '[ForeachNode]-[Constructors]'{

It '[ForeachNode]-[Constructor]([Ast]e) should Not Throw' {

# -- Arrange


[Ast]$e=''

# -- Act

# -- Assert

{[ForeachNode]::New($e)} | Should Not Throw 

}# end of it block


It '[ForeachNode]-[Constructor]([Ast]e,[node]f) should Not Throw' {

# -- Arrange


[Ast]$e=''


[node]$f=''

# -- Act

# -- Assert

{[ForeachNode]::New($e,$f)} | Should Not Throw 

}# end of it block


}# end of Describe block
Describe '[WhileNode]-[Constructors]'{

It '[WhileNode]-[Constructor]([Ast]e) should Not Throw' {

# -- Arrange


[Ast]$e=''

# -- Act

# -- Assert

{[WhileNode]::New($e)} | Should Not Throw 

}# end of it block


It '[WhileNode]-[Constructor]([Ast]e,[node]f) should Not Throw' {

# -- Arrange


[Ast]$e=''


[node]$f=''

# -- Act

# -- Assert

{[WhileNode]::New($e,$f)} | Should Not Throw 

}# end of it block


}# end of Describe block
Describe '[ForNode]-[Constructors]'{

It '[ForNode]-[Constructor]([Ast]e) should Not Throw' {

# -- Arrange


[Ast]$e=''

# -- Act

# -- Assert

{[ForNode]::New($e)} | Should Not Throw 

}# end of it block


It '[ForNode]-[Constructor]([Ast]e,[node]f) should Not Throw' {

# -- Arrange


[Ast]$e=''


[node]$f=''

# -- Act

# -- Assert

{[ForNode]::New($e,$f)} | Should Not Throw 

}# end of it block


}# end of Describe block
Describe '[DoUntilNode]-[Constructors]'{

It '[DoUntilNode]-[Constructor]([Ast]e) should Not Throw' {

# -- Arrange


[Ast]$e=''

# -- Act

# -- Assert

{[DoUntilNode]::New($e)} | Should Not Throw 

}# end of it block


It '[DoUntilNode]-[Constructor]([Ast]e,[node]f) should Not Throw' {

# -- Arrange


[Ast]$e=''


[node]$f=''

# -- Act

# -- Assert

{[DoUntilNode]::New($e,$f)} | Should Not Throw 

}# end of it block


}# end of Describe block
Describe '[DoWhileNode]-[Constructors]'{

It '[DoWhileNode]-[Constructor]([Ast]e) should Not Throw' {

# -- Arrange


[Ast]$e=''

# -- Act

# -- Assert

{[DoWhileNode]::New($e)} | Should Not Throw 

}# end of it block


It '[DoWhileNode]-[Constructor]([Ast]e,[node]f) should Not Throw' {

# -- Arrange


[Ast]$e=''


[node]$f=''

# -- Act

# -- Assert

{[DoWhileNode]::New($e,$f)} | Should Not Throw 

}# end of it block


}# end of Describe block

}#End InModuleScope


#>