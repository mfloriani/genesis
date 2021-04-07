#pragma once

#include "..\Common\DeviceResources.h"
#include "..\Common\StepTimer.h"

#include "ShaderStructures.h"
#include "Camera.h"
#include "StarrySky.h"
#include "TessPlanet.h"
#include "Pottery.h"
#include "NarrowStrip.h"
#include "RayTracing.h"
#include "ImplicitTerrain.h"
#include "RayMarching.h"
#include "RayMarchingSun.h"

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
		
		void ToggleWireframeMode(bool onOff);

	private:
		void HandleInput(DX::StepTimer const& timer);
		void HandleCameraInput(DX::StepTimer const& timer);
		bool QueryKeyPressed(Windows::System::VirtualKey key);

	private:
		// Cached pointer to device resources.
		std::shared_ptr<DX::DeviceResources> m_deviceResources;
		ModelViewProjCB	m_MVPBufferData;

		std::unique_ptr<Camera>          m_camera;
		std::unique_ptr<StarrySky>       m_starrySky;
		std::unique_ptr<TessPlanet>      m_tessPlanet;
		std::unique_ptr<Pottery>         m_pottery;
		std::unique_ptr<NarrowStrip>     m_narrowStrip;
		std::unique_ptr<RayTracing>      m_rayTracing;
		std::unique_ptr<ImplicitTerrain> m_implicitTerrain;
		std::unique_ptr<RayMarching>	 m_rayMarching;
		std::unique_ptr<RayMarchingSun>	 m_rayMarchingSun;
	};
}

