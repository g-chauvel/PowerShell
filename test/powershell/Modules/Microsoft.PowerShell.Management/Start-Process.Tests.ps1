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
        $pwshParam = "-NoProfile -Command &{ [Console]::Out.WriteLine('stdout'); [Console]::Error.WriteLine('stderr') }"
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
        $output = & $PWSH -NoProfile -Command "&{ Start-Process $PWSH -ArgumentList `"$pwshParam`" -Wait -NoNewWindow -RedirectStandardError $tempFile }"
        $output | Should -BeExactly "stdout"
        Get-Content -Path $tempFile | Should -BeExactly "stderr"
    }

    It "Should handle stdout redirection without error" {
        $output = & $PWSH -NoProfile -Command "&{ Start-Process $PWSH -ArgumentList `"$pwshParam`" -Wait -NoNewWindow -RedirectStandardOutput $tempFile }" 2>&1
        $output | Should -BeExactly "stderr"
        Get-Content -Path $tempFile | Should -BeExactly "stdout"
    }

    It "Should handle stdout,stderr redirections without error" {
        Start-Process $PWSH -ArgumentList $pwshParam -Wait -RedirectStandardError $tempFile -RedirectStandardOutput "$TESTDRIVE/output"
        Get-Content -Path "$TESTDRIVE/output" | Should -BeExactly "stdout"
        Get-Content -Path $tempFile | Should -BeExactly "stderr"
    }

    It "Should handle stdout,stderr redirections to the same file without error" {
        Start-Process $PWSH -ArgumentList $pwshParam -Wait -RedirectStandardError $tempFile -RedirectStandardOutput $tempFile
        Get-Content -Path $tempFile | Should -BeExactly @('stdout', 'stderr')
    }

}

Describe "Bug fixes" -Tags "CI" {

    ## https://github.com/PowerShell/PowerShell/issues/24986
    It "Error redirection along with '-NoNewWindow' should work for Start-Process" -Skip:(!$IsWindows) {
        $errorFile = Join-Path -Path $TestDrive -ChildPath error.txt
        $out = pwsh -noprofile -c "Start-Process -Wait -NoNewWindow -RedirectStandardError $errorFile -FilePath cmd -ArgumentList '/C echo Hello'"

        ## 'Hello' should be sent to standard output; 'error.txt' file should be created but empty.
        $out | Should -BeExactly "Hello"
        Test-Path -Path $errorFile | Should -BeTrue
        (Get-Item $errorFile).Length | Should -Be 0
    }
}
