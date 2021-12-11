// COURS NOTES

// * simuler l'orientation des poly avec une texture / code : orientation x de la normal r | normal y sur g et normal z sur b
// * dans quel espace exprimer ? Les coord de la lumière exprimées en coord monde dans le jeu, on peut utiliser les coord de la lumière si l'objet est immobile.
// * exprimer obj space : orientation par rapport à l'objet.
// * reconvertir par des matrices obj -> monde (multiplication)
// * tangent space : normal map par rapport à l'orientation du triangle (locale)
// * binormal = perpendiculaire à tan et normal
// * txt normal tangent space = récupérer la normal world space

Shader "Unlit/NormalMap"
{
    Properties
    {
        _Color ("Main Color", Color) = (1, 1, 1, 1)

        _MainTex("Main Texture", 2D) = "white" {}

        _NormalMap("Normal Map", 2D) = "white" {}
    }

    Subshader {
        
        Tags {
            "Queue" = "Transparent"
            "RenderType" = "Transparent"
            "IgnoreProjector" = "True"
        }

        Pass {
            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            uniform half4 _Color;
            uniform sampler2D _MainTex;
            uniform float4 _MainTex_ST;

            uniform sampler2D _NormalMap;
            uniform float4 _NormalMap_ST;

            struct vertexInput {
                float4 vertex: POSITION;
                float4 normal: NORMAL;
                float4 tangent: TANGENT;
                float4 texcoord: TEXCOORD0;
            };
 
            struct vertexOutput {
                float4 pos: SV_POSITION;
                float4 texcoord: TEXCOORD;
                float4 normalWorld: TEXCOORD1;
                float4 tangentWorld: TEXCOORD2;
                float3 binormalWorld: TEXCOORD3;
                float4 normalTexcoord: TEXCOORD4;
            };
 
            vertexOutput vert(vertexInput v) {
                vertexOutput o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.texcoord.xy = (v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw);

                o.normalTexcoord.xy = (v.texcoord.xy * _NormalMap_ST.xy + _NormalMap_ST.zw);

                o.normalWorld = normalize(mul(v.normal, unity_WorldToObject));
                o.tangentWorld = normalize(mul(unity_ObjectToWorld, v.tangent));
                o.binormalWorld = normalize( cross(o.normalWorld, o.tangentWorld) * v.tangent.w );

                return o;
            }
 
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
                float4 colorAtPixel = tex2D(normalMap, normalTexCoord);
                float3 normalAtPixel = normalFromColor(colorAtPixel);
                float3x3 TBNWorld = float3x3(tangentWorld, binormalWorld, normalWorld);
                
                return normalize(mul(normalAtPixel, TBNWorld));	
            }

            half4 frag(vertexOutput i) : COLOR {
                float3 worldNormalAtPixel = worldNormalFromNormalMap(_NormalMap, i.normalTexcoord.xy, i.tangentWorld.xyz, i.binormalWorld.xyz, i.normalWorld.xyz);
                return float4(worldNormalAtPixel,1);
                //return tex2D( _MainTex, i.texcoord) * _Color;
            }
            
            ENDCG
        }
    }
}
