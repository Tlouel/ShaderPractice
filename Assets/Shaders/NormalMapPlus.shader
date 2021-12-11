Shader "Unlit/NormalMapPlus"
{
    Properties {
       
        _Color ("Main Color", Color) = (1, 1, 1, 1)

        _MainTex("Main Texture", 2D) = "white" {}

        _NormalMap("Normal Map", 2D) = "white" {}

        [KeywordEnum(Off, On)] _UseNormal("Use Normal Map ?", Float) = 0
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
            #pragma shader_feature _USENORMAL_OFF _USENORMAL_ON

            #include "PracticeLighting.cginc"
            #include "UnityCG.cginc"
            
        
            uniform half4 _Color;

            uniform sampler2D _MainTex;
            uniform float4 _MainTex_ST;

            uniform sampler2D _NormalMap;
            uniform float4 _NormalMap_ST;

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

                #if _USENORMAL_ON
                float4 tangentWorld: TEXCOORD2;
                float3 binormalWorld: TEXCOORD3;
                float4 normalTexcoord: TEXCOORD4;
                #endif
            };
 
            vertexOutput vert(vertexInput v) {
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

                return o;
            }

            half4 frag(vertexOutput i) : COLOR {

                #if _USENORMAL_ON
                float3 worldNormalAtPixel = worldNormalFromNormalMap(_NormalMap, i.normalTexcoord.xy, i.tangentWorld.xyz, i.binormalWorld.xyz, i.normalWorld.xyz);
                return float4(worldNormalAtPixel,1);

                #else
                return float4(i.normalWorld.xyz, 1);
                #endif

                //return tex2D( _MainTex, i.texcoord) * _Color;
            }
            
            ENDCG
        }
    }
}
