//
//  Water.metal
//  LowPolyWater
//
//  Created by Teemu Harju on 27/01/2019.
//  Copyright © 2019 Teemu Harju. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

#include <SceneKit/scn_metal>

typedef struct {
    float4 position [[ attribute(SCNVertexSemanticPosition) ]];
} vertex_t;

typedef struct {
    float4 fragmentPosition [[ position ]];
    float3 color [[ flat ]];
    float displacement;
    float amplitude;
} io_t;

typedef struct {
    float4x4 modelTransform;
    float4x4 modelViewProjectionTransform;
} node_t;

// Random

/**
 * Generate a random float in the range [0.0f, 1.0f] using x, y, and z (based on the xor128 algorithm)
 *
 * Taken from Apple's Wood Shader example.
 * https://github.com/robovm/apple-ios-samples/blob/master/MetalShaderShowcase/MetalShaderShowcase/AAPLWoodShader.metal
 */
float rand3dTo1d(float3 value)
{
    int seed = value.x + value.y * 57 + value.z * 241;
    seed= (seed<< 13) ^ seed;
    return (( 1.0 - ( (seed * (seed * seed * 15731 + 789221) + 1376312589) & 2147483647) / 1073741824.0f) + 1.0f) / 2.0f;
}

// Interpolation

float easeIn(float interpolator){
    return interpolator * interpolator;
}

float easeOut(float interpolator){
    return 1 - easeIn(1 - interpolator);
}

float easeInOut(float interpolator){
    float easeInValue = easeIn(interpolator);
    float easeOutValue = easeOut(interpolator);
    return mix(easeInValue, easeOutValue, interpolator);
}

// 3D noise

float3 rand3dTo3d(float3 value){
    return float3(rand3dTo1d(value),
                  rand3dTo1d(value),
                  rand3dTo1d(value));
}

/**
 * Generates Perlin noise over time with custom cell size.
 *
 * Implementation based on Ronja's Shader Tutorials.
 * https://www.ronja-tutorials.com/2018/09/15/perlin-noise.html
 */
float3 perlinNoise(float3 pos, float time, float cellSize) {
    float3 value = pos / cellSize;
    value.z += time;
    float3 fraction = fract(value);

    float interpolatorX = easeInOut(fraction.x);
    float interpolatorY = easeInOut(fraction.y);
    float interpolatorZ = easeInOut(fraction.z);

    float3 cellNoiseZ[2];
    for (int z = 0; z <= 1; z++) {
        float3 cellNoiseY[2];
        for (int y = 0; y <= 1; y++) {
            float3 cellNoiseX[2];
            for (int x = 0; x <= 1; x++) {
                float3 cell = floor(value) + float3(x, y, z);
                float3 cellDirection = rand3dTo3d(cell) * 2 - 1;
                float3 compareVector = fraction - float3(x, y, z);
                cellNoiseX[x] = dot(cellDirection, compareVector);
            }
            cellNoiseY[y] = mix(cellNoiseX[0], cellNoiseX[1], interpolatorX);
        }
        cellNoiseZ[z] = mix(cellNoiseY[0], cellNoiseY[1], interpolatorY);
    }

    float3 noise = mix(cellNoiseZ[0], cellNoiseZ[1], interpolatorZ);

    return noise + 0.5;
}

/**
 * Vertex shader for deforming a square plane to look like "low-poly" water.
 *
 * Does displacement using Perlin noise based on world coordinates, so it is
 * tileable, meaning multiple square planes can be placed next to each other
 * to cover larger area and utilize frustum culling if zooming close up.
 *
 * Updates normals after displacement and calculates simple lighting for each
 * triangle.
 *
 * Passes displacement value to the fragment shader for implementing a water
 * foam effect.
 */
vertex io_t water_vertex(vertex_t in [[ stage_in ]],
                         constant SCNSceneBuffer& scn_frame [[ buffer(0) ]],
                         constant node_t& scn_node [[ buffer(1) ]],
                         constant float3& lightPosition [[ buffer(2) ]],
                         constant float& speed [[ buffer(3) ]],
                         constant float& amplitude [[ buffer(4) ]],
                         constant float& cellSize [[ buffer(5) ]]) {

    float4 worldPos = scn_node.modelTransform * in.position;

    float3 worldPos0 = worldPos.xyz;
    float3 worldPos1 = worldPos.xyz;
    float3 worldPos2 = worldPos.xyz;

    // We know the exact size of the plane and it's triangles. So we can assume
    // the position of the other vertices of the triangle before the displacement.
    worldPos1 += float3(128.0, 0.0, 0.0);
    worldPos2 += float3(0.0, 128.0, 0.0);

    float time = scn_frame.time * 0.5 * speed;

    // We calculate displacement of all vertices in a triangle so that we can
    // calculate the lightning after the displacement.
    worldPos0.z += perlinNoise(worldPos0.xyz, time, cellSize).z * amplitude;
    worldPos1.z += perlinNoise(worldPos1.xyz, time, cellSize).z * amplitude;
    worldPos2.z += perlinNoise(worldPos2.xyz, time, cellSize).z * amplitude;

    float3 u = worldPos1 - worldPos0;
    float3 v = worldPos2 - worldPos0;

    float3 normal = normalize(cross(u, v));

    io_t _output;
    _output.fragmentPosition = scn_frame.viewProjectionTransform * float4(worldPos0, 1.0);
    _output.displacement = worldPos0.z;
    _output.amplitude = amplitude;

    // Lambert shading
    float light = saturate(dot(normalize(lightPosition), normal));
    _output.color = float3(0.0, 0.2, 1.0) * light;

    return _output;
}

/**
 * Fragment shader for generating a "foam" effect for the water.
 */
fragment half4 water_fragment(io_t in [[ stage_in ]]) {
    float4 color = float4(in.color, 1.0);

    // Create "foam" by making the color whiter based on the amount
    // of displacement.
    float d = in.displacement;
    color.rgb += step(in.amplitude - 3.0, float3(d, d, d)) * 0.2;
    color.rgb += step(in.amplitude - 2.0, float3(d, d, d)) * 0.2;
    color.rgb += step(in.amplitude - 1.0, float3(d, d, d)) * 0.2;

    return half4(color);
}

