/**
    D3D11AppView.cpp
*/

#include "pch.h"
#include "D3D11AppView.h"

using namespace Windows::ApplicationModel;
using namespace Windows::ApplicationModel::Core;
using namespace Windows::ApplicationModel::Activation;
using namespace Windows::Foundation;
using namespace Windows::Graphics::Display;
using namespace Windows::System;
using namespace Windows::UI::Core;
using namespace Windows::UI::Input;
using namespace DirectX;

/**
*/
struct AppViewSource : implements<AppViewSource, IFrameworkViewSource>
{
    virtual IFrameworkView CreateView() { return make<AppView>(); }
};

/**
*/
int __stdcall wWinMain(HINSTANCE, HINSTANCE, PWSTR, int)
{
    CoreApplication::Run(AppViewSource());
}

/**
*/
inline void ChkTrue(bool b)
{
    if (!b)
    {
        throw std::exception("Unexpected error");
    }
}

/**
*/
inline void ChkOk(HRESULT hr)
{
    ChkTrue(hr == S_OK);
}

/**
    Initialize the view.
*/
void AppView::Initialize(const CoreApplicationView& applicationView)
{
    applicationView.Activated({ this, &AppView::OnActivated });
}

/**
    Associate a CoreWindow with the view.
*/
void AppView::SetWindow(const CoreWindow& window)
{
    m_window = window;
    m_logicalSize = Windows::Foundation::Size(window.Bounds().Width, window.Bounds().Height);
    window.SizeChanged({ this, &AppView::OnWindowSizeChanged });
    window.VisibilityChanged({ this, &AppView::OnVisibilityChanged });
    window.Closed({ this, &AppView::OnWindowClosed });
    window.PointerPressed({ this, &AppView::OnPointerPressed });
    window.PointerReleased({ this, &AppView::OnPointerReleased });
    window.PointerWheelChanged({ this, &AppView::OnPointerWheelChanged });

    auto mouse = Windows::Devices::Input::MouseDevice::GetForCurrentView();
    mouse.MouseMoved({ this, &AppView::OnMouseMoved });
    m_defaultCursor = m_window.PointerCursor();
    m_cursor = m_defaultCursor;

    auto currentDisplayInformation = DisplayInformation::GetForCurrentView();
    m_nativeOrientation = currentDisplayInformation.NativeOrientation();
    m_currentOrientation = currentDisplayInformation.CurrentOrientation();
    m_dpi = currentDisplayInformation.LogicalDpi();
    currentDisplayInformation.DpiChanged({ this, &AppView::OnDpiChanged });
    currentDisplayInformation.OrientationChanged({ this, &AppView::OnOrientationChanged });
    DisplayInformation::DisplayContentsInvalidated({ this, &AppView::OnDisplayContentsInvalidated });
}

/**
    Create the D3D swap chain, etc.
*/
void AppView::Load(const hstring& entryPoint)
{
    CreateDeviceResources();
    CreateWindowSizeDependentResources();
}

