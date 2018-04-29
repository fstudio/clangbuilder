/**
    D3D11AppView.h
*/

#pragma once

#include "pch.h"

using namespace winrt;
using namespace Windows;
using namespace Windows::Devices::Input;
using namespace Windows::Graphics::Display;
using namespace Windows::ApplicationModel::Activation;
using namespace Windows::ApplicationModel::Core;
using namespace Windows::Foundation::Numerics;
using namespace Windows::UI;
using namespace Windows::UI::Core;
using namespace Windows::UI::Composition;

/**
*/
struct AppView : implements<AppView, IFrameworkView>
{

public:

    // IFrameworkView Methods.
    virtual void Initialize(const CoreApplicationView& applicationView);
    virtual void SetWindow(const CoreWindow& window);
    virtual void Load(const hstring& entryPoint);
    virtual void Run();
    virtual void Uninitialize();

private:

    // Event handlers.
    void OnActivated(const CoreApplicationView& applicationView, const IActivatedEventArgs& args);
    void OnWindowSizeChanged(const CoreWindow& sender, const WindowSizeChangedEventArgs& args);
    void OnVisibilityChanged(const CoreWindow& sender, const VisibilityChangedEventArgs& args);
    void OnWindowClosed(const CoreWindow& sender, const CoreWindowEventArgs& args);
    void OnDpiChanged(const DisplayInformation& sender, const IInspectable& args);
    void OnOrientationChanged(const DisplayInformation& sender, const IInspectable& args);
    void OnDisplayContentsInvalidated(const DisplayInformation& sender, const IInspectable& args);
    void OnPointerPressed(const CoreWindow& sender, const PointerEventArgs& args);
    void OnPointerReleased(const CoreWindow& sender, const PointerEventArgs& args);
    void OnPointerWheelChanged(const CoreWindow& sender, const PointerEventArgs& args);
    void OnMouseMoved(const MouseDevice& sender, const MouseEventArgs& args);

    // Internal methods.
    void HandleDeviceLost();
    void CreateDeviceResources();
    void CreateWindowSizeDependentResources();
    DXGI_MODE_ROTATION ComputeDisplayRotation();
    float ConvertDipsToPixels(float dips);
    void UpdatePointerButtons(const PointerEventArgs& args);

    // Window state.
    bool m_windowClosed = false;
    bool m_windowVisible = true;

    // Cached window and display properties.
    CoreWindow m_window = nullptr;
    float m_dpi = -1.0f;

    // Direct3D objects.
    com_ptr<ID3D11Device3> m_device;
    com_ptr<ID3D11DeviceContext3> m_context;
    com_ptr<IDXGISwapChain3> m_swapChain;

    // Direct3D rendering objects. Required for 3D.
    com_ptr<ID3D11RenderTargetView1> m_renderTargetView;
    com_ptr<ID3D11DepthStencilView> m_depthStencilView;
    D3D11_VIEWPORT m_viewport = D3D11_VIEWPORT();

    // Cached device properties.
    D3D_FEATURE_LEVEL m_featureLevel = D3D_FEATURE_LEVEL_9_1;
    Windows::Foundation::Size m_renderTargetSize = Windows::Foundation::Size();
    Windows::Foundation::Size m_outputSize = Windows::Foundation::Size();
    Windows::Foundation::Size m_logicalSize = Windows::Foundation::Size();
    Windows::Graphics::Display::DisplayOrientations	m_nativeOrientation = Windows::Graphics::Display::DisplayOrientations::None;
    Windows::Graphics::Display::DisplayOrientations	m_currentOrientation = Windows::Graphics::Display::DisplayOrientations::None;

    // Transforms used for display orientation.
    DirectX::XMFLOAT4X4	m_orientationTransform;

    // Previous pointer position. Used to compute deltas.
    CoreCursor m_defaultCursor = nullptr;
    CoreCursor m_cursor = nullptr;

};
