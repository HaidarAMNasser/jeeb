param(
    [Parameter(Position=0)]
    [ValidateSet('auth','order','delivery','mixed','breakpoint','soak','all')]
    [string]$Scenario = 'mixed',

    [string]$ReportDir = 'reports',
    [string]$BaseUrl = '',
    [switch]$HtmlReport,
    [switch]$Quiet,
    [switch]$Local
)

$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$REPORT_PATH = Join-Path $SCRIPT_DIR $ReportDir

if (-not (Test-Path $REPORT_PATH)) {
    New-Item -ItemType Directory -Path $REPORT_PATH -Force | Out-Null
}

$hasK6 = $null -ne (Get-Command 'k6' -ErrorAction SilentlyContinue)

if (-not $hasK6 -and $Local) {
    Write-Host 'k6 not found locally. Use -Local switch but k6 is not installed.' -ForegroundColor Red
    exit 1
}

$useLocal = $hasK6 -and (-not $Local -or $Local)

if ($useLocal) {
    Write-Host 'Using local k6 installation' -ForegroundColor Green
} else {
    Write-Host 'Using Docker k6 (grafana/k6:latest)' -ForegroundColor Cyan
}

if (-not $BaseUrl) {
    if ($useLocal) {
        $BaseUrl = 'http://localhost:3000/api/v1'
    } else {
        $BaseUrl = 'http://host.docker.internal:3000/api/v1'
    }
}

$SCENARIO_MAP = @{
    'auth'       = 'scenarios/auth-flow.js'
    'order'      = 'scenarios/order-flow.js'
    'delivery'   = 'scenarios/delivery-flow.js'
    'mixed'      = 'scenarios/mixed-flow.js'
    'breakpoint' = 'scenarios/breakpoint-test.js'
    'soak'       = 'scenarios/soak-test.js'
}

if ($Scenario -eq 'all') {
    $scenariosToRun = $SCENARIO_MAP.Keys
} else {
    $scenariosToRun = @($Scenario)
}

$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'

foreach ($scenarioName in $scenariosToRun) {
    $scriptFile = $SCENARIO_MAP[$scenarioName]
    $hostScriptPath = Join-Path $SCRIPT_DIR $scriptFile

    $reportFile = "report_${scenarioName}_${timestamp}.json"
    $hostReportPath = Join-Path $REPORT_PATH $reportFile

    Write-Host '========================================' -ForegroundColor Cyan
    Write-Host "Running: $scenarioName" -ForegroundColor Cyan
    Write-Host "Script:  $scriptFile" -ForegroundColor Cyan
    Write-Host "URL:     $BaseUrl" -ForegroundColor Cyan
    Write-Host "Report:  $reportFile" -ForegroundColor Cyan
    Write-Host '========================================' -ForegroundColor Cyan

    if ($useLocal) {
        $k6Args = @(
            'run'
        )

        if (-not $Quiet) {
            $k6Args += '--quiet'
        }

        $k6Args += @(
            '--env', "K6_BASE_URL=$BaseUrl"
            '--summary-trend-stats', 'avg,min,med,max,p(90),p(95),p(99)'
        )

        if ($HtmlReport) {
            $k6Args += @('--out', "json=$hostReportPath")
        } else {
            $k6Args += @('--summary-export', $hostReportPath)
        }

        $k6Args += $hostScriptPath

        if ($Quiet) {
            $null = & k6 $k6Args 2>&1
        } else {
            & k6 $k6Args 2>&1
        }
    } else {
        $dockerArgs = @(
            'run', '--rm'
            '--add-host', 'host.docker.internal:host-gateway'
            '-v', "${SCRIPT_DIR}:/scripts"
            '-v', "${REPORT_PATH}:/reports"
            'grafana/k6:latest'
            'run'
        )

        if ($Quiet) {
            $dockerArgs += '--quiet'
        }

        $dockerArgs += @(
            '--env', "K6_BASE_URL=$BaseUrl"
            '--summary-trend-stats', 'avg,min,med,max,p(90),p(95),p(99)'
        )

        if ($HtmlReport) {
            $dockerArgs += @('--out', "json=$hostReportPath")
        } else {
            $dockerArgs += @('--summary-export', $hostReportPath)
        }

        $dockerArgs += "/scripts/$scriptFile"

        if ($Quiet) {
            $null = & docker $dockerArgs 2>&1
        } else {
            & docker $dockerArgs 2>&1
        }
    }

    $exitCode = $LASTEXITCODE
    if ($exitCode -eq 0) {
        Write-Host "OK $scenarioName completed successfully" -ForegroundColor Green
    } else {
        Write-Host "FAIL $scenarioName failed (exit code: $exitCode)" -ForegroundColor Red
    }
}

Write-Host '========================================' -ForegroundColor Cyan
Write-Host 'All tests completed!' -ForegroundColor Cyan
Write-Host "Reports saved to: $REPORT_PATH" -ForegroundColor Cyan
Write-Host '========================================' -ForegroundColor Cyan
