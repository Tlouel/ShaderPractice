Shader "Unlit/Texture"
{
    Properties {
       
        _Color ("Main Color", Color) = (1, 1, 1, 1)
        
        _MainTex("Main Texture", 2D) = "white" {}
        
        _NormalMap("Normal Map", 2D) = "white" {}
        
        _Diffuse("Diffuse %", Range(0, 1)) = 1

        _SpecularMap("Specular Map", 2D) = "black" {}
        _SpecularFactor("Specular %", Range(0, 1)) = 1
        _SpecularPower("Specular Power", Float) = 100

        [Toggle] _AmbientMode("Ambient Light ?", Float) = 0
        _AmbientFactor("Ambient %", Range(0, 1)) = 1

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
            #pragma shader_feature _AMBIENTMODE_OFF _AMBIENTMODE_ON


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

            #if _AMBIENTMODE_ON
            uniform float _AmbientFactor;
            #endif

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
 
            vertexOutput vert(vertexInput v) {
                vertexOutput o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.texcoord.xy = (v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw);

                #if _USENORMAL_ON
                o.normalTexcoord.xy = (v.texcoord.xy * _NormalMap_ST.xy + _NormalMap_ST.zw);
                o.normalWorld = normalize(mul(v.normal, unity_WorldToObject)); 
                o.tangentWorld = normalize(mul(unity_ObjectToWorld, v.tangent));
                o.binormalWorld = normalize(cross(o.normalWorld, o.tangentWorld) * v.tangent.w );

                #else
                o.normalWorld = float4(UnityObjectToWorldNormal(v.normal), 1);
                #endif

                o.worldPos = mul(unity_ObjectToWorld, v.vertex);

                #if _LIGHTING_VERT
                    float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                    float3 lightColor = _LightColor.xyz;
                    float attenuation = 1;
                    

                    //o.surfaceColor = float4(lambertDiffuse(o.normalWorld, lightDir, lightColor, _Diffuse, attenuation), 1.0);
                    float3 diffuseColor = lambertDiffuse(o.normalWorld, lightDir, lightColor, _Diffuse, attenuation);
                    float3 worldSpaceViewDir = normalize(_WorldSpaceCameraPos - o.worldPos);
                    float4 specularMap = tex2Dlod(_SpecularMap, float4(o.texcoord.xy, o.texcoord.w, 0));
                    float3 specularColor = specularBlinnPhong(o.normalWorld, lightDir, worldSpaceViewDir, specularMap.rgb, _SpecularFactor, attenuation, _SpecularPower);
                    
                    float3 mainTexColor = tex2Dlod(_MainTex, float4(o.texcoord.xy, o.texcoord.w, 0));
                    o.surfaceColor = float4(mainTexColor * _Color * (diffuseColor + specularColor), 1);

                        #if _AMBIENTMODE_ON
                        float3 ambientColor = _AmbientFactor * UNITY_LIGHTMODEL_AMBIENT;
                        o.surfaceColor = float4(o.surfaceColor + mainTexColor * _Color * ambientColor, 1);
                        #endif

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
                float3 mainTexColor = tex2D(_MainTex, i.texcoord.xy);

                #if _AMBIENTMODE_ON
                float3 ambientColor = _AmbientFactor * UNITY_LIGHTMODEL_AMBIENT;
                return float4(mainTexColor * _Color * (diffuseColor + specularColor + ambientColor), 1);
                #else
                return float4(mainTexColor * _Color * (diffuseColor + specularColor), 1);
                #endif

                // return float4(diffuseColor + specularColor, 1);
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

