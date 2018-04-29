#include <winrt\Windows.ApplicationModel.Activation.h>
#include <winrt\Windows.Devices.Enumeration.h>
#include <winrt\Windows.Foundation.h>
#include <winrt\Windows.UI.Xaml.h>
#include <winrt\Windows.UI.Xaml.Controls.h>
#include <winrt\Windows.UI.Xaml.Media.Imaging.h>


using namespace winrt;
using namespace winrt::Windows::ApplicationModel::Activation;
using namespace winrt::Windows::Devices::Enumeration;
using namespace winrt::Windows::Foundation;
using namespace winrt::Windows::UI::Xaml;
using namespace winrt::Windows::UI::Xaml::Controls;
using namespace winrt::Windows::UI::Xaml::Media::Imaging;


struct App : ApplicationT<App>
{
    void OnLaunched(LaunchActivatedEventArgs const &)
    {
        Image image;
        image.Height(30);
        image.Width(30);
        image.Source(BitmapImage(Uri(L"ms-appx:///Assets/Images/sample.png")));

        Button button;
        button.Padding(ThicknessHelper::FromUniformLength(0));
        button.BorderThickness(ThicknessHelper::FromUniformLength(0));
        button.Content(image);

        Window window = Window::Current();
        window.Content(button);
        window.Activate();
    }

    static void Initialize(ApplicationInitializationCallbackParams const &)
    {
        make<App>();
    }

    static void Start()
    {
        Application::Start(App::Initialize);
    }
};

int WINAPI wWinMain(HINSTANCE, HINSTANCE, PWSTR, int)
{
    App::Start();
}