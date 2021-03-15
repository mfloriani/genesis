#pragma once

#include "..\Common\DeviceResources.h"
#include "..\Common\StepTimer.h"
#include "ShaderStructures.h"
#include "Camera.h"
#include "StarrySky.h"

#include <memory>

namespace Genesis
{
	class Genesis3DSceneRenderer
	{
	public:
		Genesis3DSceneRenderer(const std::shared_ptr<DX::DeviceResources>& deviceResources);
		void CreateDeviceDependentResources();
		void CreateWindowSizeDependentResources();
		void ReleaseDeviceDependentResources();
		void Update(DX::StepTimer const& timer);
		void Render();
		
	private:
		void HandleInput(DX::StepTimer const& timer);
		void HandleCameraInput(DX::StepTimer const& timer);
		bool QueryKeyPressed(Windows::System::VirtualKey key);

	private:
		// Cached pointer to device resources.
		std::shared_ptr<DX::DeviceResources> m_deviceResources;
		ModelViewProjCB	m_MVPBufferData;

		std::unique_ptr<Camera>    m_camera;
		std::unique_ptr<StarrySky> m_starrySky;


	};
}

