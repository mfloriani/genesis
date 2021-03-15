#pragma once

#include "Transform.h"

struct CameraSettings
{
	DirectX::XMFLOAT3 eye;
	DirectX::XMFLOAT3 at;
};

class Camera
{
	DirectX::XMFLOAT3   _eye;
	DirectX::XMFLOAT3   _at;
	DirectX::XMFLOAT3   _up;
	DirectX::XMFLOAT3   _right;
	DirectX::XMFLOAT4X4 _view;

	const float _speed = 10.0f;

public:

	Camera();
	~Camera() = default;

	void ResetView();

	const DirectX::XMFLOAT3& Eye() const { return _eye; };
	const DirectX::XMFLOAT3& At() const { return _at; };
	const DirectX::XMFLOAT3& Up() const { return _up; };



	void Eye(const DirectX::XMFLOAT3& eye) { _eye = eye; };
	void LookAt(const DirectX::XMFLOAT3& eye, const DirectX::XMFLOAT3& at);

	void Update();

	void MoveX(const float s);
	void MoveY(const float s);
	void MoveZ(const float s);
	void RotateX(const float angle);
	void RotateY(const float angle);

	const DirectX::XMMATRIX View() const { return DirectX::XMLoadFloat4x4(&_view); }

};