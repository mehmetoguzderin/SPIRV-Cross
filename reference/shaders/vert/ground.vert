#version 310 es

struct PatchData
{
    vec4 Position;
    vec4 LODs;
};

layout(binding = 0, std140) uniform GlobalVSData
{
    vec4 g_ViewProj_Row0;
    vec4 g_ViewProj_Row1;
    vec4 g_ViewProj_Row2;
    vec4 g_ViewProj_Row3;
    vec4 g_CamPos;
    vec4 g_CamRight;
    vec4 g_CamUp;
    vec4 g_CamFront;
    vec4 g_SunDir;
    vec4 g_SunColor;
    vec4 g_TimeParams;
    vec4 g_ResolutionParams;
    vec4 g_CamAxisRight;
    vec4 g_FogColor_Distance;
    vec4 g_ShadowVP_Row0;
    vec4 g_ShadowVP_Row1;
    vec4 g_ShadowVP_Row2;
    vec4 g_ShadowVP_Row3;
} _58;

layout(binding = 0, std140) uniform PerPatch
{
    PatchData Patches[256];
} _284;

layout(binding = 2, std140) uniform GlobalGround
{
    vec4 GroundScale;
    vec4 GroundPosition;
    vec4 InvGroundSize_PatchScale;
} _381;

layout(binding = 1) uniform mediump sampler2D TexLOD;
layout(binding = 0) uniform mediump sampler2D TexHeightmap;

layout(location = 1) in vec4 LODWeights;
layout(location = 0) in vec2 Position;
layout(location = 1) out vec3 EyeVec;
layout(location = 0) out vec2 TexCoord;

vec2 warp_position()
{
    float vlod = dot(LODWeights, _284.Patches[gl_InstanceID].LODs);
    vlod = mix(vlod, _284.Patches[gl_InstanceID].Position.w, all(equal(LODWeights, vec4(0.0))));
    float floor_lod = floor(vlod);
    float fract_lod = (vlod - floor_lod);
    uint ufloor_lod = uint(floor_lod);
    uvec2 uPosition = uvec2(Position);
    uvec2 mask = ((uvec2(1u) << uvec2(ufloor_lod, (ufloor_lod + 1u))) - uvec2(1u));
    uvec2 rounding;
    uint _332;
    uint _343;
    vec4 lower_upper_snapped;
    if ((uPosition.x < 32u))
    {
        _332 = mask.x;
    }
    else
    {
        _332 = 0u;
    }
    uint _342 = _332;
    if ((uPosition.y < 32u))
    {
        _343 = mask.y;
    }
    else
    {
        _343 = 0u;
    }
    rounding = uvec2(_342, _343);
    lower_upper_snapped = vec4(((uPosition + rounding).xyxy & (~mask).xxyy));
    return mix(lower_upper_snapped.xy, lower_upper_snapped.zw, vec2(fract_lod));
}

vec2 lod_factor(vec2 uv)
{
    float level = (textureLod(TexLOD, uv, 0.0).x * 7.96875);
    float floor_level = floor(level);
    float fract_level = (level - floor_level);
    return vec2(floor_level, fract_level);
}

void main()
{
    vec2 PatchPos = (_284.Patches[gl_InstanceID].Position.xz * _381.InvGroundSize_PatchScale.zw);
    vec2 WarpedPos = warp_position();
    vec2 VertexPos = (PatchPos + WarpedPos);
    vec2 NormalizedPos = (VertexPos * _381.InvGroundSize_PatchScale.xy);
    vec2 param = NormalizedPos;
    vec2 lod = lod_factor(param);
    vec2 Offset = (_381.InvGroundSize_PatchScale.xy * exp2(lod.x));
    float Elevation = mix(textureLod(TexHeightmap, (NormalizedPos + (Offset * 0.5)), lod.x).x, textureLod(TexHeightmap, (NormalizedPos + (Offset * 1.0)), (lod.x + 1.0)).x, lod.y);
    vec3 WorldPos = vec3(NormalizedPos.x, Elevation, NormalizedPos.y);
    WorldPos = (WorldPos * _381.GroundScale.xyz);
    WorldPos = (WorldPos + _381.GroundPosition.xyz);
    EyeVec = (WorldPos - _58.g_CamPos.xyz);
    TexCoord = (NormalizedPos + (_381.InvGroundSize_PatchScale.xy * 0.5));
    gl_Position = ((((_58.g_ViewProj_Row0 * WorldPos.x) + (_58.g_ViewProj_Row1 * WorldPos.y)) + (_58.g_ViewProj_Row2 * WorldPos.z)) + _58.g_ViewProj_Row3);
}

