# check to ensure Microsoft.SharePoint.PowerShell is loaded if not using the SharePoint Management Shell 
$snapin = Get-PSSnapin | Where-Object {$_.Name -eq 'Microsoft.SharePoint.Powershell'} 
if ($snapin -eq $null) 
{    
	Write-Host "Loading SharePoint Powershell Snapin"    
	Add-PSSnapin "Microsoft.SharePoint.Powershell" 
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
   
    $newlistID = $web.Lists.Add($lib[0],"",$listTemplate);
    $list = $web.Lists[$newlistID];
    #$list.Update() 
    $list.EnableVersioning = $true;
    $list.EnableMinorVersions = $true;
    $list.ForceCheckout = $true;
    #Check if the list has enterprise column already
    #if ($list.Fields.ContainsField("Mots clés d’entreprise") -eq $false) # the site was in french so I needed to reference the library by its french DisplayName
    #{
        #Add Enterprise keywords column to list
    #    $list.Fields.Add($list.ParentWeb.AvailableFields["Mots clés d’entreprise"])
    #}

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
