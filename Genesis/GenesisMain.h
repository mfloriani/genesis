#pragma once

#include "Common\StepTimer.h"
#include "Common\DeviceResources.h"
#include "Content\Genesis3DSceneRenderer.h"
#include "Content\FpsTextRenderer.h"

// Renders Direct2D and 3D content on the screen.
namespace Genesis
{
	class GenesisMain : public DX::IDeviceNotify
	{
	public:
		GenesisMain(const std::shared_ptr<DX::DeviceResources>& deviceResources);
		~GenesisMain();
		void CreateWindowSizeDependentResources();
		void Update();
		bool Render();

		// IDeviceNotify
		virtual void OnDeviceLost();
		virtual void OnDeviceRestored();

	private:
		// Cached pointer to device resources.
		std::shared_ptr<DX::DeviceResources> m_deviceResources;

		std::unique_ptr<Genesis3DSceneRenderer> m_sceneRenderer;
		std::unique_ptr<FpsTextRenderer> m_fpsTextRenderer;

		// Rendering loop timer.
		DX::StepTimer m_timer;
	};
}