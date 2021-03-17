// A constant buffer that stores the three basic column-major matrices for composing geometry.
cbuffer ModelViewProjCB : register(b0)
{
	matrix gModel;
	matrix gView;
	matrix gProj;
	matrix gInvView;
};

float4 main( float4 pos : POSITION ) : SV_POSITION
{
	return pos;
}