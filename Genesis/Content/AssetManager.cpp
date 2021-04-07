#include "pch.h"
#include "AssetManager.h"

using namespace DirectX;

AssetManager::~AssetManager()
{
	for (auto& t : m_textures)
	{
		t.second->Release();
	}
}

bool AssetManager::LoadTexture(ID3D11Device* device, const std::string& filename, const std::string& id)
{
	ID3D11ShaderResourceView* texture;

	const auto tmp = std::wstring(filename.begin(), filename.end());
	const wchar_t* const fn = tmp.c_str();

	auto hr = CreateDDSTextureFromFile(device, fn, nullptr, &texture);
	if (SUCCEEDED(hr))
	{
		m_textures.insert(std::pair<std::string, ID3D11ShaderResourceView*>(id, texture));
		texture = nullptr;

		return true;
	}

	return false;
}

ID3D11ShaderResourceView* AssetManager::GetTexture(const std::string& id)
{
	auto it = m_textures.find(id);
	if (it != m_textures.end())
		return it->second;

	return nullptr;
}
