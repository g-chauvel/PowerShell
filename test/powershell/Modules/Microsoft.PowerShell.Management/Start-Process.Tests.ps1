# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

Describe "Start-Process" -Tag "Feature","RequireAdminOnWindows" {

    BeforeAll {
        $isNanoServer = [System.Management.Automation.Platform]::IsNanoServer
        $isIot = [System.Management.Automation.Platform]::IsIoT
        $isFullWin = $IsWindows -and !$isNanoServer -and !$isIot
        $extraArgs = @{}
        if ($isFullWin) {
            $extraArgs.WindowStyle = "Hidden"
        }

        $pingCommand = (Get-Command -CommandType Application ping)[0].Definition
        $pingDirectory = Split-Path $pingCommand -Parent
        $tempFile = Join-Path -Path $TestDrive -ChildPath PSTest
        $tempDirectory = Join-Path -Path $TestDrive -ChildPath 'PSPath[]'
        New-Item $tempDirectory -ItemType Directory  -Force
        $assetsFile = Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath assets) -ChildPath SortTest.txt
        $PWSH = (Get-Process -Id $PID).MainModule.FileName
        $pwshParam = "-NoProfile -Command &{ Write-Output 'stdout'; Write-Error 'stderr' }"
        if ($IsWindows) {
            $pingParam = "-n 2 localhost"
        }
        elseif ($IsLinux -Or $IsMacOS) {
            $pingParam = "-c 2 localhost"
        }
    }

    # Note that ProcessName may still be `powershell` due to dotnet/corefx#5378
    # This has been fixed on Linux, but not on macOS

    It "Should handle stderr redirection without error" {
        $process = Start-Process $PWSH -ArgumentList $pwshParam -Wait -PassThru -RedirectStandardError $tempFile

        $redirectFile = Get-Content -Path $tempFile

        $redirectFile | Select-String -Pattern "stdout" | Should -BeNullOrEmpty
        $redirectFile | Select-String -Pattern "stderr" | Should -Not -BeNullOrEmpty
    }

    It "Should handle stdout redirection without error" {
        $process = Start-Process $PWSH -ArgumentList $pwshParam -Wait -PassThru -RedirectStandardError $tempFile

        $redirectFile = Get-Content -Path $tempFile

        $redirectFile | Select-String -Pattern "stdout" | Should -BeNullOrEmpty
        $redirectFile | Select-String -Pattern "stderr" | Should -Not -BeNullOrEmpty
    }

    It "Should handle stdout,stderr redirections without error" {
        $process = Start-Process $PWSH -ArgumentList $pwshParam -Wait -PassThru -RedirectStandardError $tempFile -RedirectStandardOutput "$TESTDRIVE/output"

        $redirectStdoutFile = Get-Content -Path "$TESTDRIVE/output"
        $redirectStderrFile = Get-Content -Path $tempFile

        $redirectStderrFile | Select-String -Pattern "stdout" | Should -BeNullOrEmpty
        $redirectStderrFile | Select-String -Pattern "stderr" | Should -Not -BeNullOrEmpty
        $redirectStdoutFile | Select-String -Pattern "stdout" | Should -Not -BeNullOrEmpty
        $redirectStdoutFile | Select-String -Pattern "stderr" | Should -BeNullOrEmpty
    }

    It "Should handle stdout,stderr redirections to the same file without error" {
        $process = Start-Process $PWSH -ArgumentList $pwshParam -Wait -PassThru -RedirectStandardError $tempFile -RedirectStandardOutput $tempFile

        $redirectFile = Get-Content -Path $tempFile

        $redirectFile | Select-String -Pattern "stdout" | Should -Not -BeNullOrEmpty
        $redirectFile | Select-String -Pattern "stderr" | Should -Not -BeNullOrEmpty
    }

}

