#pragma once

#include "..\Common\DeviceResources.h"
#include "..\Common\StepTimer.h"
#include "ShaderStructures.h"

#include <memory>

namespace Genesis
{
	class RayMarchingSun
	{
	public:
		RayMarchingSun(const std::shared_ptr<DX::DeviceResources>& deviceResources);
		~RayMarchingSun();

		void CreateDeviceDependentResources();
		void ReleaseDeviceDependentResources();

		void Update(DX::StepTimer const& timer, ModelViewProjCB& mvp, DirectX::XMVECTOR& camPos);
		void Render();

	private:
		std::shared_ptr<DX::DeviceResources>             m_deviceResources;
													     
		Microsoft::WRL::ComPtr<ID3D11InputLayout>	     m_inputLayout;
		Microsoft::WRL::ComPtr<ID3D11Buffer>		     m_vertexBuffer;
		Microsoft::WRL::ComPtr<ID3D11Buffer>		     m_indexBuffer;
		Microsoft::WRL::ComPtr<ID3D11VertexShader>	     m_vertexShader;
		Microsoft::WRL::ComPtr<ID3D11PixelShader>	     m_pixelShader;
		Microsoft::WRL::ComPtr<ID3D11Buffer>		     m_MVPBuffer;
		Microsoft::WRL::ComPtr<ID3D11Buffer>		     m_cameraBuffer;
		Microsoft::WRL::ComPtr<ID3D11Buffer>		     m_timeBuffer;
		Microsoft::WRL::ComPtr<ID3D11RasterizerState>    m_rasterizerState;
		Microsoft::WRL::ComPtr<ID3D11SamplerState>       m_samplerState;

		ID3D11ShaderResourceView* m_noiseTexture;

		ModelViewProjCB	m_MVPBufferData;
		CameraCB	    m_cameraBufferData;
		TimeCB		    m_timeBufferData;
		bool            m_ready;
		unsigned int    m_indexCount;
	};

}