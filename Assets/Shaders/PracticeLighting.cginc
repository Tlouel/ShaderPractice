#ifndef PracticeLighting
#define PracticeLighting

float3 normalFromColor(float4 color) {
    #if defined(UNITY_NO_DXT5nm)
    return color.xyz;

    # else
    
    float3 normal = float3(color.a, color.g, 0.0);
    normal.z = sqrt(1 - dot(normal, normal));
    return normal;
    #endif
}
            
float3 worldNormalFromNormalMap(sampler2D normalMap, float2 normalTexCoord, float3 tangentWorld, float3 binormalWorld, float3 normalWorld) {
        // Color at Pixel which we read from Tangent space normal map
        float4 colorAtPixel = tex2D(normalMap, normalTexCoord);
        
        // Normal value converted from Color value
        float3 normalAtPixel = normalFromColor(colorAtPixel);
        
        
        float3x3 TBNWorld = float3x3(tangentWorld, binormalWorld, normalWorld);
        return normalize(mul(normalAtPixel, TBNWorld));	
}

float3x3 mat4toMat3(float4x4 mat4) {
    
    return float3x3 ( 
       
        mat4[0][0], mat4[0][1], mat4[0][2],
        mat4[1][0], mat4[1][1], mat4[1][2],
        mat4[2][0], mat4[2][1], mat4[2][2]
    );
}

float3 lambertDiffuse(float3 normal, float3 lightDir, float3 lightColor, float diffuseFactor, float attenuation) {

    return lightColor * diffuseFactor * attenuation * max(0, dot(normal, lightDir));
}

float3 specularBlinnPhong(float3 normal, float3 lightDir, float3 worldSpaceViewDir, float3 specularColor, float specularFactor, float attenuation, float specularPower) {
    float3 halfwayDir = normalize(lightDir + worldSpaceViewDir);
    
    return specularColor * specularFactor * attenuation * pow(max(0, dot(normal, halfwayDir)), specularPower);
}

#endif