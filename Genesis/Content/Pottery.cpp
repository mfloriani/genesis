#include "pch.h"
#include "Pottery.h"

#include "..\Common\DirectXHelper.h"

#include <array>
#include <cmath>
#include <iostream>
#include <fstream>

using namespace Genesis;
using namespace DirectX;

Pottery::Pottery(const std::shared_ptr<DX::DeviceResources>& deviceResources)
	: m_deviceResources(deviceResources), m_ready(false), m_indexCount(0), m_wireframe(false)
{
	// TODO: replace this fixed value
	m_transform.position = XMFLOAT3(0.0f, 0.0f, -10.0f);
	m_transform.scale = XMFLOAT3(1.0f, 1.0f, 3.0f);
	m_transform.rotation = XMFLOAT3(-1.57f, 0.0f, 0.0f);

}

Pottery::~Pottery()
{
}

void Pottery::CreateDeviceDependentResources()
{
	auto loadVSTask = DX::ReadDataAsync(L"PotteryVS.cso");
	auto loadHSTask = DX::ReadDataAsync(L"PotteryHS.cso");
	auto loadDSTask = DX::ReadDataAsync(L"PotteryDS.cso");
	auto loadPSTask = DX::ReadDataAsync(L"PotteryPS.cso");

	auto createVSTask = loadVSTask.then([this](const std::vector<byte>& fileData) {
		DX::ThrowIfFailed(
			m_deviceResources->GetD3DDevice()->CreateVertexShader(
				&fileData[0],
				fileData.size(),
				nullptr,
				&m_vertexShader
			)
		);

		static const D3D11_INPUT_ELEMENT_DESC vertexDesc[] =
		{
			{ "POSITION", 0, DXGI_FORMAT_R32G32B32_FLOAT, 0, 0, D3D11_INPUT_PER_VERTEX_DATA, 0 },
		};

		DX::ThrowIfFailed(
			m_deviceResources->GetD3DDevice()->CreateInputLayout(
				vertexDesc,
				ARRAYSIZE(vertexDesc),
				&fileData[0],
				fileData.size(),
				&m_inputLayout
			)
		);
	});

	auto createHSTask = loadHSTask.then([this](const std::vector<byte>& fileData) {
		DX::ThrowIfFailed(
			m_deviceResources->GetD3DDevice()->CreateHullShader(
				&fileData[0],
				fileData.size(),
				nullptr,
				&m_hullShader
			)
		);
	});

	auto createDSTask = loadDSTask.then([this](const std::vector<byte>& fileData) {
		DX::ThrowIfFailed(
			m_deviceResources->GetD3DDevice()->CreateDomainShader(
				&fileData[0],
				fileData.size(),
				nullptr,
				&m_domainShader
			)
		);
	});

	auto createPSTask = loadPSTask.then([this](const std::vector<byte>& fileData) {
		DX::ThrowIfFailed(
			m_deviceResources->GetD3DDevice()->CreatePixelShader(
				&fileData[0],
				fileData.size(),
				nullptr,
				&m_pixelShader
			)
		);
	});
		
	auto createPotteryTask = (createVSTask && createHSTask && createDSTask && createPSTask).then([this]() {

		std::vector<VertexPosition> vertices = {

			// rim: [0,192]
{XMFLOAT3(0,-1.4,2.4)},
{XMFLOAT3(0.784,-1.4,2.4)},
{XMFLOAT3(1.4,-0.784,2.4)},
{XMFLOAT3(1.4,0,2.4)},
{XMFLOAT3(0,-1.3375,2.53125)},
{XMFLOAT3(0.749,-1.3375,2.53125)},
{XMFLOAT3(1.3375,-0.749,2.53125)},
{XMFLOAT3(1.3375,0,2.53125)},
{XMFLOAT3(0,-1.4375,2.53125)},
{XMFLOAT3(0.805,-1.4375,2.53125)},
{XMFLOAT3(1.4375,-0.805,2.53125)},
{XMFLOAT3(1.4375,0,2.53125)},
{XMFLOAT3(0,-1.5,2.4)},
{XMFLOAT3(0.84,-1.5,2.4)},
{XMFLOAT3(1.5,-0.84,2.4)},
{XMFLOAT3(1.5,0,2.4)},
{XMFLOAT3(-1.4,0,2.4)},
{XMFLOAT3(-1.4,-0.784,2.4)},
{XMFLOAT3(-0.784,-1.4,2.4)},
{XMFLOAT3(0,-1.4,2.4)},
{XMFLOAT3(-1.3375,0,2.53125)},
{XMFLOAT3(-1.3375,-0.749,2.53125)},
{XMFLOAT3(-0.749,-1.3375,2.53125)},
{XMFLOAT3(0,-1.3375,2.53125)},
{XMFLOAT3(-1.4375,0,2.53125)},
{XMFLOAT3(-1.4375,-0.805,2.53125)},
{XMFLOAT3(-0.805,-1.4375,2.53125)},
{XMFLOAT3(0,-1.4375,2.53125)},
{XMFLOAT3(-1.5,0,2.4)},
{XMFLOAT3(-1.5,-0.84,2.4)},
{XMFLOAT3(-0.84,-1.5,2.4)},
{XMFLOAT3(0,-1.5,2.4)},
{XMFLOAT3(1.4,0,2.4)},
{XMFLOAT3(1.4,0.784,2.4)},
{XMFLOAT3(0.784,1.4,2.4)},
{XMFLOAT3(0,1.4,2.4)},
{XMFLOAT3(1.3375,0,2.53125)},
{XMFLOAT3(1.3375,0.749,2.53125)},
{XMFLOAT3(0.749,1.3375,2.53125)},
{XMFLOAT3(0,1.3375,2.53125)},
{XMFLOAT3(1.4375,0,2.53125)},
{XMFLOAT3(1.4375,0.805,2.53125)},
{XMFLOAT3(0.805,1.4375,2.53125)},
{XMFLOAT3(0,1.4375,2.53125)},
{XMFLOAT3(1.5,0,2.4)},
{XMFLOAT3(1.5,0.84,2.4)},
{XMFLOAT3(0.84,1.5,2.4)},
{XMFLOAT3(0,1.5,2.4)},
{XMFLOAT3(0,1.4,2.4)},
{XMFLOAT3(-0.784,1.4,2.4)},
{XMFLOAT3(-1.4,0.784,2.4)},
{XMFLOAT3(-1.4,0,2.4)},
{XMFLOAT3(0,1.3375,2.53125)},
{XMFLOAT3(-0.749,1.3375,2.53125)},
{XMFLOAT3(-1.3375,0.749,2.53125)},
{XMFLOAT3(-1.3375,0,2.53125)},
{XMFLOAT3(0,1.4375,2.53125)},
{XMFLOAT3(-0.805,1.4375,2.53125)},
{XMFLOAT3(-1.4375,0.805,2.53125)},
{XMFLOAT3(-1.4375,0,2.53125)},
{XMFLOAT3(0,1.5,2.4)},
{XMFLOAT3(-0.84,1.5,2.4)},
{XMFLOAT3(-1.5,0.84,2.4)},
{XMFLOAT3(-1.5,0,2.4)},

// body: [192,576]
{XMFLOAT3(0,-1.5,2.4)},
{XMFLOAT3(0.84,-1.5,2.4)},
{XMFLOAT3(1.5,-0.84,2.4)},
{XMFLOAT3(1.5,0,2.4)},
{XMFLOAT3(0,-1.75,1.875)},
{XMFLOAT3(0.98,-1.75,1.875)},
{XMFLOAT3(1.75,-0.98,1.875)},
{XMFLOAT3(1.75,0,1.875)},
{XMFLOAT3(0,-2,1.35)},
{XMFLOAT3(1.12,-2,1.35)},
{XMFLOAT3(2,-1.12,1.35)},
{XMFLOAT3(2,0,1.35)},
{XMFLOAT3(0,-2,0.9)},
{XMFLOAT3(1.12,-2,0.9)},
{XMFLOAT3(2,-1.12,0.9)},
{XMFLOAT3(2,0,0.9)},
{XMFLOAT3(-1.5,0,2.4)},
{XMFLOAT3(-1.5,-0.84,2.4)},
{XMFLOAT3(-0.84,-1.5,2.4)},
{XMFLOAT3(0,-1.5,2.4)},
{XMFLOAT3(-1.75,0,1.875)},
{XMFLOAT3(-1.75,-0.98,1.875)},
{XMFLOAT3(-0.98,-1.75,1.875)},
{XMFLOAT3(0,-1.75,1.875)},
{XMFLOAT3(-2,0,1.35)},
{XMFLOAT3(-2,-1.12,1.35)},
{XMFLOAT3(-1.12,-2,1.35)},
{XMFLOAT3(0,-2,1.35)},
{XMFLOAT3(-2,0,0.9)},
{XMFLOAT3(-2,-1.12,0.9)},
{XMFLOAT3(-1.12,-2,0.9)},
{XMFLOAT3(0,-2,0.9)},
{XMFLOAT3(1.5,0,2.4)},
{XMFLOAT3(1.5,0.84,2.4)},
{XMFLOAT3(0.84,1.5,2.4)},
{XMFLOAT3(0,1.5,2.4)},
{XMFLOAT3(1.75,0,1.875)},
{XMFLOAT3(1.75,0.98,1.875)},
{XMFLOAT3(0.98,1.75,1.875)},
{XMFLOAT3(0,1.75,1.875)},
{XMFLOAT3(2,0,1.35)},
{XMFLOAT3(2,1.12,1.35)},
{XMFLOAT3(1.12,2,1.35)},
{XMFLOAT3(0,2,1.35)},
{XMFLOAT3(2,0,0.9)},
{XMFLOAT3(2,1.12,0.9)},
{XMFLOAT3(1.12,2,0.9)},
{XMFLOAT3(0,2,0.9)},
{XMFLOAT3(0,1.5,2.4)},
{XMFLOAT3(-0.84,1.5,2.4)},
{XMFLOAT3(-1.5,0.84,2.4)},
{XMFLOAT3(-1.5,0,2.4)},
{XMFLOAT3(0,1.75,1.875)},
{XMFLOAT3(-0.98,1.75,1.875)},
{XMFLOAT3(-1.75,0.98,1.875)},
{XMFLOAT3(-1.75,0,1.875)},
{XMFLOAT3(0,2,1.35)},
{XMFLOAT3(-1.12,2,1.35)},
{XMFLOAT3(-2,1.12,1.35)},
{XMFLOAT3(-2,0,1.35)},
{XMFLOAT3(0,2,0.9)},
{XMFLOAT3(-1.12,2,0.9)},
{XMFLOAT3(-2,1.12,0.9)},
{XMFLOAT3(-2,0,0.9)},
{XMFLOAT3(0,-2,0.9)},
{XMFLOAT3(1.12,-2,0.9)},
{XMFLOAT3(2,-1.12,0.9)},
{XMFLOAT3(2,0,0.9)},
{XMFLOAT3(0,-2,0.45)},
{XMFLOAT3(1.12,-2,0.45)},
{XMFLOAT3(2,-1.12,0.45)},
{XMFLOAT3(2,0,0.45)},
{XMFLOAT3(0,-1.5,0.225)},
{XMFLOAT3(0.84,-1.5,0.225)},
{XMFLOAT3(1.5,-0.84,0.225)},
{XMFLOAT3(1.5,0,0.225)},
{XMFLOAT3(0,-1.5,0.15)},
{XMFLOAT3(0.84,-1.5,0.15)},
{XMFLOAT3(1.5,-0.84,0.15)},
{XMFLOAT3(1.5,0,0.15)},
{XMFLOAT3(-2,0,0.9)},
{XMFLOAT3(-2,-1.12,0.9)},
{XMFLOAT3(-1.12,-2,0.9)},
{XMFLOAT3(0,-2,0.9)},
{XMFLOAT3(-2,0,0.45)},
{XMFLOAT3(-2,-1.12,0.45)},
{XMFLOAT3(-1.12,-2,0.45)},
{XMFLOAT3(0,-2,0.45)},
{XMFLOAT3(-1.5,0,0.225)},
{XMFLOAT3(-1.5,-0.84,0.225)},
{XMFLOAT3(-0.84,-1.5,0.225)},
{XMFLOAT3(0,-1.5,0.225)},
{XMFLOAT3(-1.5,0,0.15)},
{XMFLOAT3(-1.5,-0.84,0.15)},
{XMFLOAT3(-0.84,-1.5,0.15)},
{XMFLOAT3(0,-1.5,0.15)},
{XMFLOAT3(2,0,0.9)},
{XMFLOAT3(2,1.12,0.9)},
{XMFLOAT3(1.12,2,0.9)},
{XMFLOAT3(0,2,0.9)},
{XMFLOAT3(2,0,0.45)},
{XMFLOAT3(2,1.12,0.45)},
{XMFLOAT3(1.12,2,0.45)},
{XMFLOAT3(0,2,0.45)},
{XMFLOAT3(1.5,0,0.225)},
{XMFLOAT3(1.5,0.84,0.225)},
{XMFLOAT3(0.84,1.5,0.225)},
{XMFLOAT3(0,1.5,0.225)},
{XMFLOAT3(1.5,0,0.15)},
{XMFLOAT3(1.5,0.84,0.15)},
{XMFLOAT3(0.84,1.5,0.15)},
{XMFLOAT3(0,1.5,0.15)},
{XMFLOAT3(0,2,0.9)},
{XMFLOAT3(-1.12,2,0.9)},
{XMFLOAT3(-2,1.12,0.9)},
{XMFLOAT3(-2,0,0.9)},
{XMFLOAT3(0,2,0.45)},
{XMFLOAT3(-1.12,2,0.45)},
{XMFLOAT3(-2,1.12,0.45)},
{XMFLOAT3(-2,0,0.45)},
{XMFLOAT3(0,1.5,0.225)},
{XMFLOAT3(-0.84,1.5,0.225)},
{XMFLOAT3(-1.5,0.84,0.225)},
{XMFLOAT3(-1.5,0,0.225)},
{XMFLOAT3(0,1.5,0.15)},
{XMFLOAT3(-0.84,1.5,0.15)},
{XMFLOAT3(-1.5,0.84,0.15)},
{XMFLOAT3(-1.5,0,0.15)},

// lid: [576,960]
//{XMFLOAT3(0,0,3.15)},
//{XMFLOAT3(0,0,3.15)},
//{XMFLOAT3(0,0,3.15)},
//{XMFLOAT3(0,0,3.15)},
//{XMFLOAT3(0,-0.8,3.15)},
//{XMFLOAT3(0.45,-0.8,3.15)},
//{XMFLOAT3(0.8,-0.45,3.15)},
//{XMFLOAT3(0.8,0,3.15)},
//{XMFLOAT3(0,0,2.85)},
//{XMFLOAT3(0,0,2.85)},
//{XMFLOAT3(0,0,2.85)},
//{XMFLOAT3(0,0,2.85)},
//{XMFLOAT3(0,-0.2,2.7)},
//{XMFLOAT3(0.112,-0.2,2.7)},
//{XMFLOAT3(0.2,-0.112,2.7)},
//{XMFLOAT3(0.2,0,2.7)},
//{XMFLOAT3(0,0,3.15)},
//{XMFLOAT3(0,0,3.15)},
//{XMFLOAT3(0,0,3.15)},
//{XMFLOAT3(0,0,3.15)},
//{XMFLOAT3(-0.8,0,3.15)},
//{XMFLOAT3(-0.8,-0.45,3.15)},
//{XMFLOAT3(-0.45,-0.8,3.15)},
//{XMFLOAT3(0,-0.8,3.15)},
//{XMFLOAT3(0,0,2.85)},
//{XMFLOAT3(0,0,2.85)},
//{XMFLOAT3(0,0,2.85)},
//{XMFLOAT3(0,0,2.85)},
//{XMFLOAT3(-0.2,0,2.7)},
//{XMFLOAT3(-0.2,-0.112,2.7)},
//{XMFLOAT3(-0.112,-0.2,2.7)},
//{XMFLOAT3(0,-0.2,2.7)},
//{XMFLOAT3(0,0,3.15)},
//{XMFLOAT3(0,0,3.15)},
//{XMFLOAT3(0,0,3.15)},
//{XMFLOAT3(0,0,3.15)},
//{XMFLOAT3(0.8,0,3.15)},
//{XMFLOAT3(0.8,0.45,3.15)},
//{XMFLOAT3(0.45,0.8,3.15)},
//{XMFLOAT3(0,0.8,3.15)},
//{XMFLOAT3(0,0,2.85)},
//{XMFLOAT3(0,0,2.85)},
//{XMFLOAT3(0,0,2.85)},
//{XMFLOAT3(0,0,2.85)},
//{XMFLOAT3(0.2,0,2.7)},
//{XMFLOAT3(0.2,0.112,2.7)},
//{XMFLOAT3(0.112,0.2,2.7)},
//{XMFLOAT3(0,0.2,2.7)},
//{XMFLOAT3(0,0,3.15)},
//{XMFLOAT3(0,0,3.15)},
//{XMFLOAT3(0,0,3.15)},
//{XMFLOAT3(0,0,3.15)},
//{XMFLOAT3(0,0.8,3.15)},
//{XMFLOAT3(-0.45,0.8,3.15)},
//{XMFLOAT3(-0.8,0.45,3.15)},
//{XMFLOAT3(-0.8,0,3.15)},
//{XMFLOAT3(0,0,2.85)},
//{XMFLOAT3(0,0,2.85)},
//{XMFLOAT3(0,0,2.85)},
//{XMFLOAT3(0,0,2.85)},
//{XMFLOAT3(0,0.2,2.7)},
//{XMFLOAT3(-0.112,0.2,2.7)},
//{XMFLOAT3(-0.2,0.112,2.7)},
//{XMFLOAT3(-0.2,0,2.7)},
//{XMFLOAT3(0,-0.2,2.7)},
//{XMFLOAT3(0.112,-0.2,2.7)},
//{XMFLOAT3(0.2,-0.112,2.7)},
//{XMFLOAT3(0.2,0,2.7)},
//{XMFLOAT3(0,-0.4,2.55)},
//{XMFLOAT3(0.224,-0.4,2.55)},
//{XMFLOAT3(0.4,-0.224,2.55)},
//{XMFLOAT3(0.4,0,2.55)},
//{XMFLOAT3(0,-1.3,2.55)},
//{XMFLOAT3(0.728,-1.3,2.55)},
//{XMFLOAT3(1.3,-0.728,2.55)},
//{XMFLOAT3(1.3,0,2.55)},
//{XMFLOAT3(0,-1.3,2.4)},
//{XMFLOAT3(0.728,-1.3,2.4)},
//{XMFLOAT3(1.3,-0.728,2.4)},
//{XMFLOAT3(1.3,0,2.4)},
//{XMFLOAT3(-0.2,0,2.7)},
//{XMFLOAT3(-0.2,-0.112,2.7)},
//{XMFLOAT3(-0.112,-0.2,2.7)},
//{XMFLOAT3(0,-0.2,2.7)},
//{XMFLOAT3(-0.4,0,2.55)},
//{XMFLOAT3(-0.4,-0.224,2.55)},
//{XMFLOAT3(-0.224,-0.4,2.55)},
//{XMFLOAT3(0,-0.4,2.55)},
//{XMFLOAT3(-1.3,0,2.55)},
//{XMFLOAT3(-1.3,-0.728,2.55)},
//{XMFLOAT3(-0.728,-1.3,2.55)},
//{XMFLOAT3(0,-1.3,2.55)},
//{XMFLOAT3(-1.3,0,2.4)},
//{XMFLOAT3(-1.3,-0.728,2.4)},
//{XMFLOAT3(-0.728,-1.3,2.4)},
//{XMFLOAT3(0,-1.3,2.4)},
//{XMFLOAT3(0.2,0,2.7)},
//{XMFLOAT3(0.2,0.112,2.7)},
//{XMFLOAT3(0.112,0.2,2.7)},
//{XMFLOAT3(0,0.2,2.7)},
//{XMFLOAT3(0.4,0,2.55)},
//{XMFLOAT3(0.4,0.224,2.55)},
//{XMFLOAT3(0.224,0.4,2.55)},
//{XMFLOAT3(0,0.4,2.55)},
//{XMFLOAT3(1.3,0,2.55)},
//{XMFLOAT3(1.3,0.728,2.55)},
//{XMFLOAT3(0.728,1.3,2.55)},
//{XMFLOAT3(0,1.3,2.55)},
//{XMFLOAT3(1.3,0,2.4)},
//{XMFLOAT3(1.3,0.728,2.4)},
//{XMFLOAT3(0.728,1.3,2.4)},
//{XMFLOAT3(0,1.3,2.4)},
//{XMFLOAT3(0,0.2,2.7)},
//{XMFLOAT3(-0.112,0.2,2.7)},
//{XMFLOAT3(-0.2,0.112,2.7)},
//{XMFLOAT3(-0.2,0,2.7)},
//{XMFLOAT3(0,0.4,2.55)},
//{XMFLOAT3(-0.224,0.4,2.55)},
//{XMFLOAT3(-0.4,0.224,2.55)},
//{XMFLOAT3(-0.4,0,2.55)},
//{XMFLOAT3(0,1.3,2.55)},
//{XMFLOAT3(-0.728,1.3,2.55)},
//{XMFLOAT3(-1.3,0.728,2.55)},
//{XMFLOAT3(-1.3,0,2.55)},
//{XMFLOAT3(0,1.3,2.4)},
//{XMFLOAT3(-0.728,1.3,2.4)},
//{XMFLOAT3(-1.3,0.728,2.4)},
//{XMFLOAT3(-1.3,0,2.4)},

// bottom: [960,1152]
{XMFLOAT3(0,0,0)},
{XMFLOAT3(0,0,0)},
{XMFLOAT3(0,0,0)},
{XMFLOAT3(0,0,0)},
{XMFLOAT3(1.425,0,0)},
{XMFLOAT3(1.425,-0.798,0)},
{XMFLOAT3(0.798,-1.425,0)},
{XMFLOAT3(0,-1.425,0)},
{XMFLOAT3(1.5,0,0.075)},
{XMFLOAT3(1.5,-0.84,0.075)},
{XMFLOAT3(0.84,-1.5,0.075)},
{XMFLOAT3(0,-1.5,0.075)},
{XMFLOAT3(1.5,0,0.15)},
{XMFLOAT3(1.5,-0.84,0.15)},
{XMFLOAT3(0.84,-1.5,0.15)},
{XMFLOAT3(0,-1.5,0.15)},
{XMFLOAT3(0,0,0)},
{XMFLOAT3(0,0,0)},
{XMFLOAT3(0,0,0)},
{XMFLOAT3(0,0,0)},
{XMFLOAT3(0,-1.425,0)},
{XMFLOAT3(-0.798,-1.425,0)},
{XMFLOAT3(-1.425,-0.798,0)},
{XMFLOAT3(-1.425,0,0)},
{XMFLOAT3(0,-1.5,0.075)},
{XMFLOAT3(-0.84,-1.5,0.075)},
{XMFLOAT3(-1.5,-0.84,0.075)},
{XMFLOAT3(-1.5,0,0.075)},
{XMFLOAT3(0,-1.5,0.15)},
{XMFLOAT3(-0.84,-1.5,0.15)},
{XMFLOAT3(-1.5,-0.84,0.15)},
{XMFLOAT3(-1.5,0,0.15)},
{XMFLOAT3(0,0,0)},
{XMFLOAT3(0,0,0)},
{XMFLOAT3(0,0,0)},
{XMFLOAT3(0,0,0)},
{XMFLOAT3(0,1.425,0)},
{XMFLOAT3(0.798,1.425,0)},
{XMFLOAT3(1.425,0.798,0)},
{XMFLOAT3(1.425,0,0)},
{XMFLOAT3(0,1.5,0.075)},
{XMFLOAT3(0.84,1.5,0.075)},
{XMFLOAT3(1.5,0.84,0.075)},
{XMFLOAT3(1.5,0,0.075)},
{XMFLOAT3(0,1.5,0.15)},
{XMFLOAT3(0.84,1.5,0.15)},
{XMFLOAT3(1.5,0.84,0.15)},
{XMFLOAT3(1.5,0,0.15)},
{XMFLOAT3(0,0,0)},
{XMFLOAT3(0,0,0)},
{XMFLOAT3(0,0,0)},
{XMFLOAT3(0,0,0)},
{XMFLOAT3(-1.425,0,0)},
{XMFLOAT3(-1.425,0.798,0)},
{XMFLOAT3(-0.798,1.425,0)},
{XMFLOAT3(0,1.425,0)},
{XMFLOAT3(-1.5,0,0.075)},
{XMFLOAT3(-1.5,0.84,0.075)},
{XMFLOAT3(-0.84,1.5,0.075)},
{XMFLOAT3(0,1.5,0.075)},
{XMFLOAT3(-1.5,0,0.15)},
{XMFLOAT3(-1.5,0.84,0.15)},
{XMFLOAT3(-0.84,1.5,0.15)},
{XMFLOAT3(0,1.5,0.15)},

// handle: [1152,1344]
{XMFLOAT3(-1.5,0,2.25)},
{XMFLOAT3(-1.5,-0.3,2.25)},
{XMFLOAT3(-1.6,-0.3,2.025)},
{XMFLOAT3(-1.6,0,2.025)},
{XMFLOAT3(-2.5,0,2.25)},
{XMFLOAT3(-2.5,-0.3,2.25)},
{XMFLOAT3(-2.3,-0.3,2.025)},
{XMFLOAT3(-2.3,0,2.025)},
{XMFLOAT3(-3,0,2.25)},
{XMFLOAT3(-3,-0.3,2.25)},
{XMFLOAT3(-2.7,-0.3,2.025)},
{XMFLOAT3(-2.7,0,2.025)},
{XMFLOAT3(-3,0,1.8)},
{XMFLOAT3(-3,-0.3,1.8)},
{XMFLOAT3(-2.7,-0.3,1.8)},
{XMFLOAT3(-2.7,0,1.8)},
{XMFLOAT3(-1.6,0,2.025)},
{XMFLOAT3(-1.6,0.3,2.025)},
{XMFLOAT3(-1.5,0.3,2.25)},
{XMFLOAT3(-1.5,0,2.25)},
{XMFLOAT3(-2.3,0,2.025)},
{XMFLOAT3(-2.3,0.3,2.025)},
{XMFLOAT3(-2.5,0.3,2.25)},
{XMFLOAT3(-2.5,0,2.25)},
{XMFLOAT3(-2.7,0,2.025)},
{XMFLOAT3(-2.7,0.3,2.025)},
{XMFLOAT3(-3,0.3,2.25)},
{XMFLOAT3(-3,0,2.25)},
{XMFLOAT3(-2.7,0,1.8)},
{XMFLOAT3(-2.7,0.3,1.8)},
{XMFLOAT3(-3,0.3,1.8)},
{XMFLOAT3(-3,0,1.8)},
{XMFLOAT3(-3,0,1.8)},
{XMFLOAT3(-3,-0.3,1.8)},
{XMFLOAT3(-2.7,-0.3,1.8)},
{XMFLOAT3(-2.7,0,1.8)},
{XMFLOAT3(-3,0,1.35)},
{XMFLOAT3(-3,-0.3,1.35)},
{XMFLOAT3(-2.7,-0.3,1.575)},
{XMFLOAT3(-2.7,0,1.575)},
{XMFLOAT3(-2.65,0,0.9375)},
{XMFLOAT3(-2.65,-0.3,0.9375)},
{XMFLOAT3(-2.5,-0.3,1.125)},
{XMFLOAT3(-2.5,0,1.125)},
{XMFLOAT3(-1.9,0,0.6)},
{XMFLOAT3(-1.9,-0.3,0.6)},
{XMFLOAT3(-2,-0.3,0.9)},
{XMFLOAT3(-2,0,0.9)},
{XMFLOAT3(-2.7,0,1.8)},
{XMFLOAT3(-2.7,0.3,1.8)},
{XMFLOAT3(-3,0.3,1.8)},
{XMFLOAT3(-3,0,1.8)},
{XMFLOAT3(-2.7,0,1.575)},
{XMFLOAT3(-2.7,0.3,1.575)},
{XMFLOAT3(-3,0.3,1.35)},
{XMFLOAT3(-3,0,1.35)},
{XMFLOAT3(-2.5,0,1.125)},
{XMFLOAT3(-2.5,0.3,1.125)},
{XMFLOAT3(-2.65,0.3,0.9375)},
{XMFLOAT3(-2.65,0,0.9375)},
{XMFLOAT3(-2,0,0.9)},
{XMFLOAT3(-2,0.3,0.9)},
{XMFLOAT3(-1.9,0.3,0.6)},
{XMFLOAT3(-1.9,0,0.6)},

// spout: [1344,1536]
//{XMFLOAT3(1.7,0,0.6)},
//{XMFLOAT3(1.7,-0.66,0.6)},
//{XMFLOAT3(1.7,-0.66,1.425)},
//{XMFLOAT3(1.7,0,1.425)},
//{XMFLOAT3(3.1,0,0.825)},
//{XMFLOAT3(3.1,-0.66,0.825)},
//{XMFLOAT3(2.6,-0.66,1.425)},
//{XMFLOAT3(2.6,0,1.425)},
//{XMFLOAT3(2.4,0,2.025)},
//{XMFLOAT3(2.4,-0.25,2.025)},
//{XMFLOAT3(2.3,-0.25,2.1)},
//{XMFLOAT3(2.3,0,2.1)},
//{XMFLOAT3(3.3,0,2.4)},
//{XMFLOAT3(3.3,-0.25,2.4)},
//{XMFLOAT3(2.7,-0.25,2.4)},
//{XMFLOAT3(2.7,0,2.4)},
//{XMFLOAT3(1.7,0,1.425)},
//{XMFLOAT3(1.7,0.66,1.425)},
//{XMFLOAT3(1.7,0.66,0.6)},
//{XMFLOAT3(1.7,0,0.6)},
//{XMFLOAT3(2.6,0,1.425)},
//{XMFLOAT3(2.6,0.66,1.425)},
//{XMFLOAT3(3.1,0.66,0.825)},
//{XMFLOAT3(3.1,0,0.825)},
//{XMFLOAT3(2.3,0,2.1)},
//{XMFLOAT3(2.3,0.25,2.1)},
//{XMFLOAT3(2.4,0.25,2.025)},
//{XMFLOAT3(2.4,0,2.025)},
//{XMFLOAT3(2.7,0,2.4)},
//{XMFLOAT3(2.7,0.25,2.4)},
//{XMFLOAT3(3.3,0.25,2.4)},
//{XMFLOAT3(3.3,0,2.4)},
//{XMFLOAT3(3.3,0,2.4)},
//{XMFLOAT3(3.3,-0.25,2.4)},
//{XMFLOAT3(2.7,-0.25,2.4)},
//{XMFLOAT3(2.7,0,2.4)},
//{XMFLOAT3(3.525,0,2.49375)},
//{XMFLOAT3(3.525,-0.25,2.49375)},
//{XMFLOAT3(2.8,-0.25,2.475)},
//{XMFLOAT3(2.8,0,2.475)},
//{XMFLOAT3(3.45,0,2.5125)},
//{XMFLOAT3(3.45,-0.15,2.5125)},
//{XMFLOAT3(2.9,-0.15,2.475)},
//{XMFLOAT3(2.9,0,2.475)},
//{XMFLOAT3(3.2,0,2.4)},
//{XMFLOAT3(3.2,-0.15,2.4)},
//{XMFLOAT3(2.8,-0.15,2.4)},
//{XMFLOAT3(2.8,0,2.4)},
//{XMFLOAT3(2.7,0,2.4)},
//{XMFLOAT3(2.7,0.25,2.4)},
//{XMFLOAT3(3.3,0.25,2.4)},
//{XMFLOAT3(3.3,0,2.4)},
//{XMFLOAT3(2.8,0,2.475)},
//{XMFLOAT3(2.8,0.25,2.475)},
//{XMFLOAT3(3.525,0.25,2.49375)},
//{XMFLOAT3(3.525,0,2.49375)},
//{XMFLOAT3(2.9,0,2.475)},
//{XMFLOAT3(2.9,0.15,2.475)},
//{XMFLOAT3(3.45,0.15,2.5125)},
//{XMFLOAT3(3.45,0,2.5125)},
//{XMFLOAT3(2.8,0,2.4)},
//{XMFLOAT3(2.8,0.15,2.4)},
//{XMFLOAT3(3.2,0.15,2.4)},
//{XMFLOAT3(3.2,0,2.4)},


		};


		m_indexCount = vertices.size();
		
		
		
		// LH to RH
		//for (auto& v : vertices)
		//	v.positon.z *= -1;

		//std::vector<unsigned int> indices =
		//{
		//	// rim
		//	102, 103, 104, 105, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15,

		//	// body
		//	12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27,
		//	24, 25, 26, 27, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40,

		//	// lid
		//	//96, 96, 96, 96, 97, 98, 99, 100, 101, 101, 101, 101, 0, 1, 2, 3,
		//	//0, 1, 2, 3, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117,
		//	
		//	// bottom
		//	118, 118, 118, 118, 124, 122, 119, 121, 123, 126, 125, 120, 40, 39, 38, 37,
		//	
		//	// handle
		//	41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56,
		//	53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 28, 65, 66, 67,
		//	
		//	// spout
		//	//68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83,
		//	//80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95

		//};
		//m_indexCount = indices.size();


		D3D11_SUBRESOURCE_DATA vertexBufferData = { 0 };
		vertexBufferData.pSysMem = vertices.data();
		vertexBufferData.SysMemPitch = 0;
		vertexBufferData.SysMemSlicePitch = 0;

		CD3D11_BUFFER_DESC vertexBufferDesc(
			sizeof(VertexPosition) * vertices.size(),
			D3D11_BIND_VERTEX_BUFFER
		);

		DX::ThrowIfFailed(
			m_deviceResources->GetD3DDevice()->CreateBuffer(
				&vertexBufferDesc,
				&vertexBufferData,
				&m_vertexBuffer
			)
		);


		//D3D11_SUBRESOURCE_DATA indexData;
		//indexData.pSysMem = indices.data();
		//indexData.SysMemPitch = 0;
		//indexData.SysMemSlicePitch = 0;

		//CD3D11_BUFFER_DESC indexBufferDesc(
		//	sizeof(unsigned int) * m_indexCount,
		//	D3D11_BIND_INDEX_BUFFER
		//);

		//DX::ThrowIfFailed(
		//	m_deviceResources->GetD3DDevice()->CreateBuffer(
		//		&indexBufferDesc,
		//		&indexData,
		//		&m_indexBuffer
		//	)
		//);



		CD3D11_BUFFER_DESC constantBufferDesc(sizeof(ModelViewProjCB), D3D11_BIND_CONSTANT_BUFFER);
		DX::ThrowIfFailed(
			m_deviceResources->GetD3DDevice()->CreateBuffer(
				&constantBufferDesc,
				nullptr,
				&m_MVPBuffer
			)
		);

		CD3D11_BUFFER_DESC constantBufferDesc2(sizeof(CameraCB), D3D11_BIND_CONSTANT_BUFFER);
		DX::ThrowIfFailed(
			m_deviceResources->GetD3DDevice()->CreateBuffer(
				&constantBufferDesc2,
				nullptr,
				&m_cameraBuffer
			)
		);

		CD3D11_BUFFER_DESC constantBufferDesc3(sizeof(ObjectCB), D3D11_BIND_CONSTANT_BUFFER);
		DX::ThrowIfFailed(
			m_deviceResources->GetD3DDevice()->CreateBuffer(
				&constantBufferDesc3,
				nullptr,
				&m_objectBuffer
			)
		);

		ToggleWireframeMode(false);
	});

	createPotteryTask.then([this]() {

		m_ready = true;
	});

}

