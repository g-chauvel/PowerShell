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
        Select-String -Path $tempFile -Pattern "stdout" | Should -BeNullOrEmpty
        Select-String -Path $tempFile -Pattern "stderr" | Should -Not -BeNullOrEmpty
    }

    It "Should handle stdout redirection without error" {
        $process = Start-Process $PWSH -ArgumentList $pwshParam -Wait -PassThru -RedirectStandardError $tempFile
        Select-String -Path $tempFile -Pattern "stdout" | Should -BeNullOrEmpty
        Select-String -Path $tempFile -Pattern "stderr" | Should -Not -BeNullOrEmpty
    }

    It "Should handle stdout,stderr redirections without error" {
        $process = Start-Process $PWSH -ArgumentList $pwshParam -Wait -PassThru -RedirectStandardError $tempFile -RedirectStandardOutput "$TESTDRIVE/output"
        Select-String -Path $tempFile -Pattern "stdout" | Should -BeNullOrEmpty
        Select-String -Path $tempFile -Pattern "stderr" | Should -Not -BeNullOrEmpty
        Select-String -Path "$TESTDRIVE/output" -Pattern "stdout" | Should -Not -BeNullOrEmpty
        Select-String -Path "$TESTDRIVE/output" -Pattern "stderr" | Should -BeNullOrEmpty
    }

    It "Should handle stdout,stderr redirections to the same file without error" {
        $process = Start-Process $PWSH -ArgumentList $pwshParam -Wait -PassThru -RedirectStandardError $tempFile -RedirectStandardOutput $tempFile
        Select-String -Path $tempFile -Pattern "stdout" | Should -Not -BeNullOrEmpty
        Select-String -Path $tempFile -Pattern "stderr" | Should -Not -BeNullOrEmpty
    }

}

