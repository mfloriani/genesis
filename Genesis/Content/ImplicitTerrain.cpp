#include "pch.h"
#include "ImplicitTerrain.h"

#include "..\Common\DirectXHelper.h"

#include <array>
#include <cmath>

using namespace Genesis;
using namespace DirectX;

ImplicitTerrain::ImplicitTerrain(const std::shared_ptr<DX::DeviceResources>& deviceResources)
	: m_deviceResources(deviceResources), m_ready(false), m_indexCount(0), m_wireframe(false)
{
	// TODO: replace this fixed value
	m_transform.position = XMFLOAT3(0.0f, -5.0f, 0.0f);
	m_transform.scale = XMFLOAT3(1.0f, 1.0f, 1.0f);

}

ImplicitTerrain::~ImplicitTerrain()
{
}

void ImplicitTerrain::CreateDeviceDependentResources()
{
	auto loadVSTask = DX::ReadDataAsync(L"ImplicitTerrainVS.cso");
	auto loadPSTask = DX::ReadDataAsync(L"ImplicitTerrainPS.cso");
	//auto loadPSTask = DX::ReadDataAsync(L"ImplicitTerrainPS_2.cso");

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

		// icosahedron
		std::vector<VertexPosition> vertices =
		{
			{ XMFLOAT3(0.000f,  0.000f,  1.000f) },
			{ XMFLOAT3(0.894f,  0.000f,  0.447f) },
			{ XMFLOAT3(0.276f,  0.851f,  0.447f) },
			{ XMFLOAT3(-0.724f,  0.526f,  0.447f)},
			{ XMFLOAT3(-0.724f, -0.526f,  0.447f)},
			{ XMFLOAT3(0.276f, -0.851f,  0.447f) },
			{ XMFLOAT3(0.724f,  0.526f, -0.447f) },
			{ XMFLOAT3(-0.276f,  0.851f, -0.447f)},
			{ XMFLOAT3(-0.894f,  0.000f, -0.447f)},
			{ XMFLOAT3(-0.276f, -0.851f, -0.447f)},
			{ XMFLOAT3(0.724f, -0.526f, -0.447f) },
			{ XMFLOAT3(0.000f,  0.000f, -1.000f) }

		};

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

		D3D11_SUBRESOURCE_DATA vertexBufferData = { 0 };
		vertexBufferData.pSysMem = vertices.data();
		vertexBufferData.SysMemPitch = 0;
		vertexBufferData.SysMemSlicePitch = 0;

		CD3D11_BUFFER_DESC vertexBufferDesc(
			sizeof(VertexPosNorTexTanBin) * vertices.size(),
			D3D11_BIND_VERTEX_BUFFER
		);

		DX::ThrowIfFailed(
			m_deviceResources->GetD3DDevice()->CreateBuffer(
				&vertexBufferDesc,
				&vertexBufferData,
				&m_vertexBuffer
			)
		);


		D3D11_SUBRESOURCE_DATA indexData;
		indexData.pSysMem = indices.data();
		indexData.SysMemPitch = 0;
		indexData.SysMemSlicePitch = 0;

		CD3D11_BUFFER_DESC indexBufferDesc(
			sizeof(unsigned int) * m_indexCount,
			D3D11_BIND_INDEX_BUFFER
		);

		DX::ThrowIfFailed(
			m_deviceResources->GetD3DDevice()->CreateBuffer(
				&indexBufferDesc,
				&indexData,
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

		CD3D11_BUFFER_DESC constantBufferDesc2(sizeof(CameraCB), D3D11_BIND_CONSTANT_BUFFER);
		DX::ThrowIfFailed(
			m_deviceResources->GetD3DDevice()->CreateBuffer(
				&constantBufferDesc2,
				nullptr,
				&m_cameraBuffer
			)
		);

		ToggleWireframeMode(false);
	});

	createSkyTask.then([this]() {

		m_ready = true;
	});

}

void ImplicitTerrain::ReleaseDeviceDependentResources()
{
	m_ready = false;
	m_vertexShader.Reset();
	m_inputLayout.Reset();
	m_pixelShader.Reset();
	m_MVPBuffer.Reset();
	m_cameraBuffer.Reset();
	m_vertexBuffer.Reset();
	m_rasterizerState.Reset();
}

void ImplicitTerrain::Update(DX::StepTimer const& timer, ModelViewProjCB& mvp, XMVECTOR& camPos)
{
	auto model = XMMatrixIdentity();

	//m_transform.rotation.x += -0.05f * static_cast<float>(timer.GetElapsedSeconds());
	//m_transform.rotation.y += 0.1f * static_cast<float>(timer.GetElapsedSeconds());

	model = XMMatrixMultiply(model, DirectX::XMMatrixScaling(m_transform.scale.x, m_transform.scale.y, m_transform.scale.z));
	//model = XMMatrixMultiply(
	//	model,
	//	DirectX::XMMatrixRotationQuaternion(
	//		DirectX::XMQuaternionRotationRollPitchYaw(
	//			m_transform.rotation.x, m_transform.rotation.y, m_transform.rotation.z)
	//	)
	//);
	model = XMMatrixMultiply(model, DirectX::XMMatrixTranslation(m_transform.position.x, m_transform.position.y, m_transform.position.z));


	XMStoreFloat4x4(&m_MVPBufferData.model, XMMatrixTranspose(model));
	m_MVPBufferData.view = mvp.view;
	m_MVPBufferData.projection = mvp.projection;
	m_MVPBufferData.invView = mvp.invView;

	XMStoreFloat4(&m_cameraBufferData.cameraPos, camPos);
}

void ImplicitTerrain::Render()
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

	context->RSSetState(m_rasterizerState.Get());

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
		m_cameraBuffer.GetAddressOf(),
		nullptr,
		nullptr
	);

	context->PSSetShader(
		m_pixelShader.Get(),
		nullptr,
		0
	);

	std::vector<float> bf{ 0.f, 0.f, 0.f, 0.f };
	context->OMSetBlendState(nullptr, bf.data(), 0xFFFFFFFF);

	context->DrawIndexed(m_indexCount, 0, 0);
}

void Genesis::ImplicitTerrain::ToggleWireframeMode(bool onOff)
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
