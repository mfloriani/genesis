#include "pch.h"
#include "Camera.h"

using namespace DirectX;

Camera::Camera() :
	_eye(0.0f, 0.0f, 0.0f),
	_at(0.0f, 0.0f, 1.0f),
	_up(0.0f, 1.0f, 0.0f),
	_right(1.0f, 0.0f, 0.0f)
{
	
}

void Camera::Update()
{
	XMVECTOR R = XMLoadFloat3(&_right);
	XMVECTOR U = XMLoadFloat3(&_up);
	XMVECTOR L = XMLoadFloat3(&_at);
	const XMVECTOR P = XMLoadFloat3(&_eye);

	L = XMVector3Normalize(L);
	U = XMVector3Normalize(XMVector3Cross(L, R));
	R = XMVector3Cross(U, L);

	const float x = -XMVectorGetX(XMVector3Dot(P, R));
	const float y = -XMVectorGetX(XMVector3Dot(P, U));
	const float z = -XMVectorGetX(XMVector3Dot(P, L));

	XMStoreFloat3(&_right, R);
	XMStoreFloat3(&_up, U);
	XMStoreFloat3(&_at, L);

	_view(0, 0) = _right.x;
	_view(1, 0) = _right.y;
	_view(2, 0) = _right.z;
	_view(3, 0) = x;

	_view(0, 1) = _up.x;
	_view(1, 1) = _up.y;
	_view(2, 1) = _up.z;
	_view(3, 1) = y;

	_view(0, 2) = _at.x;
	_view(1, 2) = _at.y;
	_view(2, 2) = _at.z;
	_view(3, 2) = z;

	_view(0, 3) = 0.0f;
	_view(1, 3) = 0.0f;
	_view(2, 3) = 0.0f;
	_view(3, 3) = 1.0f;
}

void Camera::ResetView()
{
	_eye = XMFLOAT3(0.0f, 0.0f, 0.0f);
	_at = XMFLOAT3(0.0f, 0.0f, 1.0f);
	_up = XMFLOAT3(0.0f, 1.0f, 0.0f);
	_right = XMFLOAT3(1.0f, 0.0f, 0.0f);
}

void Camera::LookAt(const DirectX::XMFLOAT3& eye, const DirectX::XMFLOAT3& at)
{
	_eye = eye;
	_at = at;
	Update();
}

void Camera::MoveX(const float s)
{
	const XMVECTOR speed = XMVectorReplicate(_speed * s);
	const XMVECTOR eye = XMLoadFloat3(&_eye);
	const XMVECTOR right = XMLoadFloat3(&_right);

	XMStoreFloat3(&_eye, XMVectorMultiplyAdd(speed, right, eye));
}

void Camera::MoveY(const float s)
{
	const XMVECTOR speed = XMVectorReplicate(_speed * s);
	const XMVECTOR eye = XMLoadFloat3(&_eye);
	const XMVECTOR up = XMLoadFloat3(&_up);

	XMStoreFloat3(&_eye, XMVectorMultiplyAdd(speed, up, eye));
}

void Camera::MoveZ(const float s)
{
	const XMVECTOR speed = XMVectorReplicate(_speed * s);
	const XMVECTOR eye = XMLoadFloat3(&_eye);
	const XMVECTOR at = XMLoadFloat3(&_at);
	XMStoreFloat3(&_eye, XMVectorMultiplyAdd(speed, at, eye));
}

void Camera::RotateX(const float angle)
{
	const XMMATRIX R = XMMatrixRotationAxis(XMLoadFloat3(&_right), angle);

	XMStoreFloat3(&_up, XMVector3TransformNormal(XMLoadFloat3(&_up), R));
	XMStoreFloat3(&_at, XMVector3TransformNormal(XMLoadFloat3(&_at), R));
}

void Camera::RotateY(const float angle)
{
	const XMMATRIX R = XMMatrixRotationY(angle);

	XMStoreFloat3(&_right, XMVector3TransformNormal(XMLoadFloat3(&_right), R));
	XMStoreFloat3(&_up, XMVector3TransformNormal(XMLoadFloat3(&_up), R));
	XMStoreFloat3(&_at, XMVector3TransformNormal(XMLoadFloat3(&_at), R));
}