Describe 'Port-scanner equivalence' {
    $testCases = @(
        @{ Host='127.0.0.1'; Start=22; End=22; Timeout=200; Concurrency=10; Expected=@(22) }
        @{ Host='127.0.0.1'; Start=80; End=80; Timeout=200; Concurrency=10; Expected=@() }
        @{ Host='127.0.0.1'; Start=1; End=1024; Timeout=200; Concurrency=20; Expected=@(22) }
        @{ Host='127.0.0.1'; Start=1; End=65535; Timeout=200; Concurrency=100; Expected=@(22) }
        @{ Host='example.com'; Start=80; End=80; Timeout=200; Concurrency=5; Expected=@(80) }
        @{ Host='example.com'; Start=443; End=443; Timeout=200; Concurrency=5; Expected=@(443) }
        @{ Host='example.com'; Start=1; End=1024; Timeout=200; Concurrency=10; Expected=@(80,443) }
    )
    
    foreach ($case in $testCases) {
        $Name = "Scan $($case.Host) $($case.Start)-$($case.End)"
        It $Name {
            $pyOutput = & python `
                "${PSScriptRoot}\..\get-openports.py" `
                --target $case.Host `
                --start-port $case.Start `
                --end-port $case.End `
                --timeout $case.Timeout `
                --concurrency $case.Concurrency `
                --json
            $psOutput = & pwsh -NoLogo -NoProfile -Command `
                "${PSScriptRoot}\..\get-openports.ps1" `
                -Target $case.Host `
                -StartPort $case.Start `
                -EndPort $case.End `
                -Timeout $case.Timeout `
                -ThrottleLimit $case.Concurrency `
                -Json

            $pyPorts = $pyOutput | ConvertFrom-Json
            $psPorts = $psOutput | ConvertFrom-Json

            ($pyPorts | Sort-Object) | Should -Be ($case.Expected | Sort-Object)
            ($psPorts | Sort-Object) | Should -Be ($case.Expected | Sort-Object)
        }
    }
}