/**
    Run the app.
*/
void AppView::Run()
{
    while (!m_windowClosed)
    {
        if (m_windowVisible)
        {
            auto dispatcher = CoreWindow::GetForCurrentThread().Dispatcher();
            dispatcher.ProcessEvents(CoreProcessEventsOption::ProcessAllIfPresent);

            // Reset the viewport to target the whole screen.
            m_context->RSSetViewports(1, &m_viewport);

            // Reset render targets to the screen.
            ID3D11RenderTargetView *const targets[1] = { m_renderTargetView.get() };
            m_context->OMSetRenderTargets(1, targets, m_depthStencilView.get());

            // Clear the back buffer and depth stencil view.
            FLOAT clearColor[] = { 0.165f, 0.047f, 0.251f, 1 };
            m_context->ClearRenderTargetView(m_renderTargetView.get(), clearColor);
            m_context->ClearDepthStencilView(m_depthStencilView.get(), D3D11_CLEAR_DEPTH | D3D11_CLEAR_STENCIL, 1.0f, 0);

            // TODO - render app UI

            // Reset mouse look state for next frame.
            auto window = Windows::UI::Core::CoreWindow::GetForCurrentThread();
            window.PointerCursor(m_cursor);

            // The first argument instructs DXGI to block until VSync, putting the application
            // to sleep until the next VSync. This ensures we don't waste any cycles rendering
            // frames that will never be displayed to the screen.
            DXGI_PRESENT_PARAMETERS parameters = { 0 };
            HRESULT hrPresent = m_swapChain->Present1(1, 0, &parameters);

            // Discard the contents of the render target.
            // This is a valid operation only when the existing contents will be entirely
            // overwritten. If dirty or scroll rects are used, this call should be removed.
            m_context->DiscardView1(m_renderTargetView.get(), nullptr, 0);

            // Discard the contents of the depth stencil.
            m_context->DiscardView1(m_depthStencilView.get(), nullptr, 0);

            // If the device was removed either by a disconnection or a driver upgrade, we 
            // must recreate all device resources.
            if (hrPresent == DXGI_ERROR_DEVICE_REMOVED ||
                hrPresent == DXGI_ERROR_DEVICE_RESET)
            {
                HandleDeviceLost();
            }
            else
            {
                ChkOk(hrPresent);
            }
        }
        else
        {
            auto dispatcher = CoreWindow::GetForCurrentThread().Dispatcher();
            dispatcher.ProcessEvents(CoreProcessEventsOption::ProcessOneAndAllPending);
        }
    }
}

/**
    Uninitialize the view.
*/
void AppView::Uninitialize()
{
    // nothing!
}

/**
    Handle app view activation.
*/
void AppView::OnActivated(const CoreApplicationView& applicationView, const IActivatedEventArgs& args)
{
    CoreWindow::GetForCurrentThread().Activate();
}

/**
    Handle window size change.
*/
void AppView::OnWindowSizeChanged(const CoreWindow& sender, const WindowSizeChangedEventArgs& args)
{
    Size logicalSize(sender.Bounds().Width, sender.Bounds().Height);

    if (m_logicalSize != logicalSize)
    {
        m_logicalSize = logicalSize;

        CreateWindowSizeDependentResources();
    }
}

/**
    Handle window visibility change.
*/
void AppView::OnVisibilityChanged(const CoreWindow& sender, const VisibilityChangedEventArgs& args)
{
    m_windowVisible = args.Visible();
}

/**
    Handle window close.
*/
void AppView::OnWindowClosed(const CoreWindow& sender, const CoreWindowEventArgs& args)
{
    m_windowClosed = true;
}

/**
    Handle DPI change.
*/
void AppView::OnDpiChanged(const DisplayInformation& sender, const IInspectable& args)
{
    if (sender.LogicalDpi() != m_dpi)
    {
        m_dpi = sender.LogicalDpi();

        // When the display DPI changes, the logical size of the window
        // (measured in Dips) also changes and needs to be updated.

        m_logicalSize = Windows::Foundation::Size(m_window.Bounds().Width, m_window.Bounds().Height);

        CreateWindowSizeDependentResources();
    }
}

/**
    Handle orientation change.
*/
void AppView::OnOrientationChanged(const DisplayInformation& sender, const IInspectable& args)
{
    if (m_currentOrientation != sender.CurrentOrientation())
    {
        m_currentOrientation = sender.CurrentOrientation();

       CreateWindowSizeDependentResources();
    }
}

