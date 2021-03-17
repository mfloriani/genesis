#include "pch.h"
#include "TessPlanet.h"
#include "..\Common\DirectXHelper.h"

#include <array>

using namespace Genesis;
using namespace DirectX;

TessPlanet::TessPlanet(const std::shared_ptr<DX::DeviceResources>& deviceResources)
	: m_deviceResources(deviceResources), m_ready(false), m_indexCount(0)
{
}

TessPlanet::~TessPlanet()
{
}

void TessPlanet::CreateDeviceDependentResources()
{
	auto loadVSTask = DX::ReadDataAsync(L"TessPlanetVS.cso");
	auto loadHSTask = DX::ReadDataAsync(L"TessPlanetHS.cso");
	auto loadDSTask = DX::ReadDataAsync(L"TessPlanetDS.cso");
	auto loadPSTask = DX::ReadDataAsync(L"TessPlanetPS.cso");

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
			{ "POSITION", 0, DXGI_FORMAT_R32G32B32_FLOAT, 0, 0, D3D11_INPUT_PER_VERTEX_DATA, 0 }
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
	});


	auto createSkyTask = (createVSTask && createHSTask && createDSTask && createPSTask).then([this]() {

		// icosahedron
		std::vector<VertexPosition> vertices =
		{
			{ XMFLOAT3(0.000f,  0.000f,  1.000f) },
			{ XMFLOAT3(0.894f,  0.000f,  0.447f) },
			{ XMFLOAT3(0.276f,  0.851f,  0.447f) },
			{ XMFLOAT3(-0.724f,  0.526f,  0.447f) },
			{ XMFLOAT3(-0.724f, -0.526f,  0.447f) },
			{ XMFLOAT3(0.276f, -0.851f,  0.447f) },
			{ XMFLOAT3(0.724f,  0.526f, -0.447f) },
			{ XMFLOAT3(-0.276f,  0.851f, -0.447f) },
			{ XMFLOAT3(-0.894f,  0.000f, -0.447f) },
			{ XMFLOAT3(-0.276f, -0.851f, -0.447f) },
			{ XMFLOAT3(0.724f, -0.526f, -0.447f) },
			{ XMFLOAT3(0.000f,  0.000f, -1.000f) }
		};

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

		std::vector<unsigned int> indices = 
		{
			2, 1, 0,
			3, 2, 0,
			4, 3, 0,
			5, 4, 0,
			1, 5, 0,
			11, 6, 7,
			11, 7, 8,
			11, 8, 9,
			11, 9, 10,
			11, 10, 6,
			1, 2, 6,
			2, 3, 7,
			3, 4, 8,
			4, 5, 9,
			5, 1, 10,
			2, 7, 6,
			3, 8, 7,
			4, 9, 8,
			5, 10, 9,
			1, 6, 10 
		};

		m_indexCount = indices.size();

		D3D11_SUBRESOURCE_DATA indexData;
		indexData.pSysMem = indices.data();
		indexData.SysMemPitch = 0;
		indexData.SysMemSlicePitch = 0;

		CD3D11_BUFFER_DESC indexBufferDesc(
			sizeof(unsigned int)* m_indexCount,
			D3D11_BIND_INDEX_BUFFER
		);

		DX::ThrowIfFailed(
			m_deviceResources->GetD3DDevice()->CreateBuffer(
				&indexBufferDesc,
				&indexData,
				&m_indexBuffer
			)
		);



		CD3D11_RASTERIZER_DESC rasterStateDesc(D3D11_DEFAULT);
		rasterStateDesc.CullMode = D3D11_CULL_NONE;
		rasterStateDesc.FillMode = D3D11_FILL_WIREFRAME;

		DX::ThrowIfFailed(
			m_deviceResources->GetD3DDevice()->CreateRasterizerState(
				&rasterStateDesc,
				m_rasterizerState.GetAddressOf()
			)
		);

	});

	createSkyTask.then([this]() {

		m_ready = true;
	});

}

void TessPlanet::ReleaseDeviceDependentResources()
{
	m_ready = false;
	m_vertexShader.Reset();
	m_inputLayout.Reset();
	m_pixelShader.Reset();
	m_MVPBuffer.Reset();
	m_cameraBuffer.Reset();
	m_vertexBuffer.Reset();
	m_hullShader.Reset();
	m_domainShader.Reset();
}

void TessPlanet::Update(DX::StepTimer const& timer, ModelViewProjCB& mvp, XMVECTOR& camPos)
{
	XMStoreFloat4x4(&m_MVPBufferData.model, XMMatrixIdentity());
	m_MVPBufferData.view = mvp.view;
	m_MVPBufferData.projection = mvp.projection;
	m_MVPBufferData.invView = mvp.invView;

	XMStoreFloat4(&m_cameraBufferData.cameraPos, camPos);
}

void TessPlanet::Render()
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

	context->IASetPrimitiveTopology(D3D11_PRIMITIVE_TOPOLOGY_3_CONTROL_POINT_PATCHLIST);
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

	
	context->DrawIndexed(m_indexCount, 0, 0);

	
}
