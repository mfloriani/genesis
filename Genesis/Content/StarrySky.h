#pragma once

#include "..\Common\DeviceResources.h"
#include "..\Common\StepTimer.h"
#include "ShaderStructures.h"

#include <memory>

namespace Genesis
{
	class StarrySky
	{
	public:
		StarrySky(const std::shared_ptr<DX::DeviceResources>& deviceResources);
		~StarrySky();

		void CreateDeviceDependentResources();
		void ReleaseDeviceDependentResources();

		void Update(DX::StepTimer const& timer, ModelViewProjCB& mvp);
		void Render();

	private:
		std::shared_ptr<DX::DeviceResources>        m_deviceResources;

		Microsoft::WRL::ComPtr<ID3D11InputLayout>	m_inputLayout;
		Microsoft::WRL::ComPtr<ID3D11Buffer>		m_vertexBuffer;
		Microsoft::WRL::ComPtr<ID3D11VertexShader>	m_vertexShader;
		Microsoft::WRL::ComPtr<ID3D11GeometryShader>m_geometryShader;
		Microsoft::WRL::ComPtr<ID3D11PixelShader>	m_pixelShader;
		Microsoft::WRL::ComPtr<ID3D11Buffer>		m_constantBuffer;
		Microsoft::WRL::ComPtr<ID3D11BlendState>    m_additiveBlending;

		ModelViewProjCB	m_MVPBufferData;
		bool            m_ready;
		unsigned int    m_indexCount;
};

}