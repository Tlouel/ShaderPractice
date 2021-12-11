Shader "Unlit/Sqrt"
{
    Properties {

        _Color ("Main Color", Color) = (1, 1, 1, 1)
        
    }

    SubShader {
        
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

            half4 frag(vertexOutput i) : COLOR {
               float4 color = tex2D(_MainTex, i.texcoord * 20) * _Color;
               color.a = sqrt(i.texcoord.x);
               return color;
        
            }

            ENDCG
        }
    }


}
