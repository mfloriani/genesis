#pragma once

namespace Genesis
{

	// Constant Buffer

	struct ModelViewProjCB
	{
		DirectX::XMFLOAT4X4 model;
		DirectX::XMFLOAT4X4 view;
		DirectX::XMFLOAT4X4 projection;
		DirectX::XMFLOAT4X4 invView;
	};

	struct PerFrameCB
	{
		DirectX::XMFLOAT4 cameraPos;
		DirectX::XMFLOAT4 time;
		DirectX::XMFLOAT4 positionW;
	};

	// Vertex

	struct VertexPosition
	{
		DirectX::XMFLOAT3 positon;
	};

	// Position, Normal, Texture, Tangent, Binormal
	struct VertexPosNorTexTanBin
	{
		DirectX::XMFLOAT3 position;
		DirectX::XMFLOAT3 normal;
		DirectX::XMFLOAT3 tangent;
		DirectX::XMFLOAT3 binormal;
		DirectX::XMFLOAT2 texcoord;
	};


}