/**
*/
void AppView::OnDisplayContentsInvalidated(const DisplayInformation& sender, const IInspectable& args)
{
    // The D3D Device is no longer valid if the default adapter changed
    // since the device was created or if the device has been removed.

    // First, get the information for the default adapter from when the
    // device was created.

    auto dxgiDevice = m_device.as<IDXGIDevice3>();
    com_ptr<IDXGIAdapter> deviceAdapter;
    ChkOk(dxgiDevice->GetAdapter(deviceAdapter.put()));
    com_ptr<IDXGIFactory4> deviceFactory;
    ChkOk(deviceAdapter->GetParent(_uuidof(deviceFactory), deviceFactory.put_void()));
    com_ptr<IDXGIAdapter1> previousDefaultAdapter;
    ChkOk(deviceFactory->EnumAdapters1(0, previousDefaultAdapter.put()));
    DXGI_ADAPTER_DESC1 previousDesc;
    ChkOk(previousDefaultAdapter->GetDesc1(&previousDesc));

    // Next, get the information for the current default adapter.

    com_ptr<IDXGIFactory4> currentFactory;
    ChkOk(CreateDXGIFactory1(__uuidof(currentFactory), currentFactory.put_void()));
    com_ptr<IDXGIAdapter1> currentDefaultAdapter;
    ChkOk(currentFactory->EnumAdapters1(0, currentDefaultAdapter.put()));
    DXGI_ADAPTER_DESC1 currentDesc;
    ChkOk(currentDefaultAdapter->GetDesc1(&currentDesc));

    // If the adapter LUIDs don't match, or if the device reports
    // that it has been removed, a new D3D device must be created.

    if (previousDesc.AdapterLuid.LowPart != currentDesc.AdapterLuid.LowPart ||
        previousDesc.AdapterLuid.HighPart != currentDesc.AdapterLuid.HighPart ||
        FAILED(m_device->GetDeviceRemovedReason()))
    {
        // Release references to resources related to the old device.
        dxgiDevice = nullptr;
        deviceAdapter = nullptr;
        deviceFactory = nullptr;
        previousDefaultAdapter = nullptr;

        // Create a new device and swap chain.
        HandleDeviceLost();
    }
}

/**
    Create the Direct3D device.
*/
void AppView::CreateDeviceResources()
{
    UINT creationFlags = 0;

#if defined(_DEBUG)

    HRESULT hrSdkLayersCheck = D3D11CreateDevice(
        nullptr,
        D3D_DRIVER_TYPE_NULL,       // There is no need to create a real hardware device.
        0,
        D3D11_CREATE_DEVICE_DEBUG,  // Check for the SDK layers.
        nullptr,                    // Any feature level will do.
        0,
        D3D11_SDK_VERSION,          // Always set this to D3D11_SDK_VERSION for Windows Store apps.
        nullptr,                    // No need to keep the D3D device reference.
        nullptr,                    // No need to know the feature level.
        nullptr                     // No need to keep the D3D device context reference.
    );

    if (SUCCEEDED(hrSdkLayersCheck))
    {
        // If the project is in a debug build, enable debugging via SDK Layers with this flag.
        creationFlags |= D3D11_CREATE_DEVICE_DEBUG;
    }

#endif

    // This array defines the set of DirectX hardware feature levels this app will support.
    // Note the ordering should be preserved.
    // Don't forget to declare your application's minimum required feature level in its
    // description.  All applications are assumed to support 9.1 unless otherwise stated.
    static const D3D_FEATURE_LEVEL featureLevels[] =
    {
        D3D_FEATURE_LEVEL_12_1,
        D3D_FEATURE_LEVEL_12_0,
        D3D_FEATURE_LEVEL_11_1,
        D3D_FEATURE_LEVEL_11_0,
        D3D_FEATURE_LEVEL_10_1,
        D3D_FEATURE_LEVEL_10_0,
        D3D_FEATURE_LEVEL_9_3,
        D3D_FEATURE_LEVEL_9_2,
        D3D_FEATURE_LEVEL_9_1
    };

    // Create the Direct3D 11 API device object and a corresponding context.
    com_ptr<ID3D11Device> device;
    com_ptr<ID3D11DeviceContext> context;

    HRESULT hr = D3D11CreateDevice(
        nullptr,                    // Specify nullptr to use the default adapter.
        D3D_DRIVER_TYPE_HARDWARE,   // Create a device using the hardware graphics driver.
        0,                          // Should be 0 unless the driver is D3D_DRIVER_TYPE_SOFTWARE.
        creationFlags,              // Set debug and Direct2D compatibility flags.
        featureLevels,              // List of feature levels this app can support.
        ARRAYSIZE(featureLevels),   // Size of the list above.
        D3D11_SDK_VERSION,          // Always set this to D3D11_SDK_VERSION for Windows Store apps.
        device.put(),               // Returns the Direct3D device created.
        &m_featureLevel,            // Returns feature level of device created.
        context.put()               // Returns the device immediate context.
    );

    if (FAILED(hr))
    {
        // Initialization failed, fall back to the WARP device.
        ChkOk(
            D3D11CreateDevice(
                nullptr,
                D3D_DRIVER_TYPE_WARP,
                0,
                creationFlags,
                featureLevels,
                ARRAYSIZE(featureLevels),
                D3D11_SDK_VERSION,
                device.put(),
                &m_featureLevel,
                context.put()));
    }

    // Store pointers to the Direct3D 11.3 API device and immediate context.
    ChkTrue(device.try_as(m_device));
    ChkTrue(context.try_as(m_context));

    // Create the Direct2D device object and a corresponding context.
    com_ptr<IDXGIDevice3> dxgiDevice;
    ChkTrue(m_device.try_as(dxgiDevice));
}

