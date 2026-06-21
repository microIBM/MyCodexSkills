param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('List', 'Get', 'GetByReportId', 'Create', 'Update', 'Delete', 'MoveGoals')]
    [string] $Action,

    [Parameter(Mandatory = $true)]
    [string] $GroupId,

    [string] $ScorecardId,
    [string] $ReportId,
    [string] $BodyPath,
    [string] $AccessToken,
    [switch] $ConfirmWrite
)

. "$PSScriptRoot/powerbi-rest-common.ps1"

switch ($Action) {
    'List' {
        Invoke-PowerBiRest -Method GET -Path (New-PowerBiScorecardPath -GroupId $GroupId) -AccessToken $AccessToken
    }
    'Get' {
        Assert-RequiredValue -Name 'ScorecardId' -Value $ScorecardId
        Invoke-PowerBiRest -Method GET -Path (New-PowerBiScorecardPath -GroupId $GroupId -ScorecardId $ScorecardId) -AccessToken $AccessToken
    }
    'GetByReportId' {
        $encodedGroupId = ConvertTo-PowerBiPathSegment -Name 'GroupId' -Value $GroupId
        $encodedReportId = ConvertTo-PowerBiPathSegment -Name 'ReportId' -Value $ReportId
        Invoke-PowerBiRest -Method GET -Path "groups/$encodedGroupId/scorecards/GetScorecardByReportId(reportId=$encodedReportId)" -AccessToken $AccessToken
    }
    'Create' {
        Assert-ConfirmedWrite -Action $Action -ConfirmWrite:$ConfirmWrite
        Assert-RequiredValue -Name 'BodyPath' -Value $BodyPath
        Invoke-PowerBiRest -Method POST -Path (New-PowerBiScorecardPath -GroupId $GroupId) -Body (Read-JsonObject -Path $BodyPath) -AccessToken $AccessToken
    }
    'Update' {
        Assert-ConfirmedWrite -Action $Action -ConfirmWrite:$ConfirmWrite
        Assert-RequiredValue -Name 'ScorecardId' -Value $ScorecardId
        Assert-RequiredValue -Name 'BodyPath' -Value $BodyPath
        Invoke-PowerBiRest -Method PATCH -Path (New-PowerBiScorecardPath -GroupId $GroupId -ScorecardId $ScorecardId) -Body (Read-JsonObject -Path $BodyPath) -AccessToken $AccessToken
    }
    'Delete' {
        Assert-ConfirmedWrite -Action $Action -ConfirmWrite:$ConfirmWrite
        Assert-RequiredValue -Name 'ScorecardId' -Value $ScorecardId
        Invoke-PowerBiRest -Method DELETE -Path (New-PowerBiScorecardPath -GroupId $GroupId -ScorecardId $ScorecardId) -AccessToken $AccessToken
    }
    'MoveGoals' {
        Assert-ConfirmedWrite -Action $Action -ConfirmWrite:$ConfirmWrite
        Assert-RequiredValue -Name 'ScorecardId' -Value $ScorecardId
        Assert-RequiredValue -Name 'BodyPath' -Value $BodyPath
        Invoke-PowerBiRest -Method POST -Path (New-PowerBiScorecardPath -GroupId $GroupId -ScorecardId $ScorecardId -Suffix 'MoveGoals()') -Body (Read-JsonObject -Path $BodyPath) -AccessToken $AccessToken
    }
}
