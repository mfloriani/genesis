#pragma once

namespace Genesis
{
	// Constant buffer used to send MVP matrices to the vertex shader.
	struct ModelViewProjCB
	{
		DirectX::XMFLOAT4X4 model;
		DirectX::XMFLOAT4X4 view;
		DirectX::XMFLOAT4X4 projection;
		DirectX::XMFLOAT4X4 invView;
	};

	// Used to send per-vertex data to the vertex shader.
	struct VertexPositionColor
	{
		DirectX::XMFLOAT3 pos;
		DirectX::XMFLOAT3 color;
	};

	struct VertexPosition
	{
		DirectX::XMFLOAT3 pos;
	};
}