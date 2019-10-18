# check to ensure Microsoft.SharePoint.PowerShell is loaded if not using the SharePoint Management Shell 
$snapin = Get-PSSnapin | Where-Object {$_.Name -eq 'Microsoft.SharePoint.Powershell'} 


while ($i -lt 10 ) {
    <#
        DiagramDescription: Premier While de la life quoi !
    #>
    "ahahah"
    if ( $kokokok -eq "aaa" ) {
        <#
        DiagramDescription: une description d un autre if
    #>
        foreach($a in $azeaze) {"kkkkk"}
    }
}


if ($snapin -eq $null) 
{
    <#
        DiagramDescription: If numero 2
    #> 
	Write-Host "Loading SharePoint Powershell Snapin"    
	Add-PSSnapin "Microsoft.SharePoint.Powershell" 
} else { "plop" }

if ( $truc ) {
    "clop"
} elseif ( $caca ) {
    foreach( $plop in $stuff) { "zazaz"}
    foreach( $a in $b) { if ($x) {"b"}}
} else {
    "bahahah"
    foreach($z in $y) {$z}
    if ($true) {"a"}
}

$a = {
    if ( $PROUT ) {}
}

switch ( $a ) {
    1 { if ($true) {"blop"} }
    2 { 2 }
    default { "bla" }
}

while ($i -lt 10) {
    If ( $i -eq 5) { "plop"}
}

do {
    If ( $i -eq 5) { "plop"}
} while ($i -eq 10)

do {
    If ( $i -eq 5) {
        
        "ahahaha"}
} until ($i -eq 10)

for ( $i=0;$i -lt 10;$i++) {

    If ( $i -eq 5) { "ahahaha"}

}

# This code creates a document library in a SharePoint 2013 team site and activate versioning and update title
# Updating the Title field is tricky and you have to use the Culture object to complete the task. We finally adds a link to the library
# on the left navigation.
# Note: I have commented out the part that activates Enterprise keywords because for some unknown reasons (that I don't know of...),
# it breaks the existing content types, meaning when you open for instance the a word document you get an error because the newly added
# Enterprise keyword is empty. Needs some investigation.

$libraries = @(,("[list_RealName]","[list_DisplayName]"));

$SiteUrl = [mysiteurl];
$listTemplate = [Microsoft.SharePoint.SPListTemplateType]::DocumentLibrary;
$web = Get-SPWeb $SiteUrl;
$ql = $web.Navigation.QuickLaunch;

foreach ($lib in $libraries)
{
   while ( $i -lt 10) {"a"}
    $newlistID = $web.Lists.Add($lib[0],"",$listTemplate);
    $list = $web.Lists[$newlistID];
    #$list.Update() 
    $list.EnableVersioning = $true;
    $list.EnableMinorVersions = $true;
    $list.ForceCheckout = $true;
    #Check if the list has enterprise column already
    if ($list.Fields.ContainsField("Mots clés d’entreprise") -eq $false) # the site was in french so I needed to reference the library by its french DisplayName
    {
        #Add Enterprise keywords column to list
    #    $list.Fields.Add($list.ParentWeb.AvailableFields["Mots clés d’entreprise"])
        "beuhaaaaaa"
    }

    $list.Update()
    
    ForEach($culture in $web.SupportedUICultures)
    {
            [System.Threading.Thread]::CurrentThread.CurrentUICulture=$culture;
            #$list = $web.Lists[$Name[0]]
            $list.Title = $lib[1];
            $list.Update();
    }
   
      

    $NewNode = New-Object Microsoft.SharePoint.Navigation.SPNavigationNode($list.Title,$list.DefaultViewUrl)
    $ql.AddAsLast($NewNode)

     write-host $lib[0] " added in" $web.Title "..." -foregroundcolor Green
}

$web.Dispose()

if ( $stuff ) {
    <#
        DiagramDescription: ceci est un if!
    #>
    foreach ( $plop in $blalal ) {
        "w"
    }
}

foreach ( $a in $b ) {
    if ( $i ) {
        "zzzz"
    }
}