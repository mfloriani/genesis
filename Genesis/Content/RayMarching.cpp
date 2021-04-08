#include "pch.h"
#include "RayMarching.h"
#include "Util.h"

#include "..\Common\DirectXHelper.h"

#include <array>

using namespace Genesis;
using namespace DirectX;

RayMarching::RayMarching(const std::shared_ptr<DX::DeviceResources>& deviceResources)
	: m_deviceResources(deviceResources), m_ready(false), m_indexCount(0)
{
}

RayMarching::~RayMarching()
{
}

void RayMarching::CreateDeviceDependentResources()
{
	auto loadVSTask = DX::ReadDataAsync(L"RayMarchingVS.cso");
	auto loadPSTask = DX::ReadDataAsync(L"RayMarchingPS.cso");
	//auto loadPSTask = DX::ReadDataAsync(L"RayMarchingPS_2.cso");

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


	auto createSkyTask = (createVSTask && createPSTask).then([this]() {

		std::vector<VertexPosition> vertices =
		{
			{DirectX::XMFLOAT3(-0.5f, -0.5f, 0.0f)},
			{DirectX::XMFLOAT3(-0.5f, 0.5f,  0.0f)},
			{DirectX::XMFLOAT3(0.5f,  -0.5f, 0.0f)},
			{DirectX::XMFLOAT3(0.5f,  0.5f,  0.0f)},
		};

		D3D11_SUBRESOURCE_DATA vertexBufferData = { 0 };
		vertexBufferData.pSysMem = vertices.data();
		vertexBufferData.SysMemPitch = 0;
		vertexBufferData.SysMemSlicePitch = 0;
		CD3D11_BUFFER_DESC vertexBufferDesc(sizeof(VertexPosition) * vertices.size(), D3D11_BIND_VERTEX_BUFFER);
		DX::ThrowIfFailed(
			m_deviceResources->GetD3DDevice()->CreateBuffer(
				&vertexBufferDesc,
				&vertexBufferData,
				&m_vertexBuffer
			)
		);

		std::vector<unsigned short> indices =
		{
			0, 1, 2,
			3, 2, 1
		};

		m_indexCount = indices.size();

		D3D11_SUBRESOURCE_DATA indexBufferData = { 0 };
		indexBufferData.pSysMem = indices.data();
		indexBufferData.SysMemPitch = 0;
		indexBufferData.SysMemSlicePitch = 0;
		CD3D11_BUFFER_DESC indexBufferDesc(sizeof(unsigned short) * indices.size(), D3D11_BIND_INDEX_BUFFER);
		DX::ThrowIfFailed(
			m_deviceResources->GetD3DDevice()->CreateBuffer(
				&indexBufferDesc,
				&indexBufferData,
				&m_indexBuffer
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

		CD3D11_RASTERIZER_DESC rasterStateDesc(D3D11_DEFAULT);
		rasterStateDesc.CullMode = D3D11_CULL_BACK;
		rasterStateDesc.FillMode = D3D11_FILL_SOLID;

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

void RayMarching::ReleaseDeviceDependentResources()
{
	m_ready = false;
	m_vertexShader.Reset();
	m_inputLayout.Reset();
	m_pixelShader.Reset();
	m_MVPBuffer.Reset();
	m_perFrameBuffer.Reset();
	m_vertexBuffer.Reset();
	m_indexBuffer.Reset();
	m_rasterizerState.Reset();
}

void RayMarching::Update(DX::StepTimer const& timer, ModelViewProjCB& mvp, XMVECTOR& camPos)
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

void RayMarching::Render()
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

	context->IASetIndexBuffer(
		m_indexBuffer.Get(),
		DXGI_FORMAT_R16_UINT,
		0
	);

	context->IASetPrimitiveTopology(D3D11_PRIMITIVE_TOPOLOGY_TRIANGLELIST);
	context->IASetInputLayout(m_inputLayout.Get());

	context->VSSetShader(
		m_vertexShader.Get(),
		nullptr,
		0
	);

	context->VSSetConstantBuffers1(
		0,
		1,
		m_MVPBuffer.GetAddressOf(),
		nullptr,
		nullptr
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
		nullptr,
		nullptr,
		0
	);

	context->PSSetConstantBuffers1(
		0,
		1,
		m_MVPBuffer.GetAddressOf(),
		nullptr,
		nullptr
	);

	context->PSSetConstantBuffers1(
		1,
		1,
		m_perFrameBuffer.GetAddressOf(),
		nullptr,
		nullptr
	);

	context->RSSetState(m_rasterizerState.Get());

	context->PSSetShader(
		m_pixelShader.Get(),
		nullptr,
		0
	);

	std::vector<float> bf{ 0.f, 0.f, 0.f, 0.f };
	context->OMSetBlendState(nullptr, bf.data(), 0xFFFFFFFF);

	context->DrawIndexed(m_indexCount, 0, 0);
}
