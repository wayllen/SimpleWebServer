# Create and Start http listener.
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add('http://localhost:8000/') 

$listener.Start()
'Listening ...'
while ($true) {
    $context = $listener.GetContext() # blocks until request is received
    $request = $context.Request
    $response = $context.Response
    
    # Equivalent to 'routes' in other frameworks
  if (($request.Url -match '/storage') -and ($request.HttpMethod -eq 'POST')) { # response to http://myServer:8000/ POST method.
    $response.ContentType = 'text/plain'
    Write-Host "POST ...."
    $message = 'Handling the POST request...'
        
    #Read the POST data.    
    $output = ""
    $size = $request.ContentLength64 + 1
    Write-Host "Receiving up to $size"
    $buffer = New-Object byte[] $size
    do {
         $count = $request.InputStream.Read($buffer, 0, $size)
         Write-Host "Received $count"
         $output += $request.ContentEncoding.GetString($buffer, 0, $count)
       } until($count -lt $size)

   
    Write-Host "The Received Data = $output"
    
    #Parse the DATA.
    $parameterLists = $output -split "&" 
    $key = @()
    $value = @()
    for($i=0; $i -lt $parameterLists.Length; $i++)
    {
      $key   = $parameterLists[$i].split("=")[0]
      $value = $parameterLists[$i].split("=")[1]
      if($key -eq 'vmTemplateName')
      {
        $vmTemplateName = $value
      }
      if($key -eq 'vmHostName')
      {
        $vmHostName  = $value
      }
      if($key -eq 'vmDSName')
      {
        $vmDSName  = $value
      }
      if($key -eq 'DCFlag')
      {
        $dcFlag  = $value
      }
      if($key -eq 'vmIP')
      {
        $vmIP  = $value
      }
      if($key -eq 'vmName')
      {
        $vmName  = $value
      }
                                     
    }
     Write-Host $vmTemplateName, $vmHostName, $vmDSName, $dcFlag, $vmIP, $vmName
     
     #Invoke the powercli interface to create VM according to the above parameters.
     
    #Write-Host $key
    #Write-Host $value
   
    $request.InputStream.Close()
    #ConvertFrom-Json $output
        
  }# response to http://myServer:8000/ POST method.
    
    if ($request.Url -match '/date/xml$') { # response to http://myServer:8000/date/xml
        $response.ContentType = 'text/xml'
        $hour = [System.DateTime]::Now.Hour
        $minute = [System.DateTime]::Now.Minute
        $message = "<?xml version=""1.0""?><Time><Hour>$hour</Hour><Minute>$minute</Minute></Time>"
    }

    if ($request.Url -match '/date/json$') { # response to http://myServer:8000/date/json
        $response.ContentType = 'application/json'
        $time = '' | select hour, minute
        $time.hour = [System.DateTime]::Now.Hour
        $time.minute = [System.DateTime]::Now.Minute
        $message = $time | ConvertTo-Json
    }
    
    # This will terminate the script. Remove from production!
    if ($request.Url -match '/end$') { break }

    #Send the response to web client.
    [byte[]] $buffer = [System.Text.Encoding]::UTF8.GetBytes($message)
    $response.ContentLength64 = $buffer.length
    $output = $response.OutputStream
    $output.Write($buffer, 0, $buffer.length)
    $output.Close()
    
}

$listener.Stop()