/**
    This method determines the rotation between the display device's native
    orientation and the current display orientation.
*/
DXGI_MODE_ROTATION AppView::ComputeDisplayRotation()
{
    // Note: m_nativeOrientation can only be Landscape or Portrait even though
    // the DisplayOrientations enum has other values.

    switch (m_nativeOrientation)
    {
        case DisplayOrientations::Landscape:
        {
            switch (m_currentOrientation)
            {
                case DisplayOrientations::Landscape: return DXGI_MODE_ROTATION_IDENTITY;
                case DisplayOrientations::Portrait: return DXGI_MODE_ROTATION_ROTATE270;
                case DisplayOrientations::LandscapeFlipped: return DXGI_MODE_ROTATION_ROTATE180;
                case DisplayOrientations::PortraitFlipped: return DXGI_MODE_ROTATION_ROTATE90;
            }
        }
        break;

        case DisplayOrientations::Portrait:
        {
            switch (m_currentOrientation)
            {
                case DisplayOrientations::Landscape: return DXGI_MODE_ROTATION_ROTATE90;
                case DisplayOrientations::Portrait: return DXGI_MODE_ROTATION_IDENTITY;
                case DisplayOrientations::LandscapeFlipped: return DXGI_MODE_ROTATION_ROTATE270;
                case DisplayOrientations::PortraitFlipped: return DXGI_MODE_ROTATION_ROTATE180;
            }
        }
        break;
    }

    return DXGI_MODE_ROTATION_UNSPECIFIED;
}

/**
    Converts a length in device-independent pixels to a length in physical pixels.
*/
float AppView::ConvertDipsToPixels(float dips)
{
    static const float dipsPerInch = 96.0f;
    return floorf(dips * m_dpi / dipsPerInch + 0.5f); // Round to nearest integer.
}

