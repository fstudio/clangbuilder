#include "pch.h"
#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.UI.Xaml.h>
#include <winrt/Windows.UI.Xaml.Controls.h>
#include <winrt/Windows.UI.Xaml.Media.h>
#include <winrt/Windows.UI.Xaml.Hosting.h>
//#include <winrt/Microsoft.Graphics.Canvas.Text.h>
//#include <winrt/Microsoft.Graphics.Canvas.UI.Xaml.h>
#include "resources.h"

using namespace winrt;
using namespace Windows::Foundation;
using namespace Windows::UI;
using namespace Windows::UI::Composition;
using namespace Windows::UI::Composition::Desktop;
using namespace Windows::UI::Xaml;
using namespace Windows::UI::Xaml::Controls;
using namespace Windows::UI::Xaml::Media;
using namespace Windows::UI::Xaml::Hosting;
//using namespace Microsoft::Graphics::Canvas;
//using namespace Microsoft::Graphics::Canvas::Text;
//using namespace Microsoft::Graphics::Canvas::UI::Xaml;



auto CreateDispatcherQueueController()
{
    namespace ABI = ABI::Windows::System;

    DispatcherQueueOptions options
    {
        sizeof(DispatcherQueueOptions),
        DQTYPE_THREAD_CURRENT,
        DQTAT_COM_STA
    };

    Windows::System::DispatcherQueueController controller{ nullptr };
    check_hresult(CreateDispatcherQueueController(options, reinterpret_cast<ABI::IDispatcherQueueController**>(put_abi(controller))));
    return controller;
}

DesktopWindowTarget CreateDesktopWindowTarget(Compositor const& compositor, HWND window)
{
    namespace ABI = ABI::Windows::UI::Composition::Desktop;

    auto interop = compositor.as<ABI::ICompositorDesktopInterop>();
    DesktopWindowTarget target{ nullptr };
    check_hresult(interop->CreateDesktopWindowTarget(window, true, reinterpret_cast<ABI::IDesktopWindowTarget**>(put_abi(target))));
    return target;
}

template <typename T>
struct DesktopWindow
{
    using base_type = DesktopWindow<T>;
    HWND m_window = nullptr;

    static T* GetThisFromHandle(HWND const window) noexcept
    {
        return reinterpret_cast<T *>(GetWindowLongPtr(window, GWLP_USERDATA));
    }

    static LRESULT __stdcall WndProc(HWND const window, UINT const message, WPARAM const wparam, LPARAM const lparam) noexcept
    {
        WINRT_ASSERT(window);

        if (WM_NCCREATE == message)
        {
            auto cs = reinterpret_cast<CREATESTRUCT *>(lparam);
            T* that = static_cast<T*>(cs->lpCreateParams);
            WINRT_ASSERT(that);
            WINRT_ASSERT(!that->m_window);
            that->m_window = window;
            SetWindowLongPtr(window, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(that));
        }
        else if (T* that = GetThisFromHandle(window))
        {
            return that->MessageHandler(message, wparam, lparam);
        }

        return DefWindowProc(window, message, wparam, lparam);
    }

    LRESULT MessageHandler(UINT const message, WPARAM const wparam, LPARAM const lparam) noexcept
    {
        if (WM_DESTROY == message)
        {
            PostQuitMessage(0);
            return 0;
        }
		if(WM_CREATE == message){
			  HICON hIcon = LoadIconW( reinterpret_cast<HINSTANCE>(&__ImageBase),
                          MAKEINTRESOURCEW(IDI_BALTIICON));
			  ::SendMessageW(m_window, WM_SETICON, ICON_SMALL, (LPARAM)hIcon);
			return 0;
		}
        return DefWindowProc(m_window, message, wparam, lparam);
    }
};

struct BaltiWindow : DesktopWindow<BaltiWindow>
{
    BaltiWindow() noexcept
    {
        WNDCLASSW wc{};
        wc.hCursor = LoadCursor(nullptr, IDC_ARROW);
        wc.hInstance = reinterpret_cast<HINSTANCE>(&__ImageBase);
        wc.lpszClassName = L"Balti.Window";
        wc.style = CS_HREDRAW | CS_VREDRAW;
        wc.lpfnWndProc = WndProc;
        RegisterClassW(&wc);
        WINRT_ASSERT(!m_window);

        WINRT_VERIFY(CreateWindowExW(0L,wc.lpszClassName,
            L"Balti", 
            WS_OVERLAPPEDWINDOW | WS_VISIBLE, 
            CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, 
            nullptr, nullptr, wc.hInstance, this));

        WINRT_ASSERT(m_window);
    }

    LRESULT MessageHandler(UINT const message, WPARAM const wparam, LPARAM const lparam) noexcept
    {
        return base_type::MessageHandler(message, wparam, lparam);
    }

    void PrepareVisuals()
    {
        Compositor compositor;
        m_target = CreateDesktopWindowTarget(compositor, m_window);
        auto root = compositor.CreateSpriteVisual();
        root.RelativeSizeAdjustment({ 1.0f, 1.0f });
		/// create Acrylic brush
		//AcrylicBrush acrylic;
		//root.Brush(compositor.CreateColorBrush({ 0xFF, 0x00, 0xFF , 0xFF }));
		root.Brush();
        m_target.Root(root);
	
		
        auto visuals = root.Children();
        AddVisual(visuals, 100.0f, 100.0f);
        AddVisual(visuals, 220.0f, 100.0f);
        AddVisual(visuals, 100.0f, 220.0f);
        AddVisual(visuals, 220.0f, 220.0f);
    }

    void AddVisual(VisualCollection const& visuals, float x, float y)
    {
        auto compositor = visuals.Compositor();
        auto visual = compositor.CreateSpriteVisual();
        static Color colors[] =
        {
            { 0xDC, 0x5B, 0x9B, 0xD5 },
            { 0xDC, 0xFF, 0xC0, 0x00 },
            { 0xDC, 0xED, 0x7D, 0x31 },
            { 0xDC, 0x70, 0xAD, 0x47 },
        };

        static unsigned last = 0;
        unsigned const next = ++last % 4;
        visual.Brush(compositor.CreateColorBrush(colors[next]));

        visual.Size(
        {
            100.0f,
            100.0f
        });

        visual.Offset(
        {
            x,
            y,
            0.0f,
        });

        visuals.InsertAtTop(visual);
    }

    DesktopWindowTarget m_target{ nullptr };
};

int WindowRunning()
{
    init_apartment(apartment_type::single_threaded);
    auto controller = CreateDispatcherQueueController();

    BaltiWindow window;
    window.PrepareVisuals();
    MSG message;

    while (GetMessage(&message, nullptr, 0, 0))
    {
        DispatchMessage(&message);
    }
	return 0;
}