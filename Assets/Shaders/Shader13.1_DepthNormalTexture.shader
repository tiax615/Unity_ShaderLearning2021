Shader "ShaderLearning/Shader13.1_DepthNormalTexture"
{
    Properties
    {
        _MainTex ("Base (RGB)", 2D) = "white" {}
        _DepthNormalValue("Depth Normal Value",int)=0
    }
    SubShader{
        Pass{
            CGPROGRAM

            #include "UnityCG.cginc"
            #pragma vertex vert
            #pragma fragment frag

            sampler2D _MainTex;
            fixed _DepthNormalValue;
            sampler2D _CameraDepthTexture;
            sampler2D _CameraDepthNormalsTexture;

            struct v2f{
                float4 pos:SV_POSITION;
                half2 uv:TEXCOORD0;
            };

            v2f vert(appdata_img v){
                v2f o;
                o.pos=UnityObjectToClipPos(v.vertex);
                o.uv=v.texcoord;
                return o;
            }

            fixed4 frag(v2f i):SV_Target{
                float depth=SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture,i.uv);
                float linearDepth=Linear01Depth(depth);
                fixed3 normal=DecodeViewNormalStereo(tex2D(_CameraDepthNormalsTexture,i.uv));
                fixed4 linearDepthColor=fixed4(linearDepth,linearDepth,linearDepth,1.0);
                fixed4 normalColor=fixed4(normal*0.5+0.5,1.0);

                return lerp(linearDepthColor,normalColor,_DepthNormalValue);
            }
            
            ENDCG
        }
    }
    Fallback Off
}
