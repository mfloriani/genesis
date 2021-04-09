#pragma once

#include "..\Common\DeviceResources.h"
#include "..\Common\StepTimer.h"

#include "ShaderStructures.h"
#include "Transform.h"

#include <memory>

namespace Genesis
{
	class RayMarchingGalaxy
	{
	public:
		RayMarchingGalaxy(const std::shared_ptr<DX::DeviceResources>& deviceResources);
		~RayMarchingGalaxy();

		void CreateDeviceDependentResources();
		void ReleaseDeviceDependentResources();

		void Update(DX::StepTimer const& timer, ModelViewProjCB& mvp, DirectX::XMVECTOR& camPos);
		void Render();
		void RenderToTexture();

		DirectX::XMFLOAT3 Position() const { return m_transform.position; }

	private:
		std::shared_ptr<DX::DeviceResources>             m_deviceResources;

		Microsoft::WRL::ComPtr<ID3D11InputLayout>	     m_inputLayout;
		Microsoft::WRL::ComPtr<ID3D11Buffer>		     m_vertexBuffer;
		Microsoft::WRL::ComPtr<ID3D11Buffer>		     m_indexBuffer;
		Microsoft::WRL::ComPtr<ID3D11Buffer>		     m_vertexBufferQuad;
		Microsoft::WRL::ComPtr<ID3D11VertexShader>	     m_vertexShader;
		Microsoft::WRL::ComPtr<ID3D11PixelShader>	     m_pixelShader;
		Microsoft::WRL::ComPtr<ID3D11Buffer>		     m_MVPBuffer;
		Microsoft::WRL::ComPtr<ID3D11Buffer>		     m_perFrameBuffer;
		Microsoft::WRL::ComPtr<ID3D11RasterizerState>    m_rasterizerState;
		Microsoft::WRL::ComPtr<ID3D11SamplerState>       m_samplerState;
		Microsoft::WRL::ComPtr<ID3D11BlendState>		 m_additiveBlending;
		Microsoft::WRL::ComPtr<ID3D11SamplerState>       m_samplerStateQuad;
		Microsoft::WRL::ComPtr<ID3D11VertexShader>	     m_vertexShaderQuad;
		Microsoft::WRL::ComPtr<ID3D11GeometryShader>	 m_geometryShaderQuad;
		Microsoft::WRL::ComPtr<ID3D11PixelShader>	     m_pixelShaderQuad;
		Microsoft::WRL::ComPtr<ID3D11RenderTargetView>   m_renderTargetView;
		Microsoft::WRL::ComPtr<ID3D11DepthStencilView>   m_depthStencilView;
		Microsoft::WRL::ComPtr<ID3D11ShaderResourceView> m_shaderResourceView;
		D3D11_VIEWPORT                                   m_viewportTexture;

		ID3D11ShaderResourceView* m_noiseTexture;
		ID3D11ShaderResourceView* m_textureSRV;

		ModelViewProjCB	m_MVPBufferData;
		PerFrameCB	    m_perFrameBufferData;
		bool            m_ready;
		unsigned int    m_indexCount;

		Transform m_transform;
	};

}