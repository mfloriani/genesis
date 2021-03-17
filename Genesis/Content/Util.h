#pragma once

#include <ctime>
#include <cmath>
#include <vector>
#include <DirectXMath.h>

#include "ShaderStructures.h"

namespace Genesis
{
    // return random number between min and max
    double MinMaxRand(int min, int max);

    /**
    * return array of random points on the surface of a sphere
    * n: number of points
    * r: sphere radius
    */     
    std::vector<VertexPosition> GenerateRandomPointsOnSphere(int n, float r);
}