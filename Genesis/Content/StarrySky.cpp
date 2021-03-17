#include "pch.h"
#include "StarrySky.h"
#include "Util.h"
#include "..\Common\DirectXHelper.h"

#include <array>

using namespace Genesis;
using namespace DirectX;

StarrySky::StarrySky(const std::shared_ptr<DX::DeviceResources>& deviceResources) 
	: m_deviceResources(deviceResources), m_ready(false), m_indexCount(0)
{
}

StarrySky::~StarrySky()
{
}

void StarrySky::CreateDeviceDependentResources()
{
	auto loadVSTask = DX::ReadDataAsync(L"StarrySkyVS.cso");
	auto loadGSTask = DX::ReadDataAsync(L"StarrySkyGS.cso");
	auto loadPSTask = DX::ReadDataAsync(L"StarrySkyPS.cso");

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

	auto createGSTask = loadGSTask.then([this](const std::vector<byte>& fileData) {
		DX::ThrowIfFailed(
			m_deviceResources->GetD3DDevice()->CreateGeometryShader(
				&fileData[0],
				fileData.size(),
				nullptr,
				&m_geometryShader
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
				&m_constantBuffer
			)
		);
	});


	auto createSkyTask = (createVSTask && createGSTask && createPSTask).then([this]() {
		
		//m_indexCount = 8;
		//std::vector<VertexPosition> vertices =
		//{
		//	{XMFLOAT3(-0.5f, -0.5f, -0.5f)},
		//	{XMFLOAT3(-0.5f, -0.5f,  0.5f)},
		//	{XMFLOAT3(-0.5f,  0.5f, -0.5f)},
		//	{XMFLOAT3(-0.5f,  0.5f,  0.5f)},
		//	{XMFLOAT3( 0.5f, -0.5f, -0.5f)}, 
		//	{XMFLOAT3( 0.5f, -0.5f,  0.5f)}, 
		//	{XMFLOAT3( 0.5f,  0.5f, -0.5f)}, 
		//	{XMFLOAT3( 0.5f,  0.5f,  0.5f)} 
		//};

		m_indexCount = 10000; // number of stars
		auto vertices = GenerateRandomPointsOnSphere(m_indexCount, 50.0f);

		D3D11_SUBRESOURCE_DATA vertexBufferData = { 0 };
		vertexBufferData.pSysMem = vertices.data();
		vertexBufferData.SysMemPitch = 0;
		vertexBufferData.SysMemSlicePitch = 0;
		CD3D11_BUFFER_DESC vertexBufferDesc(sizeof(VertexPosition) * m_indexCount, D3D11_BIND_VERTEX_BUFFER);
		DX::ThrowIfFailed(
			m_deviceResources->GetD3DDevice()->CreateBuffer(
				&vertexBufferDesc,
				&vertexBufferData,
				&m_vertexBuffer
			)
		);
		
	});

	createSkyTask.then([this]() {

		D3D11_BLEND_DESC AdditiveBlendingDesc = {};
		AdditiveBlendingDesc.RenderTarget[0].BlendEnable = true;
		AdditiveBlendingDesc.RenderTarget[0].BlendOp = D3D11_BLEND_OP_ADD;
		AdditiveBlendingDesc.RenderTarget[0].SrcBlend = D3D11_BLEND_SRC_ALPHA;
		AdditiveBlendingDesc.RenderTarget[0].DestBlend = D3D11_BLEND_ONE;
		AdditiveBlendingDesc.RenderTarget[0].BlendOpAlpha = D3D11_BLEND_OP_ADD;
		AdditiveBlendingDesc.RenderTarget[0].SrcBlendAlpha = D3D11_BLEND_ZERO;
		AdditiveBlendingDesc.RenderTarget[0].DestBlendAlpha = D3D11_BLEND_ZERO;
		AdditiveBlendingDesc.RenderTarget[0].RenderTargetWriteMask = D3D11_COLOR_WRITE_ENABLE_ALL;
		DX::ThrowIfFailed(
			m_deviceResources->GetD3DDevice()->CreateBlendState(&AdditiveBlendingDesc, &m_additiveBlending)
		);

		m_ready = true;
	});

}

void StarrySky::ReleaseDeviceDependentResources()
{
	m_ready = false;
	m_vertexShader.Reset();
	m_inputLayout.Reset();
	m_pixelShader.Reset();
	m_constantBuffer.Reset();
	m_vertexBuffer.Reset();
	m_geometryShader.Reset();
}

void StarrySky::Update(DX::StepTimer const& timer, ModelViewProjCB& mvp)
{
	XMStoreFloat4x4(&m_MVPBufferData.model, XMMatrixIdentity());
	m_MVPBufferData.view = mvp.view;
	m_MVPBufferData.projection = mvp.projection;
	m_MVPBufferData.invView = mvp.invView;
}

void StarrySky::Render()
{
	if (!m_ready) return;

	auto context = m_deviceResources->GetD3DDeviceContext();

	// Prepare the constant buffer to send it to the graphics device.
	context->UpdateSubresource1(
		m_constantBuffer.Get(),
		0,
		NULL,
		&m_MVPBufferData,
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

	context->IASetPrimitiveTopology(D3D11_PRIMITIVE_TOPOLOGY_POINTLIST);
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
		m_constantBuffer.GetAddressOf(),
		nullptr,
		nullptr
	);

	context->GSSetShader(
		m_geometryShader.Get(),
		nullptr,
		0
	);

	// Send the constant buffer to the graphics device.
	context->GSSetConstantBuffers1(
		0,
		1,
		m_constantBuffer.GetAddressOf(),
		nullptr,
		nullptr
	);

	// Attach our pixel shader.
	context->PSSetShader(
		m_pixelShader.Get(),
		nullptr,
		0
	);

	// save the current blending state to restore in the end
	Microsoft::WRL::ComPtr<ID3D11BlendState> pBlendState0 = nullptr;
	UINT SampleMask0;
	std::array<float, 4> BlendFactor0;
	context->OMGetBlendState(&pBlendState0, BlendFactor0.data(), &SampleMask0);

	// turn on the additive blending factor
	std::vector<float> bf{ 0.f, 0.f, 0.f, 0.f };
	context->OMSetBlendState(m_additiveBlending.Get(), bf.data(), 0xFFFFFFFF);

	context->Draw(m_indexCount, 0);

	// restore the original blending state
	context->OMSetBlendState(m_additiveBlending.Get(), BlendFactor0.data(), SampleMask0);
}
