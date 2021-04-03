#pragma once

namespace Genesis
{

	// Constant Buffer

	// Constant buffer used to send MVP matrices to the vertex shader.
	struct ModelViewProjCB
	{
		DirectX::XMFLOAT4X4 model;
		DirectX::XMFLOAT4X4 view;
		DirectX::XMFLOAT4X4 projection;
		DirectX::XMFLOAT4X4 invView;
	};

	// Constant buffer used to send MVP matrices to the vertex shader.
	struct CameraCB
	{
		DirectX::XMFLOAT4 cameraPos;		
	};

	struct TimeCB
	{
		FLOAT			  time;
		DirectX::XMFLOAT3 pad;
	};

	struct ObjectCB
	{
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