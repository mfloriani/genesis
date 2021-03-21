#include "pch.h"
#include "Pottery.h"

#include "..\Common\DirectXHelper.h"

#include <array>
#include <cmath>

using namespace Genesis;
using namespace DirectX;

Pottery::Pottery(const std::shared_ptr<DX::DeviceResources>& deviceResources)
	: m_deviceResources(deviceResources), m_ready(false), m_indexCount(0), m_wireframe(false)
{
	// TODO: replace this fixed value
	m_transform.position = XMFLOAT3(0.0f, 0.0f, -10.0f);
	m_transform.scale = XMFLOAT3(1.0f, 1.0f, 1.0f);
	m_transform.rotation = XMFLOAT3(-3.14f, 0.0f, 0.0f);

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

		std::vector<VertexPosition> vertices = 
		{
			{XMFLOAT3(-10.0f, -10.0f, +15.0f)},
			{XMFLOAT3(-5.0f,  0.0f, +15.0f)},
			{XMFLOAT3(+5.0f,  0.0f, +15.0f)},
			{XMFLOAT3(+10.0f, 0.0f, +15.0f)},
			
			{XMFLOAT3(-15.0f, 0.0f, +5.0f)},
			{XMFLOAT3(-5.0f,  0.0f, +5.0f)},
			{XMFLOAT3(+5.0f,  20.0f, +5.0f)},
			{XMFLOAT3(+15.0f, 0.0f, +5.0f)},
			
			{XMFLOAT3(-15.0f, 0.0f, -5.0f)},
			{XMFLOAT3(-5.0f,  0.0f, -5.0f)},
			{XMFLOAT3(+5.0f,  0.0f, -5.0f)},
			{XMFLOAT3(+15.0f, 0.0f, -5.0f)},
			
			{XMFLOAT3(-10.0f, 10.0f, -15.0f)},
			{XMFLOAT3(-5.0f,  0.0f, -15.0f)},
			{XMFLOAT3(+5.0f,  0.0f, -15.0f)},
			{XMFLOAT3(+25.0f, 10.0f, -15.0f)}
		};
		m_indexCount = vertices.size();

		//std::vector<unsigned int> indices =
		//{
		//	
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

	//context->IASetIndexBuffer(
	//	m_indexBuffer.Get(),
	//	DXGI_FORMAT_R32_UINT,
	//	0
	//);

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
