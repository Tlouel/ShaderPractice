Shader "Unlit/CircleFade"
{
    Properties {

        _Color ("Main Color", Color) = (1, 1, 1, 1)

        _MainTex("Main Texture", 2D) = "white" {}

        _Feather("Feather", Range(0, 0.5)) = 0.05

        
    }

    SubShader{
        
        Tags {
            
            "Queue" = "Transparent"
            "RenderType"="Transparent"
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

            uniform float _Feather;

            struct vertexInput {
                float4 vertex: POSITION;
                float4 texcoord: TEXCOORD;
            };

            struct vertexOutput {
                float4 pos: SV_POSITION;
                float4 texcoord: TEXCOORD;
            };

        
            vertexOutput vert(vertexInput v) {
                vertexOutput o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.texcoord.xy = (v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw);
                return o;
                
            }


            float drawCircle(float2 uv, float2 center, float radius, float feather) {
                float circle = pow((uv.y - center.y), 2) + pow((uv.x - center.x), 2);
                float radiusSquare = pow(radius, 2);

                if((circle < radiusSquare + 0.01) && (circle > radiusSquare - 0.01)) {
                    return 1;
                
                }

                if(circle < radiusSquare) {

                    return smoothstep(radiusSquare, radiusSquare - feather, circle);
                }
                return 0;

            }

            half4 frag(vertexOutput i) : COLOR {
                
                return tex2D(_MainTex, i.texcoord) * _Color;
        
            } 
            
            

            ENDCG
        }
    }


}
