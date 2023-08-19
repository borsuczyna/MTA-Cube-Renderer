float rand(float n) {
    return frac(sin(n) * 43758.5453123);
}

float perlinNoise(float2 pos)
{
    float2 p = floor(pos);
    float2 f = frac(pos);
    f = f * f * (3.0 - 2.0 * f);
    float n = p.x + p.y * 57.0;
    return lerp(lerp(rand(n), rand(n + 1.0), f.x),
        lerp(rand(n + 57.0), rand(n + 58.0), f.x), f.y);
}