Shader "ShaderLearning/Shader8.5_AlphaBlendZWrite"{
    Properties{
        _Color("Main Tint",Color)=(1,1,1,1)
        _MainTex("Main Tex",2D)="white"{}
        _AlphaScale("Alpha Scale",Range(0,1))=1 // 用于在透明纹理的基础上控制整体的透明度
    }

    SubShader{
        // 使用Transparent队列
        // 不受投影器（Projectors）影响
        // 归入Transparent组，表示这是使用了透明度混合的Shader
        // 使用透明度混合的Shader都应在SubShader中设置这3个标签
        Tags{"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent"}

        // Extra pass that renders to depth buffer only
        Pass{
            ZWrite On
            ColorMask 0
        }

        Pass{
            Tags{"LightMode"="ForwardBase"}

            ZWrite Off // 关闭深度写入
            Blend SrcAlpha OneMinusSrcAlpha // 开启该Pass的混合模式

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed _AlphaScale;

            struct a2v{
                float4 vertex:POSITION;
                float3 normal:NORMAL;
                float4 texcoord:TEXCOORD0;
            };

            struct v2f{
                float4 pos:SV_POSITION;
                float3 worldNormal:TEXCOORD0;
                float3 worldPos:TEXCOORD1;
                float2 uv:TEXCOORD2;
            };

            v2f vert(a2v v){
                v2f o;
                o.pos=UnityObjectToClipPos(v.vertex);
                o.worldNormal=UnityObjectToWorldNormal(v.normal);
                o.worldPos=UnityObjectToWorldDir(v.vertex);
                o.uv=TRANSFORM_TEX(v.texcoord,_MainTex);

                return o;
            }

            // 在片元着色器进行透明度测试
            fixed4 frag(v2f i):SV_Target{
                fixed3 worldNormal=normalize(i.worldNormal);
                fixed3 worldLight=normalize(UnityWorldSpaceLightDir(i.worldPos));

                fixed4 texColor=tex2D(_MainTex,i.uv);

                fixed3 albedo=texColor.rgb*_Color.rgb;
                fixed3 ambient=UNITY_LIGHTMODEL_AMBIENT.xyz*albedo;
                fixed3 diffuse=_LightColor0.rgb*albedo*max(0,dot(worldNormal,worldLight));

                // 设置了返回值中的透明通道
                return fixed4(ambient+diffuse,texColor.a*_AlphaScale);
            }

            ENDCG
        }
    }

    Fallback "Transparent/VertexLit"
}