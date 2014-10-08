
Function Usage-Show
{
  Write-Host -ForegroundColor Cyan "PSCompiler Ulits
  Usage:PSCompiler -sc .\psscript.ps1"
  [System.Console]::ReadKey()
}


Function Convert-PS1ToExe
{
    param(
    [Parameter(Mandatory=$true)]
    [ValidateScript({$true})]
    [ValidateNotNullOrEmpty()]   
    [IO.FileInfo]$ScriptFile
    )
    if( -not $ScriptFile.Exists)
    {
        Write-Warning "$ScriptFile not exits."
        return
    }
 
    [string]$csharpCode = @'
    using System;
    using System.IO;
    using System.Reflection;
    using System.Diagnostics;
    namespace LoadXmlTestConsole
    {
        public class ConsoleWriter
        {
            private static void Proc_OutputDataReceived(object sender, System.Diagnostics.DataReceivedEventArgs e)
            {
                Process pro = sender as Process;
                Console.WriteLine(e.Data);
            }
            static void Main(string[] args)
            {
                // Set title of console
                Console.Title = "PSCompiler";
 
                // read script from resource
                Assembly ase = Assembly.GetExecutingAssembly();
                string scriptName = ase.GetManifestResourceNames()[0];
                string scriptContent = string.Empty;
                using (Stream stream = ase.GetManifestResourceStream(scriptName))
                using (StreamReader reader = new StreamReader(stream))
                {
                    scriptContent = reader.ReadToEnd();
                }
 
                string scriptFile = Environment.ExpandEnvironmentVariables(string.Format("%temp%\\{0}", scriptName));
                try
                {
                    // output script file to temp path
                    File.WriteAllText(scriptFile, scriptContent);
 
                    ProcessStartInfo proInfo = new ProcessStartInfo();
                    proInfo.FileName = "PowerShell.exe";
                    proInfo.CreateNoWindow = true;
                    proInfo.RedirectStandardOutput = true;
                    proInfo.UseShellExecute = false;
                    proInfo.Arguments = string.Format(" -File {0}",scriptFile);
 
                    var proc = Process.Start(proInfo);
                    proc.OutputDataReceived += Proc_OutputDataReceived;
                    proc.BeginOutputReadLine();
                    proc.WaitForExit();
                    Console.WriteLine("Hit any key to continue...");
                    Console.ReadKey();
                }
                catch (Exception ex)
                {
                    Console.WriteLine("Hit Exception: {0}", ex.Message);
                }
                finally
                {
                    // delete temp file
                    if (File.Exists(scriptFile))
                    {
                        File.Delete(scriptFile);
                    }
                }
 
            }
 
        }
    }
'@
 
    # $providerDict
    $providerDict = New-Object 'System.Collections.Generic.Dictionary[[string],[string]]'
    $providerDict.Add('CompilerVersion','v4.0')
    $codeCompiler = [Microsoft.CSharp.CSharpCodeProvider]$providerDict
 
    # Create the optional compiler parameters
    $compilerParameters = New-Object 'System.CodeDom.Compiler.CompilerParameters'
    $compilerParameters.GenerateExecutable = $true
    $compilerParameters.GenerateInMemory = $true
    $compilerParameters.WarningLevel = 3
    $compilerParameters.TreatWarningsAsErrors = $false
    $compilerParameters.CompilerOptions = '/optimize'
    $outputExe = Join-Path $ScriptFile.Directory "$($ScriptFile.BaseName).exe"
    $compilerParameters.OutputAssembly =  $outputExe
    $compilerParameters.EmbeddedResources.Add($ScriptFile.FullName) > $null
    $compilerParameters.ReferencedAssemblies.Add( [System.Diagnostics.Process].Assembly.Location ) > $null
 
    # Compile Assembly
    $compilerResult = $codeCompiler.CompileAssemblyFromSource($compilerParameters,$csharpCode)
 
    # Print compiler errors
    if($compilerResult.Errors.HasErrors)
    {
        Write-Host 'Compile faield. See error message as below:' -ForegroundColor Red
        $compilerResult.Errors | foreach {
            Write-Warning ('{0},[{1},{2}],{3}' -f $_.ErrorNumber,$_.Line,$_.Column,$_.ErrorText )
        }
    }
    else
    {
         Write-Host 'Compile succeed.' -ForegroundColor Green
         "Output executable file to '$outputExe'"
    }
}

IF($args.Count -eq 2)
{
 
 IF([System.String]::Compare($args[0],"-sc",$True) -eq 0)
 {
 Convert-PS1ToExe -ScriptFile $args[1]
 }ELSE{
 Usage-Show
 }
}ELSE{
Usage-Show
}