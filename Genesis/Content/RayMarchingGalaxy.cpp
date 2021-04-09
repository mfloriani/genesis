#include "pch.h"
#include "RayMarchingGalaxy.h"
#include "Util.h"
#include "AssetManager.h"

#include "..\Common\DirectXHelper.h"

#include <array>

using namespace Genesis;
using namespace DirectX;

RayMarchingGalaxy::RayMarchingGalaxy(const std::shared_ptr<DX::DeviceResources>& deviceResources)
	: m_deviceResources(deviceResources), m_ready(false), m_indexCount(0)
{
	m_transform.position = XMFLOAT3(0.f, 45.f, 20.f);
}

RayMarchingGalaxy::~RayMarchingGalaxy()
{
}

void RayMarchingGalaxy::CreateDeviceDependentResources()
{
	auto loadVSTask = DX::ReadDataAsync(L"RayMarchingVS.cso");
	auto loadPSTask = DX::ReadDataAsync(L"RayMarchingGalaxyPS.cso");

	auto loadVSQuadTask = DX::ReadDataAsync(L"GalaxyVS.cso");
	auto loadGSQuadTask = DX::ReadDataAsync(L"GalaxyGS.cso");
	auto loadPSQuadTask = DX::ReadDataAsync(L"GalaxyPS.cso");


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


	auto createVSQuadTask = loadVSQuadTask.then([this](const std::vector<byte>& fileData) {
		DX::ThrowIfFailed(
			m_deviceResources->GetD3DDevice()->CreateVertexShader(
				&fileData[0],
				fileData.size(),
				nullptr,
				&m_vertexShaderQuad
			)
		);
	});

	auto createGSQuadTask = loadGSQuadTask.then([this](const std::vector<byte>& fileData) {
		DX::ThrowIfFailed(
			m_deviceResources->GetD3DDevice()->CreateGeometryShader(
				&fileData[0],
				fileData.size(),
				nullptr,
				&m_geometryShaderQuad
			)
		);
	});

	auto createPSQuadTask = loadPSQuadTask.then([this](const std::vector<byte>& fileData) {
		DX::ThrowIfFailed(
			m_deviceResources->GetD3DDevice()->CreatePixelShader(
				&fileData[0],
				fileData.size(),
				nullptr,
				&m_pixelShaderQuad
			)
		);
	});




	auto createGalaxyTask = (createVSTask && createPSTask && createVSQuadTask && createGSQuadTask && createPSQuadTask).then([this]() {

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

		D3D11_SAMPLER_DESC SamplerDesc = {};
		SamplerDesc.AddressU = D3D11_TEXTURE_ADDRESS_MIRROR;
		SamplerDesc.AddressV = SamplerDesc.AddressU;
		SamplerDesc.AddressW = SamplerDesc.AddressU;
		SamplerDesc.Filter = D3D11_FILTER_MIN_MAG_MIP_LINEAR;

		DX::ThrowIfFailed(
			m_deviceResources->GetD3DDevice()->CreateSamplerState(&SamplerDesc, &m_samplerState)
		);


		// TODO: solve this fixed values
		UINT width = 900;
		UINT height = 900;

		D3D11_TEXTURE2D_DESC texDesc{};
		texDesc.Width = width;
		texDesc.Height = height;
		texDesc.MipLevels = 1;
		texDesc.ArraySize = 1;
		texDesc.Format = DXGI_FORMAT_R32G32B32A32_FLOAT;
		texDesc.SampleDesc.Count = 1;
		texDesc.SampleDesc.Quality = 0;
		texDesc.Usage = D3D11_USAGE_DEFAULT;
		texDesc.BindFlags = D3D11_BIND_RENDER_TARGET | D3D11_BIND_SHADER_RESOURCE;
		texDesc.CPUAccessFlags = 0;
		texDesc.MiscFlags = 0;

		Microsoft::WRL::ComPtr<ID3D11Texture2D> texture;
		DX::ThrowIfFailed(
			m_deviceResources->GetD3DDevice()->CreateTexture2D(&texDesc, nullptr, &texture)
		);

		D3D11_RENDER_TARGET_VIEW_DESC rtvDesc{};
		rtvDesc.Format = texDesc.Format;
		rtvDesc.ViewDimension = D3D11_RTV_DIMENSION_TEXTURE2D;
		rtvDesc.Texture2D.MipSlice = 0;

		DX::ThrowIfFailed(
			m_deviceResources->GetD3DDevice()->CreateRenderTargetView(
				texture.Get(),
				&rtvDesc,
				&m_renderTargetView
			)
		);

		D3D11_SHADER_RESOURCE_VIEW_DESC srvDesc{};
		srvDesc.Format = texDesc.Format;
		srvDesc.ViewDimension = D3D11_SRV_DIMENSION_TEXTURE2D;
		srvDesc.Texture2D.MipLevels = texDesc.MipLevels;
		srvDesc.Texture2D.MostDetailedMip = 0;
		DX::ThrowIfFailed(
			m_deviceResources->GetD3DDevice()->CreateShaderResourceView(texture.Get(), &srvDesc, &m_textureSRV)
		);

		m_viewportTexture.Width = static_cast<FLOAT>(width);
		m_viewportTexture.Height = static_cast<FLOAT>(height);
		m_viewportTexture.MinDepth = 0.0f;
		m_viewportTexture.MaxDepth = 1.0f;
		m_viewportTexture.TopLeftX = 0;
		m_viewportTexture.TopLeftY = 0;


		// Quad vertex buffer
		{
			std::vector<VertexPosition> vertices = { { m_transform.position } };

			D3D11_SUBRESOURCE_DATA vertexBufferData = { 0 };
			vertexBufferData.pSysMem = vertices.data();
			vertexBufferData.SysMemPitch = 0;
			vertexBufferData.SysMemSlicePitch = 0;
			CD3D11_BUFFER_DESC vertexBufferDesc(sizeof(VertexPosition) * vertices.size(), D3D11_BIND_VERTEX_BUFFER);
			DX::ThrowIfFailed(
				m_deviceResources->GetD3DDevice()->CreateBuffer(
					&vertexBufferDesc,
					&vertexBufferData,
					&m_vertexBufferQuad
				)
			);
		}


		{
			D3D11_SAMPLER_DESC SamplerDesc = {};
			SamplerDesc.AddressU = D3D11_TEXTURE_ADDRESS_CLAMP;
			SamplerDesc.AddressV = SamplerDesc.AddressU;
			SamplerDesc.AddressW = SamplerDesc.AddressU;
			SamplerDesc.Filter = D3D11_FILTER_MIN_MAG_MIP_LINEAR;

			DX::ThrowIfFailed(
				m_deviceResources->GetD3DDevice()->CreateSamplerState(&SamplerDesc, &m_samplerStateQuad)
			);
		}


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


	});

	createGalaxyTask.then([this]() {
		m_ready = true;
	});

}

