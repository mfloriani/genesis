#include "pch.h"
#include "Util.h"

using namespace Genesis;
using namespace DirectX;

double Genesis::MinMaxRand(int min, int max)
{
    return ((double)rand() / ((double)RAND_MAX + 1.0)) * (max - min) + min;
}

std::vector<VertexPosition> Genesis::GenerateRandomPointsOnSphere(int n, float r)
{
    std::vector<VertexPosition> points(n);

    double theta = 0, phi = 0;
    for (int i = 0; i < n; i++)
    {
        theta = 2 * DirectX::XM_PI * MinMaxRand(0, 1);
        phi = acos(2 * MinMaxRand(0, 1) - 1.0);

        float x = r * static_cast<float>(cos(theta) * sin(phi));
        float y = r * static_cast<float>(sin(theta) * sin(phi));
        float z = r * static_cast<float>(cos(phi));

        points[i].pos = DirectX::XMFLOAT3(x, y, z);
    }

    return points;
}
