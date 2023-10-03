# Define the Region(s) to match
$regionList = "eastus","southcentralus"

# Define the Service(s) to match
$serviceList = "AzureStorage","AzureKeyVault"

# Define the URL of the web page that contains the link to the JSON file
$url = "https://www.microsoft.com/en-us/download/confirmation.aspx?id=56519"

# Define if resulting ipList should include only IPv4 Addresses (use boolean $true or $false)
$ipv4Only = $true

# Setup the IP address variable as an Array List
$ipList = [System.Collections.ArrayList]@()

# Use Invoke-WebRequest to get the web page content
$page = Invoke-WebRequest -Uri $url

# Use a regular expression to find the link to the JSON file from the page content
$urlRegex = 'https://download\.microsoft\.com/download/[^"]+/ServiceTags_Public_[^"]+\.json'
$page.Content -match $urlRegex | Out-Null

# Use the $matches variable to get the link to the JSON file
$link = $matches[0]
#Write-Host "IP Ranges File URL: $link"

# Use Invoke-WebRequest to load the JSON file
$json = Invoke-WebRequest -Uri $link

# Convert the JSON file to a PowerShell object
$azureIPs = $json | ConvertFrom-Json

# Iterate over the regions
foreach ($region in $regionList) {
  
  #Iterate over the services
  foreach ($service in $serviceList) {
    $matchedIPs = $azureIPs.Values | Where-Object {$_.properties.region -eq $region -and $_.properties.systemService -eq $service} | Select-Object -ExpandProperty $_.properties.addressPrefixes

    # Filter returned Addresses to only return IPv4 addresses if $ipv4Only is set to True
    if ($ipv4Only) {
      $ipRegex = "^((([0-9]|[1-9][0-9]|1[0-9]{2}|[1-2][0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|[1-2][0-4][0-9]|25[0-5]))((/[0-9]|/[1-2][0-9]|/[1-3][0-2])?)$"
      foreach ($ip in $matchedIPs.properties.addressPrefixes) {
        if ($ip -match $ipRegex) {
          $null = $ipList.Add($ip)
        }
      }
    }
    else {
      foreach ($ip in $matchedIPs.properties.addressPrefixes) {
        $null = $ipList.Add($ip)
      }
    }
  }
}

#De-dupliate and sort list of IPs
$ipList = $ipList | Sort-Object -Unique


$ipList
