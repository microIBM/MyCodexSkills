param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('Get', 'Upsert', 'Delete')]
    [string] $Action,

    [Parameter(Mandatory = $true)]
    [string] $GroupId,

    [Parameter(Mandatory = $true)]
    [string] $ScorecardId,

    [Parameter(Mandatory = $true)]
    [string] $GoalId,

    [string] $BodyPath,
    [string] $AccessToken,
    [switch] $ConfirmWrite
)

. "$PSScriptRoot/powerbi-rest-common.ps1"

$encodedGoalId = ConvertTo-PowerBiPathSegment -Name 'GoalId' -Value $GoalId
$goalPath = (New-PowerBiScorecardPath -GroupId $GroupId -ScorecardId $ScorecardId -Suffix 'goals') + "($encodedGoalId)"
$statusRulesPath = "$goalPath/statusRules"

switch ($Action) {
    'Get' {
        Invoke-PowerBiRest -Method GET -Path $statusRulesPath -AccessToken $AccessToken
    }
    'Upsert' {
        Assert-ConfirmedWrite -Action $Action -ConfirmWrite:$ConfirmWrite
        Assert-RequiredValue -Name 'BodyPath' -Value $BodyPath
        Invoke-PowerBiRest -Method POST -Path $statusRulesPath -Body (Read-JsonObject -Path $BodyPath) -AccessToken $AccessToken
    }
    'Delete' {
        Assert-ConfirmedWrite -Action $Action -ConfirmWrite:$ConfirmWrite
        Invoke-PowerBiRest -Method DELETE -Path $statusRulesPath -AccessToken $AccessToken
    }
}
