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

namespace ClangSetupvNextSet
{
    /// <summary>
    /// MainWindow.xaml 的交互逻辑
    /// </summary>
    ///     public partial class MainWindow :MetroWindow
    public partial class MainWindow :MetroWindow
    {
        private String[] target = { "X86", "X64", "ARM", "AArch64" };
        private String[] bdtype = { "Release", "MinSizeRel", "RelWithDebInfo", "Debug" };
        public MainWindow()
        {
            InitializeComponent();
        }

        private async void ClangSetupSettingsFeature(object sender, RoutedEventArgs e)
        {
            MetroDialogOptions.ColorScheme = MetroDialogColorScheme.Theme;

            var mySettings = new MetroDialogSettings()
            {
                AffirmativeButtonText = "OK",
                NegativeButtonText = "Visit Home",
                FirstAuxiliaryButtonText = "Cancel",
                ColorScheme = MetroDialogColorScheme.Theme
            };

            MessageDialogResult result = await this.ShowMessageAsync("ClangSetup Setting", "Welcome to use the ClangSetup Environment Configuration tool\nCopyright \xA9 2015 ForceStudio All Rights Reserved. ",
                MessageDialogStyle.AffirmativeAndNegativeAndSingleAuxiliary, mySettings);

            if (result != MessageDialogResult.FirstAuxiliary)
                await this.ShowMessageAsync("Result", "You said: " + (result == MessageDialogResult.Affirmative ? mySettings.AffirmativeButtonText : mySettings.NegativeButtonText +
                    Environment.NewLine + Environment.NewLine + "This dialog will follow the Use Accent setting."));
        }

        private void OnInitializeEnvironment(object sender, RoutedEventArgs e)
        {

        }

        private void OnStartBuildOnce(object sender, RoutedEventArgs e)
        {
            if(vstoolscb.SelectedIndex==-1||platformCb.SelectedIndex==-1||buildtypecb.SelectedIndex==-1)
            {
                this.ShowMessageAsync("You must select the compile parameters", "Select VisualStudio Version or Platform or Build Configuration");
                return ;
            }
            String launcherParam =" -V ";
            ComboBoxItem cbitem =(ComboBoxItem) vstoolscb.SelectedItem;
            launcherParam+= cbitem.Name;
            launcherParam += " -T " + target[platformCb.SelectedIndex];
            launcherParam += " -B " + bdtype[buildtypecb.SelectedIndex];
            if (useMTcrtbox.IsChecked==true)
            {
                launcherParam += "-MD";
            }
            if (mkinpackbox.IsChecked == true)
            {
                launcherParam += " -MK";
            }
            if (usecleanenvbox.IsChecked == true)
            {
                launcherParam += " -CE";
            }
            if(useNMakeBuilder.IsChecked==true)
            {
                launcherParam += " -NMake";
            }
            if(addLLDBBuilder.IsChecked==true)
            {
                launcherParam += " -LLDB";
            }
           // MessageBox.Show(launcherParam);
            String launcher = Process.GetCurrentProcess().MainModule.FileName;
            launcher = launcher.Substring(0, launcher.LastIndexOf("\\"));
            launcher = launcher.Substring(0, launcher.LastIndexOf("\\"));
            launcher += "\\NativeTools\\Launcher.exe";
            if (!System.IO.File.Exists(launcher))
            {
                this.ShowMessageAsync("Not Found Launcher.exe In this Path:",launcher);
                return ;
            }
            ProcessStartInfo psInfo = new ProcessStartInfo();
            psInfo.FileName = launcher;
            psInfo.Arguments = launcherParam;
            Process.Start(psInfo);
        }
    }
}
