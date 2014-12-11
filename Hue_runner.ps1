param(
 [Alias("ju")]
 $UserID,
 [Alias("jp")]
 $Password,
 [Alias("j")]
 $JenkinsUrl, 
 [Alias("l")]
 $LightsUrl,
 [Alias("f")]
 $Failed = 0,
 [Alias("w")]
 $FailedBuilding = 12750,
 [Alias("b")]
 $Building = 46920,
 [Alias("p")]
 $Passed = 25717,
 [alias("u")]
 $Unstable = 6000,
 [Alias("r")]
 $Brightness = 255,
 [Alias("s")]
 $Saturation = 255
)

function Get-Basic-Auth {
    $Key = $UserID + ":" + $Password
    $authVal = "Basic " + [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($key))
    
    return @{"AUTHORIZATION"=$authVal}
}

function Set-Color ($color){
    $hash = @{ hue = $color; bri = $Brightness; sat = $Saturation}
    $json = $hash | convertto-json
    $result = Invoke-WebRequest -uri $LightsUrl -Method PUT -Body $json
}

function Has-Status ($json, $status){
    
    for($i=0; $i -lt $json.jobs.length; $i++){
        
        if(($json.jobs[$i].color -eq $status) -or ($status.StartsWith("_") -and $json.jobs[$i].color.Contains($status) )){
            return $true
        }
    }
    return $false
}

function Get-Jenkins-Status {
    
    $Auth = Get-Basic-Auth
    $response = Invoke-WebRequest -Uri $JenkinsUrl -Headers $Auth
Write-Host $response.Content
    return $response.Content | ConvertFrom-Json
}

function Is-Building ($json){
    return Has-Status $json "_anime"
}

function Has-Failure($json){
    return Has-Status $json "red" -or Has-Status $json "red_anime"
}

function Has-Unstable($json){
    return Has-Status $json "yellow" -or Has-Status $json "yellow_anime"
}

function Is-Passed($json){
    $hasFailure = Has-Failure $json 
    $hasUnstable = Has-Unstable $json
    return  !$hasFailure -and !$hasUnstable
}

$json = Get-Jenkins-Status

if( Is-Building $json ){
    if(Has-Failure $json ){
        Write-Host "Is Building Has Failure"
        Set-Color  $FailedBuilding
    }
    else{
        Write-Host "Is Building"
        Set-Color $Building
    }
}
else{
    if(Has-Failure $json ){
        Write-Host "Has Failure"
        Set-Color $Failed
    }
    elseif(Has-Unstable $json ) {
        Write-Host "The Build is Unstable"
        Set-Color $Unstable
    }
    elseif(Is-Passed $json ){
        Write-Host "Build Has Passed"
        Set-Color $Passed
    }
}