void Pottery::ReleaseDeviceDependentResources()
{
	m_ready = false;
	m_vertexShader.Reset();
	m_inputLayout.Reset();
	m_pixelShader.Reset();
	m_MVPBuffer.Reset();
	m_cameraBuffer.Reset();
	m_objectBuffer.Reset();
	m_vertexBuffer.Reset();
	m_hullShader.Reset();
	m_domainShader.Reset();
	m_rasterizerState.Reset();
}

void Pottery::Update(DX::StepTimer const& timer, ModelViewProjCB& mvp, XMVECTOR& camPos)
{
	auto model = XMMatrixIdentity();

	//m_transform.rotation.x += -0.05f * static_cast<float>(timer.GetElapsedSeconds());
	//m_transform.rotation.y += 0.1f * static_cast<float>(timer.GetElapsedSeconds());

	model = XMMatrixMultiply(model, DirectX::XMMatrixScaling(m_transform.scale.x, m_transform.scale.y, m_transform.scale.z));
	model = XMMatrixMultiply(
		model,
		DirectX::XMMatrixRotationQuaternion(
			DirectX::XMQuaternionRotationRollPitchYaw(
				m_transform.rotation.x, m_transform.rotation.y, m_transform.rotation.z)
		)
	);
	model = XMMatrixMultiply(model, DirectX::XMMatrixTranslation(m_transform.position.x, m_transform.position.y, m_transform.position.z));


	XMStoreFloat4x4(&m_MVPBufferData.model, XMMatrixTranspose(model));
	m_MVPBufferData.view = mvp.view;
	m_MVPBufferData.projection = mvp.projection;
	m_MVPBufferData.invView = mvp.invView;

	XMStoreFloat4(&m_cameraBufferData.cameraPos, camPos);

	XMStoreFloat4(&m_objectBufferData.positionW, XMLoadFloat3(&m_transform.position));
}

