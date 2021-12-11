Shader "Unlit/Specular"
{
    Properties {
       
        _Color ("Main Color", Color) = (1, 1, 1, 1)
        
        _MainTex("Main Texture", 2D) = "white" {}
        
        _NormalMap("Normal Map", 2D) = "white" {}
        
        _Diffuse("Diffuse %", Range(0, 1)) = 1

        _SpecularMap("Specular Map", 2D) = "black" {}
        _SpecularFactor("Specular %", Range(0, 1)) = 1
        _SpecularPower("Specular Power", Float) = 100


        [KeywordEnum(Off, On)] _UseNormal("Use Normal Map?", Float) = 0
        [KeywordEnum(Off, Vert, Frag)] _Lighting("Lighting Mode", Float) = 0
    }

    Subshader {
        
        Tags {
            "Queue" = "Transparent"
            "RenderType" = "Transparent"
            "IgnoreProjector" = "True"
            "LightMode" = "ForwardBase"
        }

        Pass {
            Tags {"LightMode" = "ForwardBase"}
            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature _USENORMAL_OFF _USENORMAL_ON
            #pragma shader_feature _LIGHTING_OFF _LIGHTING_VERT _LIGHTING_FRAG


            #include "Assets/Shaders/PracticeLighting.cginc"
            #include "UnityCG.cginc"
            
        
            uniform half4 _Color;

            uniform sampler2D _MainTex;
            uniform float4 _MainTex_ST;

            uniform sampler2D _NormalMap;
            uniform float4 _NormalMap_ST;

            uniform float _Diffuse;
            uniform float4 _LightColor;

            uniform sampler2D _SpecularMap;
            uniform float _SpecularFactor;
            uniform float _SpecularPower;

            struct vertexInput {
                float4 vertex: POSITION;
                float4 normal: NORMAL;
                float4 texcoord: TEXCOORD;

                #if _USENORMAL_ON
                float4 tangent: TANGENT;
                #endif
            };
 
            struct vertexOutput {
                float4 pos: SV_POSITION;
                float4 texcoord: TEXCOORD;
                float4 normalWorld: TEXCOORD1;
                float4 worldPos: TEXCOORD5;

                #if _USENORMAL_ON
                float4 tangentWorld: TEXCOORD2;
                float3 binormalWorld: TEXCOORD3;
                float4 normalTexcoord: TEXCOORD4;
                #endif

                #if _LIGHTING_VERT
                float4 surfaceColor: COLOR;
                #endif
            };

            // float3 specularBlinnPhong(float3 normal, float3 lightDir, float3 worldSpaceViewDir, float3 specularColor, float specularFactor, float attenuation, float specularPower) {
            //     float3 halfwayDir = normalize(lightDir + worldSpaceViewDir);

            //     return specularColor * specularFactor * attenuation * pow(max(0, dot(normal, halfwayDir)), specularPower);
            // }
 
            vertexOutput vert(vertexInput v){
                vertexOutput o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.texcoord.xy = (v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw);

                #if _USENORMAL_ON
                o.normalTexcoord.xy = (v.texcoord.xy * _NormalMap_ST.xy + _NormalMap_ST.zw);
                o.normalWorld = normalize(mul(v.normal, unity_WorldToObject)); // Reverse order of multiplication to transpose
                o.tangentWorld = normalize(mul(unity_ObjectToWorld, v.tangent));
                o.binormalWorld = normalize(cross(o.normalWorld, o.tangentWorld) * v.tangent.w );

                #else
                o.normalWorld = float4(UnityObjectToWorldNormal(v.normal), 1);
                #endif

                o.worldPos = mul(unity_ObjectToWorld, v.vertex);

                #if _LIGHTING_VERT
                float3 lightDir = normalize(_WorldSpaceLightPos0);
                float3 lightColor = _LightColor.xyz;
                float attenuation = 1;
                

                //o.surfaceColor = float4(lambertDiffuse(o.normalWorld, lightDir, lightColor, _Diffuse, attenuation), 1.0);
                float3 diffuseColor = lambertDiffuse(o.normalWorld, lightDir, lightColor, _Diffuse, attenuation);
                float3 worldSpaceViewDir = normalize(_WorldSpaceCameraPos - o.worldPos);
                float4 specularMap = tex2Dlod(_SpecularMap, float4(o.texcoord.xy, o.texcoord.w, 0));
                float3 specularColor = specularBlinnPhong(o.normalWorld, lightDir, worldSpaceViewDir, specularMap.rgb, _SpecularFactor, attenuation, _SpecularPower);
                o.surfaceColor = float4(diffuseColor + specularColor, 1);
                #endif

                return o;
            }


            half4 frag(vertexOutput i) : COLOR {

                #if _USENORMAL_ON
                float3 worldNormalAtPixel = worldNormalFromNormalMap(_NormalMap, i.normalTexcoord.xy, i.tangentWorld.xyz, i.binormalWorld.xyz, i.normalWorld.xyz);
                //return float4(worldNormalAtPixel,1);

                #else
                float3 worldNormalAtPixel = i.normalWorld.xyz;
                #endif

                #if _LIGHTING_FRAG
                float3 lightDir = normalize(_WorldSpaceLightPos0);
                float3 lightColor = _LightColor.xyz;
                float attenuation = 1;
                //return float4(lambertDiffuse(worldNormalAtPixel, lightDir, lightColor, _Diffuse, attenuation), 1.0);
                
                float3 diffuseColor = lambertDiffuse(worldNormalAtPixel, lightDir, lightColor, _Diffuse, attenuation);
                float3 worldSpaceViewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
                float4 specularMap = tex2Dlod(_SpecularMap, float4(i.texcoord.xy, i.texcoord.w, 0));
                float3 specularColor = specularBlinnPhong(worldNormalAtPixel, lightDir, worldSpaceViewDir, specularMap.rgb, _SpecularFactor, attenuation, _SpecularPower);

                return float4(diffuseColor + specularColor, 1);

                #elif _LIGHTING_VERT
                return i.surfaceColor;

                #else
                return float4(worldNormalAtPixel, 1);
                #endif

                //return tex2D( _MainTex, i.texcoord) * _Color;
            }
            
            ENDCG
        }
    }
}
