Shader "ShaderLearning/Shader11.3_Water"{
    Properties{
        _MainTex("Main Tex",2D)="White"{}
        _Color("Color Tint",Color)=(1,1,1,1)
        _Magnitude("Distortion Magnitude",Float)=1 // 水流波动的幅度
        _Frequency("Distortion Frequency",Float)=1 // 水流波动的频率
        _InvWaveLength("Distortion Inverse Wave Length",Float)=10 // 波长的倒数
        _Speed("Speed",Float)=0.5
    }

    SubShader{
        // Need to disable batching because of the vertex animation
        Tags{
            "Queue"="Transparent"
            "IgnoreProjector"="True"
            "RenderType"="Transparent"
            "DisableBatching"="True" // 不使用批处理，因为要做顶点动画
        }

        Pass{
            Tags{"LightMode"="ForwardBase"}

            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha
            Cull off // 关闭剔除，让水流的每个面都能显示

            CGPROGRAM

            #pragma multi_compile_fwdbase
            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Color;
            float _Magnitude;
            float _Frequency;
            float _InvWaveLength;
            float _Speed;

            struct a2v{
                float4 vertex:POSITION;
                float4 texcoord:TEXCOORD0;
            };

            struct v2f{
                float4 pos:SV_POSITION;
                float2 uv:TEXCOORD0;
            };

            // 在顶点着色器中计算顶点动画
            v2f vert(a2v v){
                v2f o;
                
                float4 offset;
                offset.yzw=float3(0.0,0.0,0.0);
                offset.x=sin(_Frequency*_Time.y+v.vertex.x*_InvWaveLength+v.vertex.y*_InvWaveLength+v.vertex.z*_InvWaveLength)*_Magnitude;
                o.pos=UnityObjectToClipPos(v.vertex+offset);

                o.uv=TRANSFORM_TEX(v.texcoord,_MainTex);
                o.uv+=float2(0.0,_Time.y*_Speed);

                return o;
            }

            fixed4 frag(v2f i):SV_Target{
                fixed4 c=tex2D(_MainTex,i.uv);
                c.rgb*=_Color.rgb;

                return c;
            }

            ENDCG
        }
    }

    Fallback "Transparent/VertexLit"
}