void Pottery::Render()
{
	if (!m_ready) return;

	auto context = m_deviceResources->GetD3DDeviceContext();

	// Prepare the constant buffer to send it to the graphics device.
	context->UpdateSubresource1(
		m_MVPBuffer.Get(),
		0,
		NULL,
		&m_MVPBufferData,
		0,
		0,
		0
	);

	context->UpdateSubresource1(
		m_cameraBuffer.Get(),
		0,
		NULL,
		&m_cameraBufferData,
		0,
		0,
		0
	);

	context->UpdateSubresource1(
		m_objectBuffer.Get(),
		0,
		NULL,
		&m_objectBufferData,
		0,
		0,
		0
	);

	// Each vertex is one instance of the VertexPositionColor struct.
	UINT stride = sizeof(VertexPosition);
	UINT offset = 0;
	context->IASetVertexBuffers(
		0,
		1,
		m_vertexBuffer.GetAddressOf(),
		&stride,
		&offset
	);

	context->IASetIndexBuffer(
		m_indexBuffer.Get(),
		DXGI_FORMAT_R32_UINT,
		0
	);

	context->IASetPrimitiveTopology(D3D11_PRIMITIVE_TOPOLOGY_16_CONTROL_POINT_PATCHLIST);
	context->IASetInputLayout(m_inputLayout.Get());

	// Attach our vertex shader.
	context->VSSetShader(
		m_vertexShader.Get(),
		nullptr,
		0
	);

	// Send the constant buffer to the graphics device.
	context->VSSetConstantBuffers1(
		0,
		1,
		m_MVPBuffer.GetAddressOf(),
		nullptr,
		nullptr
	);

	context->VSSetConstantBuffers1(
		1,
		1,
		m_cameraBuffer.GetAddressOf(),
		nullptr,
		nullptr
	);

	context->VSSetConstantBuffers1(
		2,
		1,
		m_objectBuffer.GetAddressOf(),
		nullptr,
		nullptr
	);

	context->HSSetShader(
		m_hullShader.Get(),
		nullptr,
		0
	);

	context->DSSetShader(
		m_domainShader.Get(),
		nullptr,
		0
	);

	context->DSSetConstantBuffers1(
		0,
		1,
		m_MVPBuffer.GetAddressOf(),
		nullptr,
		nullptr
	);

	context->DSSetConstantBuffers1(
		1,
		1,
		m_cameraBuffer.GetAddressOf(),
		nullptr,
		nullptr
	);

	context->GSSetShader(
		nullptr,
		nullptr,
		0
	);


	context->RSSetState(m_rasterizerState.Get());

	// Attach our pixel shader.
	context->PSSetShader(
		m_pixelShader.Get(),
		nullptr,
		0
	);


	std::vector<float> bf{ 0.f, 0.f, 0.f, 0.f };
	context->OMSetBlendState(nullptr, bf.data(), 0xFFFFFFFF);

	//context->DrawIndexed(m_indexCount, 0, 0);
	context->Draw(m_indexCount, 0);
}

void Genesis::Pottery::ToggleWireframeMode(bool onOff)
{
	m_wireframe = onOff;
	m_rasterizerState.Reset();

	CD3D11_RASTERIZER_DESC rasterStateDesc(D3D11_DEFAULT);

	if (m_wireframe)
	{
		rasterStateDesc.CullMode = D3D11_CULL_NONE;
		rasterStateDesc.FillMode = D3D11_FILL_WIREFRAME;
	}
	else
	{
		rasterStateDesc.CullMode = D3D11_CULL_BACK;
		rasterStateDesc.FillMode = D3D11_FILL_SOLID;
	}

	DX::ThrowIfFailed(
		m_deviceResources->GetD3DDevice()->CreateRasterizerState(
			&rasterStateDesc,
			m_rasterizerState.GetAddressOf()
		)
	);


}
