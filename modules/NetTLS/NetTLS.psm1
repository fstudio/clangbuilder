

## https://githubengineering.com/crypto-removal-notice/
Function InitializeTLS{
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}