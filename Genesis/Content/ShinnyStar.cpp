#include "pch.h"
#include "ShinnyStar.h"
#include "Util.h"

#include "..\Common\DirectXHelper.h"

#include <array>

using namespace Genesis;
using namespace DirectX;

ShinnyStar::ShinnyStar(const std::shared_ptr<DX::DeviceResources>& deviceResources)
	: m_deviceResources(deviceResources), m_ready(false), m_indexCount(0)
{
}

ShinnyStar::~ShinnyStar()
{
}

void ShinnyStar::CreateDeviceDependentResources()
{
	auto loadVSTask = DX::ReadDataAsync(L"ShinnyStarVS.cso");
	auto loadGSTask = DX::ReadDataAsync(L"ShinnyStarGS.cso");
	auto loadPSTask = DX::ReadDataAsync(L"ShinnyStarPS.cso");

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
				&m_MVPBuffer
			)
		);

		CD3D11_BUFFER_DESC constantBufferDesc2(sizeof(PerFrameCB), D3D11_BIND_CONSTANT_BUFFER);
		DX::ThrowIfFailed(
			m_deviceResources->GetD3DDevice()->CreateBuffer(
				&constantBufferDesc2,
				nullptr,
				&m_perFrameBuffer
			)
		);
	});


	auto createSkyTask = (createVSTask && createGSTask && createPSTask).then([this]() {

		m_indexCount = 25; // number of stars
		auto vertices = GenerateRandomPointsOnSphere(m_indexCount, 90.0f);

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

void ShinnyStar::ReleaseDeviceDependentResources()
{
	m_ready = false;
	m_vertexShader.Reset();
	m_inputLayout.Reset();
	m_pixelShader.Reset();
	m_MVPBuffer.Reset();
	m_perFrameBuffer.Reset();
	m_vertexBuffer.Reset();
	m_geometryShader.Reset();
}

void ShinnyStar::Update(DX::StepTimer const& timer, ModelViewProjCB& mvp, XMVECTOR& camPos)
{
	XMStoreFloat4x4(&m_MVPBufferData.model, XMMatrixIdentity());
	m_MVPBufferData.view = mvp.view;
	m_MVPBufferData.projection = mvp.projection;
	m_MVPBufferData.invView = mvp.invView;

	float time = static_cast<float>(timer.GetTotalSeconds());
	XMStoreFloat4(&m_perFrameBufferData.cameraPos, camPos);
	XMStoreFloat4(&m_perFrameBufferData.time, XMVectorSet(time, 0.f, 0.f, 0.f));
	XMStoreFloat4(&m_perFrameBufferData.positionW, XMVectorZero());
}

void ShinnyStar::Render()
{
	if (!m_ready) return;

	auto context = m_deviceResources->GetD3DDeviceContext();

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
		m_perFrameBuffer.Get(),
		0,
		NULL,
		&m_perFrameBufferData,
		0,
		0,
		0
	);

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

	context->VSSetShader(
		m_vertexShader.Get(),
		nullptr,
		0
	);

	context->HSSetShader(
		nullptr,
		nullptr,
		0
	);

	context->DSSetShader(
		nullptr,
		nullptr,
		0
	);

	context->GSSetShader(
		m_geometryShader.Get(),
		nullptr,
		0
	);

	context->GSSetConstantBuffers1(
		0,
		1,
		m_MVPBuffer.GetAddressOf(),
		nullptr,
		nullptr
	);

	context->PSSetShader(
		m_pixelShader.Get(),
		nullptr,
		0
	);

	context->PSSetConstantBuffers1(
		0,
		1,
		m_perFrameBuffer.GetAddressOf(),
		nullptr,
		nullptr
	);
	
	// turn on the additive blending factor
	std::vector<float> bf{ 1.f, 1.f, 1.f, 1.f };
	context->OMSetBlendState(m_additiveBlending.Get(), bf.data(), 0xFFFFFFFF);

	context->Draw(m_indexCount, 0);

}
