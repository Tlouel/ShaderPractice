Shader "Unlit/Line1"
{
    Properties {

        _Color ("Main Color", Color) = (1, 1, 1, 1)

        _MainTex("Main Line", 2D) = "white" {}
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

            float drawLine(float2 uv, float start, float end) {

                if((uv.x > start && uv.x < end) || (uv.y > start && uv.y < end)){
                    return 1;
                }
                return 0;
            }

            half4 frag(vertexOutput i) : COLOR {
                float4 color = tex2D(_MainTex, i.texcoord) * _Color;
                color.a = drawLine(i.texcoord.xy, 0.4, 0.6);
                return color;
        
            }

            ENDCG
        }
    }


}
