#pragma once

#include "..\Common\DeviceResources.h"
#include "..\Common\StepTimer.h"
#include "ShaderStructures.h"

#include <memory>

namespace Genesis
{
	class RayMarching
	{
	public:
		RayMarching(const std::shared_ptr<DX::DeviceResources>& deviceResources);
		~RayMarching();

		void CreateDeviceDependentResources();
		void ReleaseDeviceDependentResources();

		void Update(DX::StepTimer const& timer, ModelViewProjCB& mvp, DirectX::XMVECTOR& camPos);
		void Render();

	private:
		std::shared_ptr<DX::DeviceResources>          m_deviceResources;

		Microsoft::WRL::ComPtr<ID3D11InputLayout>	  m_inputLayout;
		Microsoft::WRL::ComPtr<ID3D11Buffer>		  m_vertexBuffer;
		Microsoft::WRL::ComPtr<ID3D11Buffer>		  m_indexBuffer;
		Microsoft::WRL::ComPtr<ID3D11VertexShader>	  m_vertexShader;
		Microsoft::WRL::ComPtr<ID3D11PixelShader>	  m_pixelShader;
		Microsoft::WRL::ComPtr<ID3D11Buffer>		  m_MVPBuffer;
		Microsoft::WRL::ComPtr<ID3D11Buffer>		  m_perFrameBuffer;
		Microsoft::WRL::ComPtr<ID3D11RasterizerState> m_rasterizerState;

		ModelViewProjCB	m_MVPBufferData;
		PerFrameCB	    m_perFrameBufferData;
		bool            m_ready;
		unsigned int    m_indexCount;
	};

}