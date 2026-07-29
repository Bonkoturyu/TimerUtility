[CmdletBinding(DefaultParameterSetName = 'Invoke')]
param(
    [Parameter(ParameterSetName = 'Invoke')]
    [ValidateNotNullOrEmpty()]
    [string]$Prompt,

    [Parameter(ParameterSetName = 'Invoke')]
    [switch]$PromptFromStdin,

    [Parameter(ParameterSetName = 'Invoke')]
    [ValidateNotNullOrEmpty()]
    [string]$PromptFile,

    [Parameter(ParameterSetName = 'Invoke')]
    [ValidateSet('low', 'medium', 'high', 'xhigh', 'max')]
    [string]$Effort = 'high',

    [Parameter(ParameterSetName = 'Invoke')]
    [ValidateRange(1, 50)]
    [int]$MaxTurns = 20,

    [Parameter(ParameterSetName = 'Invoke')]
    [ValidateRange(30, 7200)]
    [int]$TimeoutSeconds = 1800,

    [Parameter(ParameterSetName = 'Invoke')]
    [switch]$AllowEdits,

    [Parameter(ParameterSetName = 'Invoke')]
    [switch]$NoTools,

    [Parameter(Mandatory = $true, ParameterSetName = 'Check')]
    [switch]$CheckOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$RequestedModel = 'opus'
$ExpectedCanonicalModel = 'claude-opus-5'
$Utf8NoBom = [System.Text.UTF8Encoding]::new($false)
[Console]::InputEncoding = $Utf8NoBom
[Console]::OutputEncoding = $Utf8NoBom
$OutputEncoding = $Utf8NoBom

if ($PSCmdlet.ParameterSetName -eq 'Invoke') {
    $promptSourceCount = @(
        $PSBoundParameters.ContainsKey('Prompt'),
        [bool]$PromptFromStdin,
        $PSBoundParameters.ContainsKey('PromptFile')
    ).Where({ $_ }).Count
    if ($promptSourceCount -ne 1) {
        throw 'Specify exactly one of -Prompt, -PromptFromStdin, or -PromptFile.'
    }

    if ($PromptFromStdin) {
        $Prompt = [Console]::In.ReadToEnd()
    }
    elseif ($PSBoundParameters.ContainsKey('PromptFile')) {
        $resolvedPromptFile = (Resolve-Path -LiteralPath $PromptFile).Path
        $Prompt = [System.IO.File]::ReadAllText(
            $resolvedPromptFile,
            [System.Text.Encoding]::UTF8
        )
    }

    if ([string]::IsNullOrWhiteSpace($Prompt)) {
        throw 'A non-empty prompt is required.'
    }
}

function Write-JsonResult {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Value,

        [int]$ExitCode = 0
    )

    $Value | ConvertTo-Json -Depth 32
    exit $ExitCode
}

function New-ClaudeProcessCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$Source
    )

    $resolvedPath = (Resolve-Path -LiteralPath $Path).Path
    if ([System.IO.Path]::GetExtension($resolvedPath) -ieq '.ps1') {
        $hostName = if ($PSVersionTable.PSEdition -eq 'Core') {
            if ([System.Environment]::OSVersion.Platform -eq
                [System.PlatformID]::Win32NT) {
                'pwsh.exe'
            }
            else {
                'pwsh'
            }
        }
        else {
            'powershell.exe'
        }
        $hostPath = Join-Path $PSHOME $hostName
        if (-not (Test-Path -LiteralPath $hostPath -PathType Leaf)) {
            throw "PowerShell host was not found: $hostPath"
        }

        return [pscustomobject]@{
            Path = $hostPath
            TargetPath = $resolvedPath
            ArgumentPrefix = @(
                '-NoProfile',
                '-ExecutionPolicy', 'Bypass',
                '-File', $resolvedPath
            )
            Source = "$Source-external-script"
        }
    }

    return [pscustomobject]@{
        Path = $resolvedPath
        TargetPath = $resolvedPath
        ArgumentPrefix = @()
        Source = $Source
    }
}

