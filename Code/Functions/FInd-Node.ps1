function Find-Node {
    <#
    .SYNOPSIS
        Short description
    .DESCRIPTION
        Long description
    .EXAMPLE
        PS C:\> <example usage>
        Explanation of what the example does
    .INPUTS
        Inputs (if any)
    .OUTPUTS
        Output (if any)
    .NOTES
        General notes
    #>

    [CmdletBinding()]
    param (
        $File,
        [Switch]$FindDescription
    )
    
    begin {
        
    }
    
    process {
        $FilePath = Get-Item $File
        Write-Verbose -Message "[Find-Node] File FullName: $($FilePath.FullName)"
        If ( $PSBoundParameters["FindDescription"].IsPresent ) {
           Foreach ( $node in [nodeutility]::ParseFile($FilePath.FullName) ) {
               $node.FindDescription()
               $node
           } 
        } Else {
            return ,[nodeutility]::ParseFile($FilePath.FullName)
        }
    }
    
    end {
        
    }
}