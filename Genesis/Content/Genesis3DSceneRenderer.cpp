#include "pch.h"
#include "Genesis3DSceneRenderer.h"

#include "..\Common\DirectXHelper.h"

using namespace Genesis;

using namespace DirectX;
using namespace Windows::Foundation;
using namespace Windows::System;
using namespace Windows::UI::Core;
using namespace Windows::ApplicationModel::Core;

// Loads vertex and pixel shaders from files and instantiates the cube geometry.
Genesis3DSceneRenderer::Genesis3DSceneRenderer(const std::shared_ptr<DX::DeviceResources>& deviceResources) :
	m_deviceResources(deviceResources)
{
	m_camera = std::make_unique<Camera>();
	m_starrySky = std::make_unique<StarrySky>(deviceResources);
	m_tessPlanet = std::make_unique<TessPlanet>(deviceResources);

	CreateDeviceDependentResources();
	CreateWindowSizeDependentResources();
}

// Initializes view parameters when the window size changes.
void Genesis3DSceneRenderer::CreateWindowSizeDependentResources()
{
	Size outputSize = m_deviceResources->GetOutputSize();
	float aspectRatio = outputSize.Width / outputSize.Height;
	float fovAngleY = 70.0f * XM_PI / 180.0f;

	// This is a simple example of change that can be made when the app is in
	// portrait or snapped view.
	if (aspectRatio < 1.0f)
	{
		fovAngleY *= 2.0f;
	}

	// Note that the OrientationTransform3D matrix is post-multiplied here
	// in order to correctly orient the scene to match the display orientation.
	// This post-multiplication step is required for any draw calls that are
	// made to the swap chain render target. For draw calls to other targets,
	// this transform should not be applied.

	// This sample makes use of a right-handed coordinate system using row-major matrices.
	XMMATRIX perspectiveMatrix = XMMatrixPerspectiveFovRH(
		fovAngleY,
		aspectRatio,
		0.01f,
		100.0f
		);

	XMStoreFloat4x4(
		&m_MVPBufferData.projection,
		XMMatrixTranspose(perspectiveMatrix)
	);

	m_camera->LookAt(XMFLOAT3(0.0f, 0.7f, 1.5f), XMFLOAT3(0.0f, 0.0f, 1.0f));
}

// Called once per frame, rotates the cube and calculates the model and view matrices.
void Genesis3DSceneRenderer::Update(DX::StepTimer const& timer)
{
	HandleInput(timer);
	HandleCameraInput(timer);

	m_camera->Update();
	XMVECTOR camEye = m_camera->EyeVec();
	XMMATRIX camView = m_camera->View();

	XMStoreFloat4x4(&m_MVPBufferData.view, XMMatrixTranspose(camView));
	XMStoreFloat4x4(&m_MVPBufferData.invView, XMMatrixTranspose(XMMatrixInverse(nullptr, camView)));

	m_starrySky->Update(timer, m_MVPBufferData);
	m_tessPlanet->Update(timer, m_MVPBufferData, camEye);
}

void Genesis3DSceneRenderer::HandleInput(DX::StepTimer const& timer)
{
	if (QueryKeyPressed(VirtualKey::Escape))
		CoreApplication::Exit();
}

void Genesis3DSceneRenderer::HandleCameraInput(DX::StepTimer const& timer)
{
	float speed = static_cast<float>(timer.GetElapsedSeconds());

	if (QueryKeyPressed(VirtualKey::W))
		m_camera->MoveZ(-speed);

	if (QueryKeyPressed(VirtualKey::S))
		m_camera->MoveZ(speed);

	if (QueryKeyPressed(VirtualKey::A))
		m_camera->MoveX(-speed);

	if (QueryKeyPressed(VirtualKey::D))
		m_camera->MoveX(speed);

	if (QueryKeyPressed(VirtualKey::Q))
		m_camera->MoveY(-speed);

	if (QueryKeyPressed(VirtualKey::E))
		m_camera->MoveY(speed);

	if (QueryKeyPressed(VirtualKey::Up))
		m_camera->RotateX(speed);

	if (QueryKeyPressed(VirtualKey::Down))
		m_camera->RotateX(-speed);

	if (QueryKeyPressed(VirtualKey::Left))
		m_camera->RotateY(speed);

	if (QueryKeyPressed(VirtualKey::Right))
		m_camera->RotateY(-speed);
}

bool Genesis3DSceneRenderer::QueryKeyPressed(VirtualKey key)
{
	return (CoreWindow::GetForCurrentThread()->GetKeyState(key) & CoreVirtualKeyStates::Down) == CoreVirtualKeyStates::Down;
}

void Genesis3DSceneRenderer::Render()
{
	m_starrySky->Render();
	m_tessPlanet->Render();
}

void Genesis3DSceneRenderer::CreateDeviceDependentResources()
{
	m_starrySky->CreateDeviceDependentResources();
	m_tessPlanet->CreateDeviceDependentResources();
}

void Genesis3DSceneRenderer::ReleaseDeviceDependentResources()
{
	m_starrySky->ReleaseDeviceDependentResources();
	m_tessPlanet->ReleaseDeviceDependentResources();
}