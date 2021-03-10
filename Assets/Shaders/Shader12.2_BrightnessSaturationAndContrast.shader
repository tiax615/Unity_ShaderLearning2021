Shader "ShaderLearning/Shader12.2_BrightnessSaturationAndContrast"{
    Properties{
        _MainTex("Base (RGB)",2D)="white"{}
        _Brightness("Brightness",Float)=1
        _Saturation("Saturation",Float)=1
        _Contrast("Contrast",Float)=1
    }

    SubShader{
        Pass{
            // 这些状态设置可以认为是后处理的“标配”
            ZTest Always
            Cull Off
            ZWrite Off

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            sampler2D _MainTex;
            half _Brightness;
            half _Saturation;
            half _Contrast;

            struct v2f{
                float4 pos:SV_POSITION;
                half2 uv:TEXCOORD0;
            };

            // appdata_img只包含顶点坐标和坐标纹理
            v2f vert(appdata_img v){
                v2f o;
                o.pos=UnityObjectToClipPos(v.vertex);
                o.uv=v.texcoord;
                return o;
            }

            fixed4 frag(v2f i):SV_Target{
                fixed4 renderTex=tex2D(_MainTex,i.uv);

                // Apply brightness
                fixed3 finalColor=renderTex.rgb*_Brightness;

                // Apply saturation
                fixed luminace=0.2125*renderTex.r+0.7154*renderTex.g+0.0721*renderTex.b;
                fixed3 luminanceColor=fixed3(luminace,luminace,luminace);
                finalColor=lerp(luminanceColor,finalColor,_Saturation);

                // Apply contrast
                fixed3 avgColor=fixed3(0.5,0.5,0.5);
                finalColor=lerp(avgColor,finalColor,_Contrast);

                return fixed4(finalColor,renderTex.a);
            }

            ENDCG
        }
    }
    Fallback Off
}