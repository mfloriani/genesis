#pragma once

#include <map>
#include <string>

#include <d3d11.h>

#pragma comment( lib, "dxguid.lib")
#include "DDSTextureLoader.h"

class AssetManager
{
	AssetManager() = default;

	std::map<std::string, ID3D11ShaderResourceView*> m_textures;

public:
	static AssetManager& Get()
	{
		static AssetManager instance;
		return instance;
	}

	~AssetManager();

	AssetManager(AssetManager const&) = delete;
	void operator=(AssetManager const&) = delete;

public:
	bool LoadTexture(ID3D11Device* device, const std::string& filename, const std::string& id);
	ID3D11ShaderResourceView* GetTexture(const std::string& id);
};

