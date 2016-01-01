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

        private void OnBuildingNow(object sender, RoutedEventArgs e)
        {
            if (visualstudioVersion.SelectedIndex == -1 || target.SelectedIndex == -1 || configureType.SelectedIndex == -1)
            {
                this.ShowMessageAsync("You must select the compile parameters", 
                    "VisualStudio ,Target , Configuration Must be selected !");
                return;
            }
        }

        private void OnStartupEnvironment(object sender, RoutedEventArgs e)
        {
        }
    }
}
