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
    //public class ClangbuilderUIItem
    //{
    //    public string Content { set; get; }
    //    public string Value { set; get; }
    //    public int ID { set; get; }
    //}
    //public class ClangbuilderUICombobox : ObservableCollection<ClangbuilderUIItem>
    //{
    //    public ClangbuilderUICombobox()
    //    {
    //        this.Add(new ClangbuilderUIItem { ID = 1, Value = "110" ,Content="Visual Studio 2012 [Windows 8]"});
    //        this.Add(new ClangbuilderUIItem { ID = 2, Value = "120", Content = "Visual Studio 2013 [Windows 8.1]" });
    //        this.Add(new ClangbuilderUIItem { ID = 3, Value = "140", Content = "Visual Studio 2015 [Windows 8.1]" });
    //        this.Add(new ClangbuilderUIItem { ID = 4, Value = "141", Content = "Visual Studio 2015 [Windows 10]" });
    //        this.Add(new ClangbuilderUIItem { ID = 5, Value = "150", Content = "Visual Studio 15 " }); 
    //    }
    //}
    /// <summary>
    /// MainWindow.xaml 的交互逻辑
    /// </summary>
    ///     public partial class MainWindow :MetroWindow
    public partial class MainWindow : MetroWindow
    {
        public MainWindow()
        {
            InitializeComponent();
            if (Environment.GetEnvironmentVariable("VS140COMNTOOLS") != null)
            {
                String subKey = @"SOFTWARE\Microsoft\Windows NT\CurrentVersion";
                RegistryKey key = Registry.LocalMachine;
                RegistryKey skey = key.OpenSubKey(subKey);
                if (skey.GetValue("CurrentMajorVersionNumber") != null)
                {
                    int major = (int)skey.GetValue("CurrentMajorVersionNumber");
                    if (major >= 10)
                    {
                        visualstudioVersion.SelectedIndex = 3;
                    }
                    else
                    {
                        visualstudioVersion.SelectedIndex = 2;
                    }
                }
                else
                {
                    visualstudioVersion.SelectedIndex = 2;
                }
                //visualstudioVersion.SelectedIndex
            }
            else if (Environment.GetEnvironmentVariable("VS120COMNTOOLS") != null)
            {
                visualstudioVersion.SelectedIndex = 1;
            }
            else if (Environment.GetEnvironmentVariable("VS110COMNTOOLS") != null)
            {
                visualstudioVersion.SelectedIndex = 0;
            }
            else
            {
                this.ShowMessageAsync("Cannot find a supported version of VisualStudio !", "Visual Studio 2012 , 2013 and 2015");
            }
            if (System.Environment.Is64BitOperatingSystem)
            {
                arch.SelectedIndex = 1;
            }
            else
            {
                arch.SelectedIndex = 0;
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
            String[] stringConfiguration = { "Release", "MinSizeRel", "RelWithDebInfo", "Debug" };
            if (visualstudioVersion.SelectedIndex == -1 || arch.SelectedIndex == -1 || flavor.SelectedIndex == -1)
            {
                this.ShowMessageAsync("Cannot Continue !",
                    "VisualStudio ,Target , Configuration Must be selected !");
                return null;
            }
            String Args = "-V " + stringVs[visualstudioVersion.SelectedIndex] + " -T " + stringArch[arch.SelectedIndex];
            if (IsBuilder)
            {
                Args += " -C " + stringConfiguration[flavor.SelectedIndex];
                Args += " -B";
                if (IsCreateInstallPackage.IsChecked == true)
                {
                    Args += " -I";
                }
                if (IsEnabledStaticRuntime.IsChecked == true)
                {
                    Args += " -S";
                }
                if (IsUseNMakeBuilder.IsChecked == true)
                {
                    Args += " -N";
                }
                if (IsBuildReleasedRevision.IsChecked == true)
                {
                    Args += " -R";
                }
                if (IsBuidLLDB.IsChecked == true)
                {
                    Args += " -L";
                }

            }
            if (IsCleanEnvironment.IsChecked == true)
            {
                Args += " -E";
            }
            StartupLauncher(Args);
            return null;
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
    }
}
