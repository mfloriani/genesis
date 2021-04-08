#include "pch.h"
#include "Genesis3DSceneRenderer.h"
#include "AssetManager.h"

#include "..\Common\DirectXHelper.h"

#include <iostream>

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
	
	AssetManager::Get().LoadTexture(deviceResources->GetD3DDevice(), "noise.dds", "noise");
	AssetManager::Get().LoadTexture(deviceResources->GetD3DDevice(), "noise2.dds", "noise2");
	AssetManager::Get().LoadTexture(deviceResources->GetD3DDevice(), "gray_noise_64.dds", "gray_noise_64");
	AssetManager::Get().LoadTexture(deviceResources->GetD3DDevice(), "gray_noise_256.dds", "gray_noise_256");
	AssetManager::Get().LoadTexture(deviceResources->GetD3DDevice(), "rgba_noise_64.dds", "rgba_noise_64");
	AssetManager::Get().LoadTexture(deviceResources->GetD3DDevice(), "rgba_noise_256.dds", "rgba_noise_256");

	m_camera = std::make_unique<Camera>();
	m_starrySky = std::make_unique<StarrySky>(deviceResources);
	m_tessPlanet = std::make_unique<TessPlanet>(deviceResources);
	m_pottery = std::make_unique<Pottery>(deviceResources);
	m_narrowStrip = std::make_unique<NarrowStrip>(deviceResources);
	m_rayTracing = std::make_unique<RayTracing>(deviceResources);
	m_implicitTerrain = std::make_unique<ImplicitTerrain>(deviceResources);
	m_rayMarching = std::make_unique<RayMarching>(deviceResources);
	m_rayMarchingSun = std::make_unique<RayMarchingSun>(deviceResources);
	m_rayMarchingGalaxy = std::make_unique<RayMarchingGalaxy>(deviceResources);

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

	m_camera->LookAt(XMFLOAT3(0.0f, 5.7f, 7.5f), XMFLOAT3(0.0f, 0.0f, 1.0f));
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
	m_pottery->Update(timer, m_MVPBufferData, camEye);
	m_narrowStrip->Update(timer, m_MVPBufferData, camEye);
	m_rayTracing->Update(timer, m_MVPBufferData, camEye);
	m_implicitTerrain->Update(timer, m_MVPBufferData, camEye);
	m_rayMarching->Update(timer, m_MVPBufferData, camEye);
	m_rayMarchingSun->Update(timer, m_MVPBufferData, camEye);
	m_rayMarchingGalaxy->Update(timer, m_MVPBufferData, camEye);
}

void Genesis3DSceneRenderer::HandleInput(DX::StepTimer const& timer)
{
	if (QueryKeyPressed(VirtualKey::Escape))
		CoreApplication::Exit();

	if (QueryKeyPressed(VirtualKey::F1))
		ToggleWireframeMode(true);

	if (QueryKeyPressed(VirtualKey::F2))
		ToggleWireframeMode(false);
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

void Genesis3DSceneRenderer::RenderToTexture()
{
	m_rayMarchingSun->RenderToTexture();
}

void Genesis3DSceneRenderer::Render()
{
	m_rayTracing->Render();
	m_rayMarching->Render();
	m_implicitTerrain->Render();	
	m_pottery->Render();
	m_narrowStrip->Render();
	m_starrySky->Render();
	m_tessPlanet->Render();
	m_rayMarchingSun->Render();



	//m_rayMarchingGalaxy->Render();
}

void Genesis::Genesis3DSceneRenderer::ToggleWireframeMode(bool onOff)
{
	m_tessPlanet->ToggleWireframeMode(onOff);
	m_pottery->ToggleWireframeMode(onOff);
	m_narrowStrip->ToggleWireframeMode(onOff);
}

void Genesis3DSceneRenderer::CreateDeviceDependentResources()
{
	m_starrySky->CreateDeviceDependentResources();
	m_tessPlanet->CreateDeviceDependentResources();
	m_pottery->CreateDeviceDependentResources();
	m_narrowStrip->CreateDeviceDependentResources();
	m_rayTracing->CreateDeviceDependentResources();
	m_implicitTerrain->CreateDeviceDependentResources();
	m_rayMarching->CreateDeviceDependentResources();
	m_rayMarchingSun->CreateDeviceDependentResources();
	m_rayMarchingGalaxy->CreateDeviceDependentResources();
}

void Genesis3DSceneRenderer::ReleaseDeviceDependentResources()
{
	m_starrySky->ReleaseDeviceDependentResources();
	m_tessPlanet->ReleaseDeviceDependentResources();
	m_pottery->ReleaseDeviceDependentResources();
	m_narrowStrip->ReleaseDeviceDependentResources();
	m_rayTracing->ReleaseDeviceDependentResources();
	m_implicitTerrain->ReleaseDeviceDependentResources();
	m_rayMarching->ReleaseDeviceDependentResources();
	m_rayMarchingSun->ReleaseDeviceDependentResources();
	m_rayMarchingGalaxy->ReleaseDeviceDependentResources();
}