void RayMarchingGalaxy::ReleaseDeviceDependentResources()
{
	m_ready = false;
	m_vertexShader.Reset();
	m_inputLayout.Reset();
	m_pixelShader.Reset();
	m_MVPBuffer.Reset();
	m_vertexBuffer.Reset();
	m_indexBuffer.Reset();
	m_perFrameBuffer.Reset();
	m_rasterizerState.Reset();
}

void RayMarchingGalaxy::Update(DX::StepTimer const& timer, ModelViewProjCB& mvp, XMVECTOR& camPos)
{
	XMStoreFloat4x4(&m_MVPBufferData.model, XMMatrixIdentity());
	m_MVPBufferData.view = mvp.view;
	m_MVPBufferData.projection = mvp.projection;
	m_MVPBufferData.invView = mvp.invView;

	float time = static_cast<float>(timer.GetTotalSeconds());
	XMStoreFloat4(&m_perFrameBufferData.cameraPos, camPos);
	XMStoreFloat4(&m_perFrameBufferData.time, XMVectorSet(time, 0.f, 0.f, 0.f));
	XMStoreFloat4(&m_perFrameBufferData.positionW, XMLoadFloat3(&m_transform.position));
}

void RayMarchingGalaxy::RenderToTexture()
{
	if (!m_ready) return;

	auto context = m_deviceResources->GetD3DDeviceContext();

	ID3D11RenderTargetView* const targets[1] = { m_renderTargetView.Get() };
	context->OMSetRenderTargets(1, targets, nullptr);
	context->ClearRenderTargetView(m_renderTargetView.Get(), DirectX::Colors::Black);
	context->RSSetViewports(1, &m_viewportTexture);

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

	context->PSSetShaderResources(0, 1, &m_noiseTexture);
	auto sampler = m_samplerState.Get();
	context->PSSetSamplers(0, 1, &sampler);

	context->PSSetShader(
		m_pixelShader.Get(),
		nullptr,
		0
	);

	std::vector<float> bf{ 0.f, 0.f, 0.f, 0.f };
	context->OMSetBlendState(nullptr, bf.data(), 0xFFFFFFFF);

	context->DrawIndexed(m_indexCount, 0, 0);
}

void RayMarchingGalaxy::Render()
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

	UINT stride = sizeof(VertexPosition);
	UINT offset = 0;
	context->IASetVertexBuffers(
		0,
		1,
		m_vertexBufferQuad.GetAddressOf(),
		&stride,
		&offset
	);

	context->IASetPrimitiveTopology(D3D11_PRIMITIVE_TOPOLOGY_POINTLIST);
	context->IASetInputLayout(m_inputLayout.Get());

	context->VSSetShader(
		m_vertexShaderQuad.Get(),
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
		m_geometryShaderQuad.Get(),
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

	context->RSSetState(m_rasterizerState.Get());

	context->PSSetShaderResources(0, 1, &m_textureSRV);
	auto sampler = m_samplerStateQuad.Get();
	context->PSSetSamplers(0, 1, &sampler);

	context->PSSetShader(
		m_pixelShaderQuad.Get(),
		nullptr,
		0
	);

	// turn on the additive blending factor
	std::vector<float> bf{ 1.f, 1.f, 1.f, 1.f };
	context->OMSetBlendState(m_additiveBlending.Get(), bf.data(), 0xFFFFFFFF);

	context->Draw(1, 0); // draw one point to turn into quad

	// ubbind the sun texture that is used by the render target view to draw a new texture
	ID3D11ShaderResourceView* const pSRV[1] = { NULL };
	context->PSSetShaderResources(0, 1, pSRV);
}
