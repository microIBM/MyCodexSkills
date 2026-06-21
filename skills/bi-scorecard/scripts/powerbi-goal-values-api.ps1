param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('List', 'Create', 'Delete')]
    [string] $Action,

    [Parameter(Mandatory = $true)]
    [string] $GroupId,

    [Parameter(Mandatory = $true)]
    [string] $ScorecardId,

    [Parameter(Mandatory = $true)]
    [string] $GoalId,

    [string] $Timestamp,
    [string] $BodyPath,
    [string] $AccessToken,
    [switch] $ConfirmWrite
)

. "$PSScriptRoot/powerbi-rest-common.ps1"

$encodedGoalId = ConvertTo-PowerBiPathSegment -Name 'GoalId' -Value $GoalId
$goalPath = (New-PowerBiScorecardPath -GroupId $GroupId -ScorecardId $ScorecardId -Suffix 'goals') + "($encodedGoalId)"
$goalValuesPath = "$goalPath/goalValues"

switch ($Action) {
    'List' {
        Invoke-PowerBiRest -Method GET -Path $goalValuesPath -AccessToken $AccessToken
    }
    'Create' {
        Assert-ConfirmedWrite -Action $Action -ConfirmWrite:$ConfirmWrite
        Assert-RequiredValue -Name 'BodyPath' -Value $BodyPath
        Invoke-PowerBiRest -Method POST -Path $goalValuesPath -Body (Read-JsonObject -Path $BodyPath) -AccessToken $AccessToken
    }
    'Delete' {
        Assert-ConfirmedWrite -Action $Action -ConfirmWrite:$ConfirmWrite
        Assert-RequiredValue -Name 'Timestamp' -Value $Timestamp
        # The timestamp is an OData datetime key and appears literally per the
        # Power BI REST reference — goalValues(2021-12-14T00:00:00Z) — so do NOT
        # percent-encode the colons (a strict OData parser rejects %3A). Validate
        # the ISO-8601 instant instead, which also keeps the segment injection-safe.
        if ($Timestamp -notmatch '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?Z$') {
            throw "Timestamp must be an ISO-8601 UTC instant like 2026-01-01T00:00:00Z (got: $Timestamp)"
        }
        Invoke-PowerBiRest -Method DELETE -Path "$goalValuesPath($Timestamp)" -AccessToken $AccessToken
    }
}
