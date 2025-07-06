param(
    [Parameter(Mandatory=$false, Position=0)][int]$Port = 12101,
    [Parameter(Mandatory=$false, Position=0)][int]$ReadInterval = 50,
    [Parameter(Mandatory=$false, Position=1)][string]$Mode = 'jsonl'
)

function Mode-Jsonl {
    param(
        [int]$Port,
        [int]$ReadInterval
    )
    $listenerEndPoint = New-Object IPEndpoint([System.Net.IPAddress]::Any, $Port)
    $tcpListener = New-Object System.Net.Sockets.TCPListener($listenerEndpoint)
    $client = $null
    $clientStream = $null
    $reader = $null
    $task = $null
    $entity = $null
    $prevEntity = $null

    try {
        $tcpListener.Start()
        while ($true) {
            # Wait for client connection.
            if ($null -eq $client) {
                if ($null -eq $task) {
                    $task = $tcpListener.AccepttcpClientAsync()
                }
                if (-not $task.Wait(200)) {
                    continue
                }

                $client = $task.GetAwaiter().GetResult();
                $clientStream = $client.GetStream()
                $reader = New-Object System.IO.StreamReader($clientStream)
                $task = $null
            }
            if ($reader.EndOfStream) {
                $reader.Close()
                $clientStream.Close()
                $client.Close()
                $task = $null
                $reader = $null
                $clientStream = $null
                $client = $null
                $entity = $null
                $prevEntity = $null
                continue
            }

            # Waiting to receive data.
            try {
                if ($null -eq $task) {
                    $task = $reader.ReadLineAsync()
                }

                if (-not $task.Wait($ReadInterval)) {
                    continue
                }
                $entity = $task.GetAwaiter().GetResult();
                $task = $null
            }
            catch {
                Write-Host "error: $($_.Exception.Message)"
                $reader.Close()
                $clientStream.Close()
                $client.Close()
                $reader = $null
                $ClientStream = $null
                $client = $null
            }

            if ($null -ne $entity) {
                if ("" -eq $entity) {
                    if ("" -eq $prevEntity) {
                        Write-Host 'reset'
                    }
                } else {
                    try {
                        $entity | ConvertFrom-Json | Write-Host
                    }
                    catch {
                        Write-Host "error payload: ${entity}"
                    }
                }
            }

            $prevEntity = $entity
            $entity = $null
        }
    }
    catch {
        Write-Host "error: $($_.Exception.Message)"
    }
    finally {
        if ($client) {
            $reader.Close()
            $clientStream.Close()
            $client.Close()
        }
        $tcpListener.Stop()
    }
}

function Mode-Raw {
    param(
        [string]$Port,
        [int]$ReadInterval
    )
    $listenerEndPoint = New-Object IPEndpoint([System.Net.IPAddress]::Any, $Port)
    $tcpListener = New-Object System.Net.Sockets.TCPListener($listenerEndpoint)
    $client = $null
    $clientStream = $null
    $reader = $null
    $task = $null
    $prevEntity = $null

    try {
        $tcpListener.Start()
        while ($true) {
            # Wait for client connection.
            if ($null -eq $client) {
                if ($null -eq $task) {
                    $task = $tcpListener.AcceptTcpClientAsync()
                }
                if (-not $task.Wait(200)) {
                    continue
                }

                $client = $task.GetAwaiter().GetResult();
                $clientStream = $client.GetStream()
                $reader = New-Object System.IO.StreamReader($clientStream)
                $task = $null
            }
            if ($reader.EndOfStream) {
                $reader.Close()
                $clientStream.Close()
                $client.Close()
                $task = $null
                $reader = $null
                $clientStream = $null
                $client = $null
                $entity = $null
                $prevEntity = $null
                continue
            }

            # Waiting to receive data.
            try {
                if ($null -eq $task) {
                    $task = $reader.ReadLineAsync()
                }

                if (-not $task.Wait($ReadInterval)) {
                    continue
                }
                $entity = $task.GetAwaiter().GetResult();
                $task = $null
            }
            catch {
                Write-Host "error: $($_.Exception.Message)"
                $reader.Close()
                $clientStream.Close()
                $client.Close()
                $reader = $null
                $ClientStream = $null
                $client = $null
            }

            if ($null -ne $entity) {
                if ("" -eq $entity) {
                    if ("" -eq $prevEntity) {
                        Write-Host 'reset'
                    }
                } else {
                    $entity | Write-Host
                }
            }

            $prevEntity = $entity
            $entity = $null
        }
    }
    catch {
        Write-Host "error: $($_.Exception.Message)"
    }
    finally {
        if ($client) {
            $reader.Close()
            $clientStream.Close()
            $client.Close()
        }
        $tcpListener.Stop()
    }
}

switch ( $Mode )
{
    Jsonl { Mode-Jsonl -Port $Port -ReadInterval $ReadInterval }
    Raw   { Mode-Raw -Port $Port -ReadInterval $ReadInterval }
}