/**
    These resources need to be recreated every time the window size is changed.
*/
void AppView::CreateWindowSizeDependentResources()
{
    // Clear the previous window size specific context.
    ID3D11RenderTargetView* nullViews[] = { nullptr };
    m_context->OMSetRenderTargets(ARRAYSIZE(nullViews), nullViews, nullptr);
    m_renderTargetView = nullptr;
    m_depthStencilView = nullptr;
    m_context->Flush1(D3D11_CONTEXT_TYPE_ALL, nullptr);

    // Calculate the necessary render target size in pixels.
    // The std::max calls make sure we don't pass zero to D3D.
    m_outputSize.Width = (std::max)(1.0f, ConvertDipsToPixels(m_logicalSize.Width));
    m_outputSize.Height = (std::max)(1.0f, ConvertDipsToPixels(m_logicalSize.Height));

    // The width and height of the swap chain must be based on the window's
    // natively-oriented width and height. If the window is not in the native
    // orientation, the dimensions must be reversed.
    DXGI_MODE_ROTATION displayRotation = ComputeDisplayRotation();
    bool swapDimensions = displayRotation == DXGI_MODE_ROTATION_ROTATE90 || displayRotation == DXGI_MODE_ROTATION_ROTATE270;
    m_renderTargetSize.Width = swapDimensions ? m_outputSize.Height : m_outputSize.Width;
    m_renderTargetSize.Height = swapDimensions ? m_outputSize.Width : m_outputSize.Height;

    if (m_swapChain != nullptr)
    {
        // The swap chain already exists, resize it.
        HRESULT hr = m_swapChain->ResizeBuffers(
            2, // Double-buffered swap chain.
            lround(m_renderTargetSize.Width),
            lround(m_renderTargetSize.Height),
            DXGI_FORMAT_B8G8R8A8_UNORM,
            0);

        if (hr == DXGI_ERROR_DEVICE_REMOVED || hr == DXGI_ERROR_DEVICE_RESET)
        {
            // If the device was removed for any reason, a new device
            // and swap chain will need to be created.
            HandleDeviceLost();

            // Everything is set up now. Do not continue execution of this
            // method. HandleDeviceLost will reenter this method and correctly
            // set up the new device.
            return;
        }
        else
        {
            ChkOk(hr);
        }
    }
    else
    {
        // Create a new swap chain using the same adapter as the existing device.
        DXGI_SWAP_CHAIN_DESC1 swapChainDesc = { 0 };
        swapChainDesc.Width = lround(m_renderTargetSize.Width);         // Match the size of the window.
        swapChainDesc.Height = lround(m_renderTargetSize.Height);
        swapChainDesc.Format = DXGI_FORMAT_B8G8R8A8_UNORM;              // This is the most common swap chain format.
        swapChainDesc.Stereo = FALSE;
        swapChainDesc.SampleDesc.Count = 1;                             // Don't use multi-sampling.
        swapChainDesc.SampleDesc.Quality = 0;
        swapChainDesc.BufferUsage = DXGI_USAGE_RENDER_TARGET_OUTPUT;
        swapChainDesc.BufferCount = 2;                                  // Use double-buffering to minimize latency.
        swapChainDesc.SwapEffect = DXGI_SWAP_EFFECT_FLIP_SEQUENTIAL;    // All Windows Store apps must use this SwapEffect.
        swapChainDesc.Flags = 0;
        swapChainDesc.Scaling = DXGI_SCALING_STRETCH;
        swapChainDesc.AlphaMode = DXGI_ALPHA_MODE_IGNORE;

        // This sequence obtains the DXGI factory that was used to create the Direct3D device above.
        com_ptr<IDXGIDevice3> dxgiDevice;
        ChkTrue(m_device.try_as(dxgiDevice));
        com_ptr<IDXGIAdapter> dxgiAdapter;
        ChkOk(dxgiDevice->GetAdapter(dxgiAdapter.put()));
        com_ptr<IDXGIFactory4> dxgiFactory;
        ChkOk(dxgiAdapter->GetParent(__uuidof(dxgiFactory), dxgiFactory.put_void()));

        auto unkWindow = m_window.as<::IUnknown>();
        com_ptr<IDXGISwapChain1> swapChain;
        ChkOk(
            dxgiFactory->CreateSwapChainForCoreWindow(
                m_device.get(),
                unkWindow.get(),
                &swapChainDesc,
                nullptr,
                swapChain.put()));
        ChkTrue(swapChain.try_as(m_swapChain));

        // Ensure that DXGI does not queue more than one frame at a time. This both reduces latency and
        // ensures that the application will only render after each VSync, minimizing power consumption.
        ChkOk(dxgiDevice->SetMaximumFrameLatency(1));
    }

    // Set the proper orientation for the swap chain and
    // the transform for rendering to the rotated swap chain.

    ChkOk(m_swapChain->SetRotation(displayRotation));

    // 0-degree Z-rotation
    static const XMFLOAT4X4 Rotation0(
        1.0f, 0.0f, 0.0f, 0.0f,
        0.0f, 1.0f, 0.0f, 0.0f,
        0.0f, 0.0f, 1.0f, 0.0f,
        0.0f, 0.0f, 0.0f, 1.0f);

    // 90-degree Z-rotation
    static const XMFLOAT4X4 Rotation90(
        0.0f, 1.0f, 0.0f, 0.0f,
        -1.0f, 0.0f, 0.0f, 0.0f,
        0.0f, 0.0f, 1.0f, 0.0f,
        0.0f, 0.0f, 0.0f, 1.0f);

    // 180-degree Z-rotation
    static const XMFLOAT4X4 Rotation180(
        -1.0f, 0.0f, 0.0f, 0.0f,
        0.0f, -1.0f, 0.0f, 0.0f,
        0.0f, 0.0f, 1.0f, 0.0f,
        0.0f, 0.0f, 0.0f, 1.0f);

    // 270-degree Z-rotation
    static const XMFLOAT4X4 Rotation270(
        0.0f, -1.0f, 0.0f, 0.0f,
        1.0f, 0.0f, 0.0f, 0.0f,
        0.0f, 0.0f, 1.0f, 0.0f,
        0.0f, 0.0f, 0.0f, 1.0f);

    switch (displayRotation)
    {
        case DXGI_MODE_ROTATION_IDENTITY: m_orientationTransform = Rotation0; break;
        case DXGI_MODE_ROTATION_ROTATE90: m_orientationTransform = Rotation270; break;
        case DXGI_MODE_ROTATION_ROTATE180: m_orientationTransform = Rotation180; break;
        case DXGI_MODE_ROTATION_ROTATE270: m_orientationTransform = Rotation90; break;

        default:
            ChkTrue(false);
    }

    // Create a render target view of the swap chain back buffer.
    com_ptr<ID3D11Texture2D1> backBuffer;
    ChkOk(m_swapChain->GetBuffer(0, __uuidof(backBuffer), backBuffer.put_void()));
    ChkOk(m_device->CreateRenderTargetView1(backBuffer.get(), nullptr, m_renderTargetView.put()));

    // Create a depth stencil view for use with 3D rendering if needed.
    CD3D11_TEXTURE2D_DESC1 depthStencilDesc(
        DXGI_FORMAT_D24_UNORM_S8_UINT,
        lround(m_renderTargetSize.Width),
        lround(m_renderTargetSize.Height),
        1, // This depth stencil view has only one texture.
        1, // Use a single mipmap level.
        D3D11_BIND_DEPTH_STENCIL);

    com_ptr<ID3D11Texture2D1> depthStencil;
    ChkOk(m_device->CreateTexture2D1(&depthStencilDesc, nullptr, depthStencil.put()));

    CD3D11_DEPTH_STENCIL_VIEW_DESC depthStencilViewDesc(D3D11_DSV_DIMENSION_TEXTURE2D);
    ChkOk(m_device->CreateDepthStencilView(depthStencil.get(), &depthStencilViewDesc, m_depthStencilView.put()));

    // Set the 3D rendering viewport to target the entire window.
    m_viewport = CD3D11_VIEWPORT(0.0f, 0.0f, m_renderTargetSize.Width, m_renderTargetSize.Height);
    m_context->RSSetViewports(1, &m_viewport);
}

