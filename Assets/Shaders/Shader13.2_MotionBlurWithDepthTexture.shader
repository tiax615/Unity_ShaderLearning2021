Shader "ShaderLearning/Shader13.2_MotionBlurWithDepthTexture"{
    Properties{
        _MainTex("Base (RGB)",2D)="white"{}
        _BlurSize("Blur Size",Float)=1.0
        // 没有定义上一帧和当前帧的视角*投影矩阵
        // 因为Unity没有提供矩阵类型的属性，但依然可以在CG代码块中定义
    }
    SubShader{
        CGINCLUDE

        #include "UnityCG.cginc"

        sampler2D _MainTex;
        half4 _MainTex_TexelSize;
        sampler2D _CameraDepthTexture; // 深度纹理
        float4x4 _PreviousViewProjectionMatrix; // 前一帧矩阵
        float4x4 _CurrentViewProjectionInverseMatrix; // 当前帧矩阵
        half _BlurSize;

        struct v2f{
            float4 pos:SV_POSITION;
            half2 uv:TEXCOORD0;
            half2 uv_depth:TEXCOORD1;
        };

        v2f vert(appdata_img v){
            v2f o;
            o.pos=UnityObjectToClipPos(v.vertex);
            o.uv=v.texcoord;
            o.uv_depth=v.texcoord;

            #if UNITY_UV_STARTS_AT_TOP
            if(_MainTex_TexelSize.y<0)
                o.uv_depth.y=1-o.uv_depth.y;
            #endif

            return o;
        }

        fixed4 frag(v2f i):SV_Target{
            // Get the depth buffer value at this pixel
            float d=SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture,i.uv_depth);
            // H is the viewport position at this pixel in the range -1 to 1
            float4 H=float4(i.uv.x*2-1,i.uv.y*2-1,d*2-1,1);
            // Transform by the view-projection inverse
            float4 D=mul(_CurrentViewProjectionInverseMatrix,H);
            // Divide by w to get the world position
            float4 worldPos=D/D.w;

            // Current viewport position
            float4 currentPos=H;
            // Use the world position, and transform by the previous view-projection matrix
            float4 previousPos=mul(_PreviousViewProjectionMatrix,worldPos);
            // Convert to nonhomogeneous points [-1,1] by dividing by w
            previousPos/=previousPos.w;

            // Use this frame's position and last frame's to compute the pixel velocity
            float2 velocity=(currentPos.xy-previousPos.xy)/2.0f;

            float2 uv=i.uv;
            float4 c=tex2D(_MainTex,uv);
            uv+=velocity*_BlurSize;
            for(int it=1;it<3;it++,uv+=velocity*_BlurSize){
                float4 currentColor=tex2D(_MainTex,uv);
                c+=currentColor;
            }
            c/=3;

            return fixed4(c.rgb,1.0);
        }

        ENDCG

        Pass{
            ZTest Always
            Cull Off
            ZWrite Off

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            ENDCG
        }
    }
    Fallback Off
}