function Resolve-ClaudeExecutable {
    if (-not [string]::IsNullOrWhiteSpace($env:CLAUDE_CODE_EXECUTABLE)) {
        if (Test-Path -LiteralPath $env:CLAUDE_CODE_EXECUTABLE -PathType Leaf) {
            return New-ClaudeProcessCommand `
                -Path $env:CLAUDE_CODE_EXECUTABLE `
                -Source 'environment'
        }
    }

    $pathCommand = Get-Command claude -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandType -in @('Application', 'ExternalScript') } |
        Select-Object -First 1
    if ($null -ne $pathCommand) {
        return New-ClaudeProcessCommand `
            -Path $pathCommand.Source `
            -Source 'path'
    }

    $extensionRoots = @(
        (Join-Path $env:USERPROFILE '.vscode\extensions'),
        (Join-Path $env:USERPROFILE '.vscode-insiders\extensions')
    )

    $candidates = foreach ($extensionRoot in $extensionRoots) {
        if (-not (Test-Path -LiteralPath $extensionRoot -PathType Container)) {
            continue
        }

        Get-ChildItem -LiteralPath $extensionRoot -Directory `
            -ErrorAction SilentlyContinue |
            Where-Object {
                $_.Name -match
                    '^anthropic\.claude-code-(?<version>\d+\.\d+\.\d+)-'
            } |
            ForEach-Object {
                $binaryPath = Join-Path `
                    $_.FullName `
                    'resources\native-binary\claude.exe'
                if (Test-Path -LiteralPath $binaryPath -PathType Leaf) {
                    [pscustomobject]@{
                        Path = $binaryPath
                        Source = 'vscode-extension'
                        Version = [version]$Matches.version
                    }
                }
            }
    }

    $latestCandidate = $candidates |
        Sort-Object -Property Version -Descending |
        Select-Object -First 1
    if ($null -ne $latestCandidate) {
        return New-ClaudeProcessCommand `
            -Path $latestCandidate.Path `
            -Source $latestCandidate.Source
    }

    return $null
}

function ConvertTo-ProcessArgument {
    param([string]$Value)

    if ($Value.Length -eq 0) {
        return '""'
    }
    if ($Value -notmatch '[\s"]') {
        return $Value
    }
    return '"' + $Value.Replace('"', '\"') + '"'
}

function Get-ClaudeObservedModels {
    param($InputObject)

    if ($null -eq $InputObject) {
        return @()
    }

    $models = [System.Collections.Generic.List[string]]::new()
    $modelUsageProperty = $InputObject.PSObject.Properties['modelUsage']
    if ($null -ne $modelUsageProperty -and
        $null -ne $modelUsageProperty.Value) {
        foreach ($usageProperty in $modelUsageProperty.Value.PSObject.Properties) {
            $canonicalModel = $null
            if ($null -ne $usageProperty.Value) {
                $canonicalModelProperty =
                    $usageProperty.Value.PSObject.Properties['canonicalModel']
                if ($null -ne $canonicalModelProperty -and
                    -not [string]::IsNullOrWhiteSpace(
                        [string]$canonicalModelProperty.Value
                    )) {
                    $canonicalModel = [string]$canonicalModelProperty.Value
                }
            }

            if (-not [string]::IsNullOrWhiteSpace($canonicalModel)) {
                $models.Add($canonicalModel)
            }
            elseif (-not [string]::IsNullOrWhiteSpace($usageProperty.Name)) {
                $models.Add($usageProperty.Name)
            }
        }
    }

    if ($models.Count -eq 0) {
        $directModelProperty = $InputObject.PSObject.Properties['model']
        if ($null -ne $directModelProperty -and
            -not [string]::IsNullOrWhiteSpace(
                [string]$directModelProperty.Value
            )) {
            $models.Add([string]$directModelProperty.Value)
        }
    }

    return @($models | Select-Object -Unique)
}

function Test-ClaudeExpectedModelSet {
    param([string[]]$ObservedModels)

    if ($null -eq $ObservedModels -or $ObservedModels.Count -eq 0) {
        return $false
    }

    return @(
        $ObservedModels |
            Where-Object { $_ -ne $ExpectedCanonicalModel }
    ).Count -eq 0
}

function Test-ClaudeModelDetection {
    $expected = [pscustomobject]@{
        modelUsage = [pscustomobject]@{
            'claude-opus-5' = [pscustomobject]@{
                canonicalModel = 'claude-opus-5'
            }
        }
    }
    $unexpected = [pscustomobject]@{
        modelUsage = [pscustomobject]@{
            'claude-sonnet-5' = [pscustomobject]@{
                canonicalModel = 'claude-sonnet-5'
            }
        }
    }

    if (-not (Test-ClaudeExpectedModelSet -ObservedModels @(
        Get-ClaudeObservedModels -InputObject $expected
    ))) {
        throw 'Claude Opus 5 model detection self-test failed.'
    }
    if (Test-ClaudeExpectedModelSet -ObservedModels @(
        Get-ClaudeObservedModels -InputObject $unexpected
    )) {
        throw 'Unexpected Claude model rejection self-test failed.'
    }
    return 'passed'
}

function Test-ClaudeResultIsInvalidForNoTools {
    param($InputObject)

    if ($null -eq $InputObject) {
        return $true
    }

    $resultProperty = $InputObject.PSObject.Properties['result']
    if ($null -eq $resultProperty -or
        [string]::IsNullOrWhiteSpace([string]$resultProperty.Value)) {
        return $true
    }

    $result = [string]$resultProperty.Value
    return $result -match (
        '(?is)<function_calls>|<invoke>|' +
        '\A\s*Toolwindow\.[A-Za-z][A-Za-z0-9_.]*\s*(?:\r?\n|\{)'
    )
}

function Test-ClaudeNoToolsResultValidation {
    $toolCall = [pscustomobject]@{
        result = "Toolwindow.Read`n{`"file_path`":`"sample.txt`"}"
    }
    $normalProse = [pscustomobject]@{
        result = 'The functions.example text is normal prose.'
    }

    if (-not (Test-ClaudeResultIsInvalidForNoTools -InputObject $toolCall)) {
        throw 'NoTools tool-call detection self-test failed.'
    }
    if (Test-ClaudeResultIsInvalidForNoTools -InputObject $normalProse) {
        throw 'NoTools normal prose acceptance self-test failed.'
    }
    return 'passed'
}

function Find-ResetValue {
    param($InputObject)

    if ($null -eq $InputObject -or
        $InputObject -is [string] -or
        $InputObject -is [ValueType]) {
        return $null
    }

    if ($InputObject -is [System.Collections.IDictionary]) {
        foreach ($key in $InputObject.Keys) {
            $name = [string]$key
            $value = $InputObject[$key]
            if ($name -match
                '^(tokenResetTime|token_reset_time|resetTime|reset_time|resetAt|reset_at|resetsAt|resets_at|retryAfter|retry_after)$') {
                if ($null -ne $value -and
                    -not [string]::IsNullOrWhiteSpace([string]$value)) {
                    return [string]$value
                }
            }
            $nested = Find-ResetValue -InputObject $value
            if ($null -ne $nested) {
                return $nested
            }
        }
        return $null
    }

    if ($InputObject -is [System.Collections.IEnumerable]) {
        foreach ($item in $InputObject) {
            $nested = Find-ResetValue -InputObject $item
            if ($null -ne $nested) {
                return $nested
            }
        }
        return $null
    }

    foreach ($property in $InputObject.PSObject.Properties) {
        if ($property.Name -match
            '^(tokenResetTime|token_reset_time|resetTime|reset_time|resetAt|reset_at|resetsAt|resets_at|retryAfter|retry_after)$') {
            if ($null -ne $property.Value -and
                -not [string]::IsNullOrWhiteSpace(
                    [string]$property.Value
                )) {
                return [string]$property.Value
            }
        }
        $nested = Find-ResetValue -InputObject $property.Value
        if ($null -ne $nested) {
            return $nested
        }
    }
    return $null
}

function Find-ResetValueInText {
    param([string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return $null
    }

    $patterns = @(
        '(?i)"(?:tokenResetTime|token_reset_time|resetTime|reset_time|resetAt|reset_at|resetsAt|resets_at|retryAfter|retry_after)"\s*:\s*"(?<value>[^"]+)"',
        '(?im)\b(?:TokenResetTime|reset\s+time|resets?(?:\s+at)?|retry[-_ ]after)\b\s*[:=·-]?\s*(?<value>[^\r\n,;}"]+)'
    )
    foreach ($pattern in $patterns) {
        $match = [regex]::Match($Text, $pattern)
        if ($match.Success) {
            return $match.Groups['value'].Value.Trim()
        }
    }
    return $null
}

function Test-TokenLimitResponse {
    param([string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return $false
    }

    $pattern =
        '(?i)(token[_ -]?limit|usage[_ -]?limit|' +
        '(?:hit|reached) (?:your )?(?:(?:session|weekly|usage|rate|token)\s+)?limit|' +
        'exceeded.{0,40}limit|out of.{0,20}tokens)'
    return [regex]::IsMatch($Text, $pattern)
}

function ConvertTo-JstIfAbsolute {
    param([string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return $null
    }

    $hasDate = $Value -match
        '(?i)((?<!\d)\d{4}[-/]\d{1,2}[-/]\d{1,2}(?!\d)|\b\d{1,2}\s+[A-Za-z]{3,9}\s+\d{4}\b|\b[A-Za-z]{3,9}\s+\d{1,2},?\s+\d{4}\b)'
    $hasZone = $Value -match
        '(?i)(Z\b|[+-]\d{2}:?\d{2}\b|\bUTC\b|\bGMT\b)'
    if (-not $hasDate -or -not $hasZone) {
        return $null
    }

    $parsed = [DateTimeOffset]::MinValue
    if (-not [DateTimeOffset]::TryParse(
        $Value,
        [System.Globalization.CultureInfo]::InvariantCulture,
        [System.Globalization.DateTimeStyles]::AllowWhiteSpaces,
        [ref]$parsed
    )) {
        return $null
    }

    $jst = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId(
        $parsed,
        'Tokyo Standard Time'
    )
    return $jst.ToString('yyyy-MM-dd HH:mm:ss zzz')
}

function Test-TokenLimitParser {
    $absolute = '2026-07-25T15:00:00Z'
    $sessionLimit =
        '{"is_error":true,"api_error_status":429,"result":"You''ve hit your session limit · resets 2:20am (Asia/Tokyo)"}'
    $structured = [pscustomobject]@{
        error = [pscustomobject]@{
            tokenResetTime = $absolute
        }
    }

    if ((Find-ResetValue -InputObject $structured) -ne $absolute) {
        throw 'Structured TokenResetTime parser self-test failed.'
    }
    if ((Find-ResetValueInText -Text $sessionLimit) -ne
        '2:20am (Asia/Tokyo)') {
        throw 'Session-limit reset time parser self-test failed.'
    }
    if ((ConvertTo-JstIfAbsolute -Value $absolute) -ne
        '2026-07-26 00:00:00 +09:00') {
        throw 'TokenResetTime JST conversion self-test failed.'
    }
    if (-not (Test-TokenLimitResponse -Text $sessionLimit)) {
        throw 'Session-limit response classifier self-test failed.'
    }
    if (Test-TokenLimitResponse -Text (
        'The session limit configuration is documented.')) {
        throw 'Non-error session-limit text was misclassified.'
    }
    return 'passed'
}

function Get-ProcessTreeKillMethod {
    return [System.Diagnostics.Process].GetMethod(
        'Kill',
        [type[]]@([bool])
    )
}

function Test-ProcessTreeTerminationSupport {
    if ($null -ne (Get-ProcessTreeKillMethod)) {
        return 'passed'
    }
    if ($env:OS -eq 'Windows_NT' -and
        $null -ne (Get-Command taskkill.exe -ErrorAction SilentlyContinue)) {
        return 'passed'
    }
    throw 'Process-tree termination is not supported by this runtime.'
}

function Stop-ProcessTree {
    param(
        [Parameter(Mandatory = $true)]
        [System.Diagnostics.Process]$Process
    )

    if ($Process.HasExited) {
        return
    }

    $killTreeMethod = Get-ProcessTreeKillMethod
    if ($null -ne $killTreeMethod) {
        $null = $killTreeMethod.Invoke($Process, [object[]]@($true))
        return
    }

    if ($env:OS -eq 'Windows_NT') {
        $taskkill = Get-Command taskkill.exe -ErrorAction Stop
        & $taskkill.Source /PID $Process.Id /T /F 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0 -and -not $Process.HasExited) {
            throw "Failed to terminate process tree: PID $($Process.Id)"
        }
        return
    }

    throw 'Process-tree termination is not supported by this runtime.'
}

$resolvedClaude = Resolve-ClaudeExecutable
if ($null -eq $resolvedClaude) {
    Write-JsonResult -Value @{
        schema_version = 1
        status = 'not_found'
        message = 'Claude Code executable was not found.'
        observed_at_utc = [DateTimeOffset]::UtcNow.ToString('o')
    } -ExitCode 11
}

$versionArguments = @($resolvedClaude.ArgumentPrefix) + @('--version')
$versionOutput = (& $resolvedClaude.Path @versionArguments 2>&1 |
    Out-String).Trim()

if ($CheckOnly) {
    Write-JsonResult -Value @{
        schema_version = 1
        status = 'ready'
        model_requested = $RequestedModel
        executable_source = $resolvedClaude.Source
        executable_path = $resolvedClaude.Path
        claude_target_path = $resolvedClaude.TargetPath
        claude_code_version = $versionOutput
        token_limit_parser_self_test = Test-TokenLimitParser
        model_detection_self_test = Test-ClaudeModelDetection
        no_tools_result_self_test = Test-ClaudeNoToolsResultValidation
        process_tree_termination_self_test =
            Test-ProcessTreeTerminationSupport
        observed_at_utc = [DateTimeOffset]::UtcNow.ToString('o')
    }
}

$permissionMode = if ($AllowEdits) { 'acceptEdits' } else { 'plan' }
$delegationSystemPrompt = @"
You are Claude Opus 5 acting as a bounded specialist for Codex Sol.

Rules:
- Work only on the delegated task and scope.
- Do not create or invoke subagents, background agents, or parallel agents.
- Do not create or switch branches, commit, push, merge, rebase, reset, clean, tag, or perform GitHub operations.
- Follow AGENTS.md and CLAUDE.md, but these delegation rules take precedence for this invocation.
- Respond in Japanese.
- Report conclusion, evidence, proposed or completed changes, validation, and remaining risks.
- Codex Sol owns final integration and the user-facing decision.
"@

if ($NoTools) {
    $delegationSystemPrompt += @"

- No tools are available in this invocation.
- Do not emit tool calls, tool-call markup, or requests to inspect files.
- Answer only from the delegated task packet. If it lacks required evidence, say so.
"@
}

$systemPromptOption =
    if ($NoTools) { '--system-prompt' } else { '--append-system-prompt' }
$claudeArguments = @(
    '--print',
    '--model', $RequestedModel,
    $systemPromptOption, $delegationSystemPrompt,
    '--effort', $Effort,
    '--permission-mode', $permissionMode,
    '--max-turns',
    $MaxTurns.ToString([System.Globalization.CultureInfo]::InvariantCulture),
    '--output-format', 'json',
    '--no-session-persistence',
    '--name', 'codex-opus5-delegation',
    '--disallowedTools',
    'Agent',
    'Task',
    'Bash(git commit *)',
    'Bash(git push *)',
    'Bash(git add *)',
    'Bash(git rm *)',
    'Bash(git mv *)',
    'Bash(git merge *)',
    'Bash(git rebase *)',
    'Bash(git cherry-pick *)',
    'Bash(git revert *)',
    'Bash(git reset *)',
    'Bash(git restore *)',
    'Bash(git clean *)',
    'Bash(git stash *)',
    'Bash(git branch *)',
    'Bash(git tag *)',
    'Bash(git worktree *)',
    'Bash(git config *)',
    'Bash(git init *)',
    'Bash(git submodule *)',
    'Bash(git sparse-checkout *)',
    'Bash(git switch *)',
    'Bash(git checkout *)',
    'Bash(git fetch *)',
    'Bash(git pull *)',
    'Bash(gh *)'
)
if ($NoTools) {
    $claudeArguments += @('--tools', '')
}

$startInfo = [System.Diagnostics.ProcessStartInfo]::new()
$startInfo.FileName = $resolvedClaude.Path
$processArguments = @($resolvedClaude.ArgumentPrefix) + $claudeArguments
$startInfo.Arguments = ($processArguments | ForEach-Object {
    ConvertTo-ProcessArgument -Value $_
}) -join ' '
$startInfo.WorkingDirectory = (Get-Location).Path
$startInfo.UseShellExecute = $false
$startInfo.CreateNoWindow = $true
$startInfo.RedirectStandardInput = $true
$startInfo.RedirectStandardOutput = $true
$startInfo.RedirectStandardError = $true
$startInfo.StandardOutputEncoding = [System.Text.Encoding]::UTF8
$startInfo.StandardErrorEncoding = [System.Text.Encoding]::UTF8

$process = [System.Diagnostics.Process]::new()
$process.StartInfo = $startInfo
try {
    if (-not $process.Start()) {
        throw 'Claude Code process did not start.'
    }

    $stdoutTask = $process.StandardOutput.ReadToEndAsync()
    $stderrTask = $process.StandardError.ReadToEndAsync()
    $process.StandardInput.Write($Prompt)
    $process.StandardInput.Close()

    if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
        Stop-ProcessTree -Process $process
        $process.WaitForExit()
        Write-JsonResult -Value @{
            schema_version = 1
            status = 'timeout'
            model_requested = $RequestedModel
            permission_mode = $permissionMode
            timeout_seconds = $TimeoutSeconds
            stdout = $stdoutTask.GetAwaiter().GetResult()
            stderr = $stderrTask.GetAwaiter().GetResult()
            observed_at_utc = [DateTimeOffset]::UtcNow.ToString('o')
        } -ExitCode 12
    }

    $stdout = $stdoutTask.GetAwaiter().GetResult()
    $stderr = $stderrTask.GetAwaiter().GetResult()
    $exitCode = $process.ExitCode
}
catch {
    Write-JsonResult -Value @{
        schema_version = 1
        status = 'error'
        model_requested = $RequestedModel
        permission_mode = $permissionMode
        message = $_.Exception.Message
        observed_at_utc = [DateTimeOffset]::UtcNow.ToString('o')
    } -ExitCode 1
}
finally {
    $process.Dispose()
}

$parsedOutput = $null
if (-not [string]::IsNullOrWhiteSpace($stdout)) {
    try {
        $parsedOutput = $stdout | ConvertFrom-Json
    }
    catch {
        $parsedOutput = $null
    }
}

$combinedOutput = ($stdout + [Environment]::NewLine + $stderr).Trim()
$observedModels = @(Get-ClaudeObservedModels -InputObject $parsedOutput)
$modelVerified =
    Test-ClaudeExpectedModelSet -ObservedModels $observedModels
$isStructuredError = $null -ne $parsedOutput -and
    $null -ne $parsedOutput.PSObject.Properties['is_error'] -and
    [bool]$parsedOutput.is_error
$isTokenLimit = ($exitCode -ne 0 -or $isStructuredError) -and
    (Test-TokenLimitResponse -Text $combinedOutput)

$resetValue = Find-ResetValue -InputObject $parsedOutput
if ($null -eq $resetValue) {
    $resetValue = Find-ResetValueInText -Text $combinedOutput
}
$resetValueJst = ConvertTo-JstIfAbsolute -Value $resetValue

if ($isTokenLimit) {
    Write-JsonResult -Value @{
        schema_version = 1
        status = 'token_limit'
        model_requested = $RequestedModel
        model_observed = $observedModels
        model_verified = $modelVerified
        permission_mode = $permissionMode
        token_reset_time = $resetValue
        token_reset_time_jst = $resetValueJst
        claude = $parsedOutput
        stdout = if ($null -eq $parsedOutput) { $stdout } else { $null }
        stderr = $stderr
        observed_at_utc = [DateTimeOffset]::UtcNow.ToString('o')
    } -ExitCode 10
}

if ($exitCode -ne 0 -or $isStructuredError) {
    Write-JsonResult -Value @{
        schema_version = 1
        status = 'error'
        model_requested = $RequestedModel
        model_observed = $observedModels
        model_verified = $modelVerified
        permission_mode = $permissionMode
        exit_code = $exitCode
        claude = $parsedOutput
        stdout = if ($null -eq $parsedOutput) { $stdout } else { $null }
        stderr = $stderr
        observed_at_utc = [DateTimeOffset]::UtcNow.ToString('o')
    } -ExitCode 1
}

if (-not $modelVerified) {
    Write-JsonResult -Value @{
        schema_version = 1
        status = 'error'
        model_requested = $RequestedModel
        model_observed = $observedModels
        model_verified = $false
        permission_mode = $permissionMode
        message =
            'Claude Opus 5 could not be verified from the response metadata.'
        claude = $parsedOutput
        stdout = if ($null -eq $parsedOutput) { $stdout } else { $null }
        stderr = $stderr
        observed_at_utc = [DateTimeOffset]::UtcNow.ToString('o')
    } -ExitCode 13
}

if ($NoTools -and
    (Test-ClaudeResultIsInvalidForNoTools -InputObject $parsedOutput)) {
    Write-JsonResult -Value @{
        schema_version = 1
        status = 'error'
        model_requested = $RequestedModel
        model_observed = $observedModels
        model_verified = $true
        permission_mode = $permissionMode
        message =
            'Claude returned a tool call or no final answer in -NoTools mode.'
        claude = $parsedOutput
        stdout = if ($null -eq $parsedOutput) { $stdout } else { $null }
        stderr = $stderr
        observed_at_utc = [DateTimeOffset]::UtcNow.ToString('o')
    } -ExitCode 14
}

Write-JsonResult -Value @{
    schema_version = 1
    status = 'success'
    model_requested = $RequestedModel
    model_observed = $observedModels
    model_verified = $true
    permission_mode = $permissionMode
    claude_code_version = $versionOutput
    claude = $parsedOutput
    stdout = if ($null -eq $parsedOutput) { $stdout } else { $null }
    stderr = $stderr
    observed_at_utc = [DateTimeOffset]::UtcNow.ToString('o')
}
