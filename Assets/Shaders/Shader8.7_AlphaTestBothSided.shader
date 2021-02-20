Shader "ShaderLearning/Shader8.7_AlphaTestBothSided"{
    Properties{
        _Color("Main Tint",Color)=(1,1,1,1)
        _MainTex("Main Tex",2D)="white"{}
        _Cutoff("Alpha Cutoff",Range(0,1))=0.5 // 调用clip进行透明度测试的判断条件
    }

    SubShader{
        // 使用AlphaTest队列
        // 不受投影器（Projectors）影响
        // 归入TransparentCutout组，表示这是使用了透明度测试的Shader
        // 使用透明度测试的Shader都应在SubShader中设置这3个标签
        Tags{"Queue"="AlphaTest" "IgnoreProjector"="True" "RenderType"="TranspparentCutout"}

        Pass{
            Tags{"LightMode"="ForwardBase"}

            // Turn off culling
            Cull Off

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed _Cutoff;

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

                // Alpha test
                clip(texColor.a-_Cutoff);
                // Equal to
                // if((texColor.a-_Cutoff)<0.0){discard;}

                fixed3 albedo=texColor.rgb*_Color.rgb;
                fixed3 ambient=UNITY_LIGHTMODEL_AMBIENT.xyz*albedo;
                fixed3 diffuse=_LightColor0.rgb*albedo*max(0,dot(worldNormal,worldLight));

                return fixed4(ambient+diffuse,1.0);
            }

            ENDCG
        }
    }

    Fallback "Transparent/Cutout/VertexLit" // 还可以保证使用透明度测试的物体可以正确向其他物体投射阴影
}