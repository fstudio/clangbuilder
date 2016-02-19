using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Diagnostics;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Navigation;
using System.Windows.Shapes;
using MahApps.Metro.Controls;
using MahApps.Metro.Controls.Dialogs;
using Microsoft.Win32;
using System.Configuration;
using System.Collections.ObjectModel;
using System.Reflection;

namespace ClangbuilderUI
{
    /// <summary>
    /// MainWindow.xaml 的交互逻辑
    /// </summary>
    ///     public partial class MainWindow :MetroWindow
    public partial class MainWindow : MetroWindow
    {
        public MainWindow()
        {
            InitializeComponent();

            if (Environment.GetEnvironmentVariable("VS110COMNTOOLS") != null)
            {
                VS110.IsSelected = true;
            }
            else
            {
                VS110.IsEnabled = false;
            }
            if (Environment.GetEnvironmentVariable("VS120COMNTOOLS") != null)
            {
                VS120.IsSelected = true;
            }
            else
            {
                VS120.IsEnabled = false;
            }
            if (Environment.GetEnvironmentVariable("VS140COMNTOOLS") != null)
            {
                String subKey = @"SOFTWARE\Microsoft\Windows NT\CurrentVersion";
                RegistryKey key = Registry.LocalMachine;
                RegistryKey skey = key.OpenSubKey(subKey);
                if (skey.GetValue("CurrentMajorVersionNumber") != null&&(int)skey.GetValue("CurrentMajorVersionNumber")>=10)
                {
                    VS141.IsSelected = true;
                }
                else
                {
                    VS140.IsSelected = true;
                }
            }
            else
            {
                VS140.IsEnabled = false;
                VS141.IsEnabled = false;
            }

            if (Environment.GetEnvironmentVariable("VS150COMNTOOLS") != null)
            {
                VS150.IsSelected = true;
            }
            else
            {
                VS150.IsEnabled = false;
            }

            if (VS141.IsSelected)
            {
                archARM64.IsEnabled = true;
            }
            else
            {
                archARM64.IsEnabled = false;
            }

            if (System.Environment.Is64BitOperatingSystem)
            {
                archX64.IsSelected = true;
            }
            else
            {
                archX86.IsSelected = false;
            }
        }

        private async void ClangbuilderSettingsFeature(object sender, RoutedEventArgs e)
        {
            MetroDialogOptions.ColorScheme = MetroDialogColorScheme.Theme;

            var mySettings = new MetroDialogSettings()
            {
                AffirmativeButtonText = "OK",
                NegativeButtonText = "Visit Home",
                FirstAuxiliaryButtonText = "Cancel",
                ColorScheme = MetroDialogColorScheme.Theme
            };

            MessageDialogResult result = await this.ShowMessageAsync("Clangbuilder UI Setting",
                "Welcome to use the Clangbuilder Environment Configuration tool.\nCopyright \xA9 2016 ForceStudio All Rights Reserved. ",
                MessageDialogStyle.AffirmativeAndNegativeAndSingleAuxiliary, mySettings);

            if (result == MessageDialogResult.Negative)
            {
                System.Diagnostics.Process.Start("http://forcemz.net");
            }
        }
        private bool StartupLauncher(String Args)
        {
            String launcher = Process.GetCurrentProcess().MainModule.FileName;
            launcher = System.IO.Path.GetDirectoryName(launcher);
            launcher += "\\launcher.exe";
            if (!System.IO.File.Exists(launcher))
            {
                this.ShowMessageAsync("Not Found Launcher.exe In this Path:", launcher);
                //this.ShowMessageAsync(Args, launcher);
                return false;
            }
            ProcessStartInfo psInfo = new ProcessStartInfo();
            psInfo.FileName = launcher;
            psInfo.Arguments = Args;
            Process.Start(psInfo);
            return true;
        }
        private String ArgumentsBuilder(object sender, RoutedEventArgs e, bool IsBuilder)
        {
            String[] stringVs = { "110", "120", "140", "141", "150" };
            String[] stringArch = { "x86", "x64", "ARM", "ARM64" };
            String[] stringFlavor = { "Release", "MinSizeRel", "RelWithDebInfo", "Debug" };
            if (visualstudioVersion.SelectedIndex == -1 || arch.SelectedIndex == -1 || flavor.SelectedIndex == -1)
            {
                this.ShowMessageAsync("Cannot Continue !",
                    "VisualStudio ,Arch and Flavor Must be selected !");
                return null;
            }
            String Args = "--vs " + stringVs[visualstudioVersion.SelectedIndex] + " --arch " + stringArch[arch.SelectedIndex];
            if (IsBuilder)
            {
                Args += " --flavor " + stringFlavor[flavor.SelectedIndex];
                if(IsClangBootstrap.IsChecked==true){
                    Args += " --bootstrap";
                }
                if (IsCreateInstallPackage.IsChecked == true)
                {
                    Args += " --install";
                }
                if (IsEnabledStaticRuntime.IsChecked == true)
                {
                    Args += " --static";
                }
                if (IsUseNMakeBuilder.IsChecked == true)
                {
                    Args += " --nmake";
                }
                if (IsBuildReleasedRevision.IsChecked == true)
                {
                    Args += " --released";
                }
                if (IsBuidLLDB.IsChecked == true)
                {
                    Args += " --lldb";
                }

            }else{
                Args+=" --env";
            }
            if (IsCleanEnvironment.IsChecked == true)
            {
                Args += " --clear";
            }
            return Args;
        }
        private void OnBuildingNow(object sender, RoutedEventArgs e)
        {
            String args = ArgumentsBuilder(sender, e, true);
            if (args != null)
            {
                StartupLauncher(args);
            }
        }

        private void OnStartupEnvironment(object sender, RoutedEventArgs e)
        {
            String args = ArgumentsBuilder(sender, e, false);
            if (args != null)
            {
                StartupLauncher(args);
            }
        }

        private void VisualStudioSelectChanged(object sender, SelectionChangedEventArgs e)
        {
            if (visualstudioVersion.SelectedIndex > 2)
            {
                archARM64.IsEnabled = true;
            }
            else
            {
                archARM64.IsEnabled = false;
            }
        }
    }
}