/**
    Recreate all device resources and set them back to the current state.
*/
void AppView::HandleDeviceLost()
{
    m_swapChain = nullptr;
    CreateDeviceResources();
    CreateWindowSizeDependentResources();
}

/**
*/
void AppView::OnPointerPressed(const CoreWindow& sender, const PointerEventArgs& args)
{
    UpdatePointerButtons(args);
    m_cursor = nullptr;
}

/**
*/
void AppView::OnPointerReleased(const CoreWindow& sender, const PointerEventArgs& args)
{
    UpdatePointerButtons(args);
    m_cursor = m_defaultCursor;
}

/**
*/
void AppView::OnMouseMoved(const MouseDevice& sender, const MouseEventArgs& args)
{
    if (m_cursor == nullptr)
    {
        float dx = float(args.MouseDelta().X) / 100.0f;
        float dy = float(args.MouseDelta().Y) / 100.0f;
        // TODO: Do something with dx, dy
    }
}

/**
*/
void AppView::OnPointerWheelChanged(const CoreWindow& sender, const PointerEventArgs& args)
{
    static int CLICKS_PER_TURN = 100;
    auto d = args.CurrentPoint().Properties().MouseWheelDelta();
    auto nd = float(d) / float(WHEEL_DELTA * CLICKS_PER_TURN);
    nd = (std::max)(-1.0f, (std::min)(+1.0f, nd));
    // TODO: Do something with nd
}

/**
*/
void AppView::UpdatePointerButtons(const PointerEventArgs& args)
{
    auto device = args.CurrentPoint().PointerDevice();

    if (device.PointerDeviceType() == PointerDeviceType::Mouse)
    {
        auto properties = args.CurrentPoint().Properties();
        // TODO: Do something with properties
    }
}
