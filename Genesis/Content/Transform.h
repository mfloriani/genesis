#pragma once

#include <DirectXMath.h>

struct Transform
{
	DirectX::XMFLOAT3 position;
	DirectX::XMFLOAT3 rotation;
	DirectX::XMFLOAT3 scale;

	Transform() : position({ 0.0f, 0.0f, 0.0f }), rotation({ 0.0f, 0.0f, 0.0f }), scale({ 1.0f, 1.0f, 1.0f }) {}
	Transform(const DirectX::XMFLOAT3& p, const DirectX::XMFLOAT3& r, const DirectX::XMFLOAT3& s) : position(p), rotation(r), scale(s) {}
};