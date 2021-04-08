#include "pch.h"
#include "NarrowStrip.h"

#include "..\Common\DirectXHelper.h"

#include <array>
#include <cmath>
#include <iostream>
#include <fstream>

using namespace Genesis;
using namespace DirectX;

NarrowStrip::NarrowStrip(const std::shared_ptr<DX::DeviceResources>& deviceResources)
	: m_deviceResources(deviceResources), m_ready(false), m_indexCount(0), m_wireframe(false)
{
	// TODO: replace this fixed value
	m_transform.position = XMFLOAT3(50.0f, 25.0f, -50.0f);
	m_transform.scale = XMFLOAT3(13.f, 13.f, 13.f);
	m_transform.rotation = XMFLOAT3(0.f, 0.0f, 0.0f);
}

NarrowStrip::~NarrowStrip()
{
}

void NarrowStrip::CreateDeviceDependentResources()
{
	auto loadVSTask = DX::ReadDataAsync(L"NarrowStripVS.cso");
	auto loadHSTask = DX::ReadDataAsync(L"NarrowStripHS.cso");
	auto loadDSTask = DX::ReadDataAsync(L"NarrowStripDS.cso");
	auto loadPSTask = DX::ReadDataAsync(L"NarrowStripPS.cso");

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

	auto createNarrowStripTask = (createVSTask && createHSTask && createDSTask && createPSTask).then([this]() {

		std::vector<VertexPosition> vertices = 
		{
#if 1
			{DirectX::XMFLOAT3(-0.5f, -0.5f, 0.0f)},
			{DirectX::XMFLOAT3(-0.5f, 0.5f,  0.0f)},
			{DirectX::XMFLOAT3(0.5f,  -0.5f, 0.0f)},
			{DirectX::XMFLOAT3(0.5f,  0.5f,  0.0f)},
#else
			{XMFLOAT3(-0.5000f, 0.0000f, 0.5000f)},
			{XMFLOAT3(-0.4000f, 0.0000f, 0.5000f)},
			{XMFLOAT3(-0.4000f, 0.0000f, 0.4000f)},
			{XMFLOAT3(-0.5000f, 0.0000f, 0.4000f)},
			{XMFLOAT3(-0.3000f, 0.0000f, 0.5000f)},
			{XMFLOAT3(-0.3000f, 0.0000f, 0.4000f)},
			{XMFLOAT3(-0.2000f, 0.0000f, 0.5000f)},
			{XMFLOAT3(-0.2000f, 0.0000f, 0.4000f)},
			{XMFLOAT3(-0.1000f, 0.0000f, 0.5000f)},
			{XMFLOAT3(-0.1000f, 0.0000f, 0.4000f)},
			{XMFLOAT3(-0.0000f, 0.0000f, 0.5000f)},
			{XMFLOAT3(-0.0000f, 0.0000f, 0.4000f)},
			{XMFLOAT3(0.1000f, 0.0000f, 0.5000f)},
			{XMFLOAT3(0.1000f, 0.0000f, 0.4000f)},
			{XMFLOAT3(0.2000f, 0.0000f, 0.5000f)},
			{XMFLOAT3(0.2000f, 0.0000f, 0.4000f)},
			{XMFLOAT3(0.3000f, 0.0000f, 0.5000f)},
			{XMFLOAT3(0.3000f, 0.0000f, 0.4000f)},
			{XMFLOAT3(0.4000f, 0.0000f, 0.5000f)},
			{XMFLOAT3(0.4000f, 0.0000f, 0.4000f)},
			{XMFLOAT3(0.5000f, 0.0000f, 0.5000f)},
			{XMFLOAT3(0.5000f, 0.0000f, 0.4000f)},
			{XMFLOAT3(-0.4000f, 0.0000f, 0.3000f)},
			{XMFLOAT3(-0.5000f, 0.0000f, 0.3000f)},
			{XMFLOAT3(-0.3000f, 0.0000f, 0.3000f)},
			{XMFLOAT3(-0.2000f, 0.0000f, 0.3000f)},
			{XMFLOAT3(-0.1000f, 0.0000f, 0.3000f)},
			{XMFLOAT3(-0.0000f, 0.0000f, 0.3000f)},
			{XMFLOAT3(0.1000f, 0.0000f, 0.3000f)},
			{XMFLOAT3(0.2000f, 0.0000f, 0.3000f)},
			{XMFLOAT3(0.3000f, 0.0000f, 0.3000f)},
			{XMFLOAT3(0.4000f, 0.0000f, 0.3000f)},
			{XMFLOAT3(0.5000f, 0.0000f, 0.3000f)},
			{XMFLOAT3(-0.4000f, 0.0000f, 0.2000f)},
			{XMFLOAT3(-0.5000f, 0.0000f, 0.2000f)},
			{XMFLOAT3(-0.3000f, 0.0000f, 0.2000f)},
			{XMFLOAT3(-0.2000f, 0.0000f, 0.2000f)},
			{XMFLOAT3(-0.1000f, 0.0000f, 0.2000f)},
			{XMFLOAT3(-0.0000f, 0.0000f, 0.2000f)},
			{XMFLOAT3(0.1000f, 0.0000f, 0.2000f)},
			{XMFLOAT3(0.2000f, 0.0000f, 0.2000f)},
			{XMFLOAT3(0.3000f, 0.0000f, 0.2000f)},
			{XMFLOAT3(0.4000f, 0.0000f, 0.2000f)},
			{XMFLOAT3(0.5000f, 0.0000f, 0.2000f)},
			{XMFLOAT3(-0.4000f, 0.0000f, 0.1000f)},
			{XMFLOAT3(-0.5000f, 0.0000f, 0.1000f)},
			{XMFLOAT3(-0.3000f, 0.0000f, 0.1000f)},
			{XMFLOAT3(-0.2000f, 0.0000f, 0.1000f)},
			{XMFLOAT3(-0.1000f, 0.0000f, 0.1000f)},
			{XMFLOAT3(-0.0000f, 0.0000f, 0.1000f)},
			{XMFLOAT3(0.1000f, 0.0000f, 0.1000f)},
			{XMFLOAT3(0.2000f, 0.0000f, 0.1000f)},
			{XMFLOAT3(0.3000f, 0.0000f, 0.1000f)},
			{XMFLOAT3(0.4000f, 0.0000f, 0.1000f)},
			{XMFLOAT3(0.5000f, 0.0000f, 0.1000f)},
			{XMFLOAT3(-0.4000f, 0.0000f, 0.0000f)},
			{XMFLOAT3(-0.5000f, 0.0000f, 0.0000f)},
			{XMFLOAT3(-0.3000f, 0.0000f, 0.0000f)},
			{XMFLOAT3(-0.2000f, 0.0000f, 0.0000f)},
			{XMFLOAT3(-0.1000f, 0.0000f, 0.0000f)},
			{XMFLOAT3(-0.0000f, 0.0000f, 0.0000f)},
			{XMFLOAT3(0.1000f, 0.0000f, 0.0000f)},
			{XMFLOAT3(0.2000f, 0.0000f, 0.0000f)},
			{XMFLOAT3(0.3000f, 0.0000f, 0.0000f)},
			{XMFLOAT3(0.4000f, 0.0000f, 0.0000f)},
			{XMFLOAT3(0.5000f, 0.0000f, 0.0000f)},
			{XMFLOAT3(-0.4000f, 0.0000f, -0.1000f)},
			{XMFLOAT3(-0.5000f, 0.0000f, -0.1000f)},
			{XMFLOAT3(-0.3000f, 0.0000f, -0.1000f)},
			{XMFLOAT3(-0.2000f, 0.0000f, -0.1000f)},
			{XMFLOAT3(-0.1000f, 0.0000f, -0.1000f)},
			{XMFLOAT3(-0.0000f, 0.0000f, -0.1000f)},
			{XMFLOAT3(0.1000f, 0.0000f, -0.1000f)},
			{XMFLOAT3(0.2000f, 0.0000f, -0.1000f)},
			{XMFLOAT3(0.3000f, 0.0000f, -0.1000f)},
			{XMFLOAT3(0.4000f, 0.0000f, -0.1000f)},
			{XMFLOAT3(0.5000f, 0.0000f, -0.1000f)},
			{XMFLOAT3(-0.4000f, 0.0000f, -0.2000f)},
			{XMFLOAT3(-0.5000f, 0.0000f, -0.2000f)},
			{XMFLOAT3(-0.3000f, 0.0000f, -0.2000f)},
			{XMFLOAT3(-0.2000f, 0.0000f, -0.2000f)},
			{XMFLOAT3(-0.1000f, 0.0000f, -0.2000f)},
			{XMFLOAT3(-0.0000f, 0.0000f, -0.2000f)},
			{XMFLOAT3(0.1000f, 0.0000f, -0.2000f)},
			{XMFLOAT3(0.2000f, 0.0000f, -0.2000f)},
			{XMFLOAT3(0.3000f, 0.0000f, -0.2000f)},
			{XMFLOAT3(0.4000f, 0.0000f, -0.2000f)},
			{XMFLOAT3(0.5000f, 0.0000f, -0.2000f)},
			{XMFLOAT3(-0.4000f, 0.0000f, -0.3000f)},
			{XMFLOAT3(-0.5000f, 0.0000f, -0.3000f)},
			{XMFLOAT3(-0.3000f, 0.0000f, -0.3000f)},
			{XMFLOAT3(-0.2000f, 0.0000f, -0.3000f)},
			{XMFLOAT3(-0.1000f, 0.0000f, -0.3000f)},
			{XMFLOAT3(-0.0000f, 0.0000f, -0.3000f)},
			{XMFLOAT3(0.1000f, 0.0000f, -0.3000f)},
			{XMFLOAT3(0.2000f, 0.0000f, -0.3000f)},
			{XMFLOAT3(0.3000f, 0.0000f, -0.3000f)},
			{XMFLOAT3(0.4000f, 0.0000f, -0.3000f)},
			{XMFLOAT3(0.5000f, 0.0000f, -0.3000f)},
			{XMFLOAT3(-0.4000f, 0.0000f, -0.4000f)},
			{XMFLOAT3(-0.5000f, 0.0000f, -0.4000f)},
			{XMFLOAT3(-0.3000f, 0.0000f, -0.4000f)},
			{XMFLOAT3(-0.2000f, 0.0000f, -0.4000f)},
			{XMFLOAT3(-0.1000f, 0.0000f, -0.4000f)},
			{XMFLOAT3(-0.0000f, 0.0000f, -0.4000f)},
			{XMFLOAT3(0.1000f, 0.0000f, -0.4000f)},
			{XMFLOAT3(0.2000f, 0.0000f, -0.4000f)},
			{XMFLOAT3(0.3000f, 0.0000f, -0.4000f)},
			{XMFLOAT3(0.4000f, 0.0000f, -0.4000f)},
			{XMFLOAT3(0.5000f, 0.0000f, -0.4000f)},
			{XMFLOAT3(-0.4000f, 0.0000f, -0.5000f)},
			{XMFLOAT3(-0.5000f, 0.0000f, -0.5000f)},
			{XMFLOAT3(-0.3000f, 0.0000f, -0.5000f)},
			{XMFLOAT3(-0.2000f, 0.0000f, -0.5000f)},
			{XMFLOAT3(-0.1000f, 0.0000f, -0.5000f)},
			{XMFLOAT3(-0.0000f, 0.0000f, -0.5000f)},
			{XMFLOAT3(0.1000f, 0.0000f, -0.5000f)},
			{XMFLOAT3(0.2000f, 0.0000f, -0.5000f)},
			{XMFLOAT3(0.3000f, 0.0000f, -0.5000f)},
			{XMFLOAT3(0.4000f, 0.0000f, -0.5000f)},
			{XMFLOAT3(0.5000f, 0.0000f, -0.5000f)},
#endif
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

		std::vector<unsigned short> indices =
		{
#if 1
			0, 1, 2,
			3, 2, 1
#else
			1,2,3,
			3,4,1,
			2,5,6,
			6,3,2,
			5,7,8,
			8,6,5,
			7,9,10,
			10,8,7,
			9,11,12,
			12,10,9,
			11,13,14,
			14,12,11,
			13,15,16,
			16,14,13,
			15,17,18,
			18,16,15,
			17,19,20,
			20,18,17,
			19,21,22,
			22,20,19,
			4,3,23,
			23,24,4,
			3,6,25,
			25,23,3,
			6,8,26,
			26,25,6,
			8,10,27,
			27,26,8,
			10,12,28,
			28,27,10,
			12,14,29,
			29,28,12,
			14,16,30,
			30,29,14,
			16,18,31,
			31,30,16,
			18,20,32,
			32,31,18,
			20,22,33,
			33,32,20,
			24,23,34,
			34,35,24,
			23,25,36,
			36,34,23,
			25,26,37,
			37,36,25,
			26,27,38,
			38,37,26,
			27,28,39,
			39,38,27,
			28,29,40,
			40,39,28,
			29,30,41,
			41,40,29,
			30,31,42,
			42,41,30,
			31,32,43,
			43,42,31,
			32,33,44,
			44,43,32,
			35,34,45,
			45,46,35,
			34,36,47,
			47,45,34,
			36,37,48,
			48,47,36,
			37,38,49,
			49,48,37,
			38,39,50,
			50,49,38,
			39,40,51,
			51,50,39,
			40,41,52,
			52,51,40,
			41,42,53,
			53,52,41,
			42,43,54,
			54,53,42,
			43,44,55,
			55,54,43,
			46,45,56,
			56,57,46,
			45,47,58,
			58,56,45,
			47,48,59,
			59,58,47,
			48,49,60,
			60,59,48,
			49,50,61,
			61,60,49,
			50,51,62,
			62,61,50,
			51,52,63,
			63,62,51,
			52,53,64,
			64,63,52,
			53,54,65,
			65,64,53,
			54,55,66,
			66,65,54,
			57,56,67,
			67,68,57,
			56,58,69,
			69,67,56,
			58,59,70,
			70,69,58,
			59,60,71,
			71,70,59,
			60,61,72,
			72,71,60,
			61,62,73,
			73,72,61,
			62,63,74,
			74,73,62,
			63,64,75,
			75,74,63,
			64,65,76,
			76,75,64,
			65,66,77,
			77,76,65,
			68,67,78,
			78,79,68,
			67,69,80,
			80,78,67,
			69,70,81,
			81,80,69,
			70,71,82,
			82,81,70,
			71,72,83,
			83,82,71,
			72,73,84,
			84,83,72,
			73,74,85,
			85,84,73,
			74,75,86,
			86,85,74,
			75,76,87,
			87,86,75,
			76,77,88,
			88,87,76,
			79,78,89,
			89,90,79,
			78,80,91,
			91,89,78,
			80,81,92,
			92,91,80,
			81,82,93,
			93,92,81,
			82,83,94,
			94,93,82,
			83,84,95,
			95,94,83,
			84,85,96,
			96,95,84,
			85,86,97,
			97,96,85,
			86,87,98,
			98,97,86,
			87,88,99,
			99,98,87,
			90,89,100,
			100,101,90,
			89,91,102,
			102,100,89,
			91,92,103,
			103,102,91,
			92,93,104,
			104,103,92,
			93,94,105,
			105,104,93,
			94,95,106,
			106,105,94,
			95,96,107,
			107,106,95,
			96,97,108,
			108,107,96,
			97,98,109,
			109,108,97,
			98,99,110,
			110,109,98,
			101,100,111,
			111,112,101,
			100,102,113,
			113,111,100,
			102,103,114,
			114,113,102,
			103,104,115,
			115,114,103,
			104,105,116,
			116,115,104,
			105,106,117,
			117,116,105,
			106,107,118,
			118,117,106,
			107,108,119,
			119,118,107,
			108,109,120,
			120,119,108,
			109,110,121,
			121,120,109
#endif
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

		ToggleWireframeMode(true);
	});

	createNarrowStripTask.then([this]() {

		m_ready = true;
	});

}

void NarrowStrip::ReleaseDeviceDependentResources()
{
	m_ready = false;
	m_vertexShader.Reset();
	m_inputLayout.Reset();
	m_pixelShader.Reset();
	m_MVPBuffer.Reset();
	m_perFrameBuffer.Reset();
	m_vertexBuffer.Reset();
	m_indexBuffer.Reset();
	m_hullShader.Reset();
	m_domainShader.Reset();
	m_rasterizerState.Reset();
}

void NarrowStrip::Update(DX::StepTimer const& timer, ModelViewProjCB& mvp, XMVECTOR& camPos)
{
	auto model = XMMatrixIdentity();

	m_transform.rotation.x += -0.05f * static_cast<float>(timer.GetElapsedSeconds());
	m_transform.rotation.y += 0.1f * static_cast<float>(timer.GetElapsedSeconds());

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

	float time = static_cast<float>(timer.GetTotalSeconds());
	XMStoreFloat4(&m_perFrameBufferData.cameraPos, camPos);
	XMStoreFloat4(&m_perFrameBufferData.time, XMVectorSet(time, 0.f, 0.f, 0.f));
	XMStoreFloat4(&m_perFrameBufferData.positionW, XMVectorZero());
}

void NarrowStrip::Render()
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
		m_perFrameBuffer.Get(),
		0,
		NULL,
		&m_perFrameBufferData,
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
		DXGI_FORMAT_R16_UINT,
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
		m_perFrameBuffer.GetAddressOf(),
		nullptr,
		nullptr
	);

	context->GSSetShader(
		nullptr,
		nullptr,
		0
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

void Genesis::NarrowStrip::ToggleWireframeMode(bool onOff)
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
