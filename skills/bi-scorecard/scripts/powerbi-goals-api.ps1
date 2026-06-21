param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('List', 'Get', 'Create', 'Update', 'Delete', 'GetRefreshHistory', 'RefreshCurrentValue', 'RefreshTargetValue', 'DeleteCurrentValueConnection', 'DeleteTargetValueConnection')]
    [string] $Action,

    [Parameter(Mandatory = $true)]
    [string] $GroupId,

    [Parameter(Mandatory = $true)]
    [string] $ScorecardId,

    [string] $GoalId,
    [string] $BodyPath,
    [string] $AccessToken,
    [switch] $ConfirmWrite
)

. "$PSScriptRoot/powerbi-rest-common.ps1"

$goalsPath = New-PowerBiScorecardPath -GroupId $GroupId -ScorecardId $ScorecardId -Suffix 'goals'

function Get-GoalPath {
    Assert-RequiredValue -Name 'GoalId' -Value $GoalId
    $encodedGoalId = ConvertTo-PowerBiPathSegment -Name 'GoalId' -Value $GoalId
    return "$goalsPath($encodedGoalId)"
}

switch ($Action) {
    'List' {
        Invoke-PowerBiRest -Method GET -Path $goalsPath -AccessToken $AccessToken
    }
    'Get' {
        Invoke-PowerBiRest -Method GET -Path (Get-GoalPath) -AccessToken $AccessToken
    }
    'Create' {
        Assert-ConfirmedWrite -Action $Action -ConfirmWrite:$ConfirmWrite
        Assert-RequiredValue -Name 'BodyPath' -Value $BodyPath
        Invoke-PowerBiRest -Method POST -Path $goalsPath -Body (Read-JsonObject -Path $BodyPath) -AccessToken $AccessToken
    }
    'Update' {
        Assert-ConfirmedWrite -Action $Action -ConfirmWrite:$ConfirmWrite
        Assert-RequiredValue -Name 'BodyPath' -Value $BodyPath
        Invoke-PowerBiRest -Method PATCH -Path (Get-GoalPath) -Body (Read-JsonObject -Path $BodyPath) -AccessToken $AccessToken
    }
    'Delete' {
        Assert-ConfirmedWrite -Action $Action -ConfirmWrite:$ConfirmWrite
        Invoke-PowerBiRest -Method DELETE -Path (Get-GoalPath) -AccessToken $AccessToken
    }
    'GetRefreshHistory' {
        Invoke-PowerBiRest -Method GET -Path "$(Get-GoalPath)/GetRefreshHistory()" -AccessToken $AccessToken
    }
    'RefreshCurrentValue' {
        Assert-ConfirmedWrite -Action $Action -ConfirmWrite:$ConfirmWrite
        Invoke-PowerBiRest -Method POST -Path "$(Get-GoalPath)/RefreshGoalCurrentValue()" -AccessToken $AccessToken
    }
    'RefreshTargetValue' {
        Assert-ConfirmedWrite -Action $Action -ConfirmWrite:$ConfirmWrite
        Invoke-PowerBiRest -Method POST -Path "$(Get-GoalPath)/RefreshGoalTargetValue()" -AccessToken $AccessToken
    }
    'DeleteCurrentValueConnection' {
        Assert-ConfirmedWrite -Action $Action -ConfirmWrite:$ConfirmWrite
        Invoke-PowerBiRest -Method POST -Path "$(Get-GoalPath)/DeleteGoalCurrentValueConnection()" -AccessToken $AccessToken
    }
    'DeleteTargetValueConnection' {
        Assert-ConfirmedWrite -Action $Action -ConfirmWrite:$ConfirmWrite
        Invoke-PowerBiRest -Method POST -Path "$(Get-GoalPath)/DeleteGoalTargetValueConnection()" -AccessToken $AccessToken
    }
}
