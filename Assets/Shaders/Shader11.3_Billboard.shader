Shader "ShaderLearning/Shader11.3_Billboard"{
    Properties{
        _MainTex("Main Tex",2D)="White"{}
        _Color("Color Tint",Color)=(1,1,1,1)
        _VerticalBillboarding("Vertical Restraints",Range(0,1))=1 // 调整固定法线还是固定向上方向
    }

    SubShader{
        // Need to disable batching because of the vertex animation
        Tags{"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "DisableBatching"="True"}

        Pass{
            Tags{"LightMode"="ForwardBase"}

            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha
            Cull Off

            CGPROGRAM

            #pragma multi_compile_fwdbase
            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Color;
            fixed _VerticalBillboarding;

            struct a2v{
                float4 vertex:POSITION;
                float4 texcoord:TEXCOORD0;
            };

            struct v2f{
                float4 pos:SV_POSITION;
                float2 uv:TEXCOORD0;
            };

            // 在模型空间计算3个新的正交基
            v2f vert(a2v v){
                v2f o;

                // Suppose the center in object space is fixed
                // 选择模型空间的原点作为广告牌的锚点
                float3 center=float3(0,0,0);
                // 获取模型空间下的视角位置
                float3 viewer=mul(unity_WorldToObject,float4(_WorldSpaceCameraPos,1));

                float3 normalDir=viewer-center;
                // If _VerticalBillboarding equals 1, we use the desired view dir as the normal dir
                // Which means the normal dir is fixed
                // Or if _VerticalBillboarding equals 0, the y of normal is 0
                // Which means the up dir is fixed
                // 如果_VerticalBillboarding是1，认为法线固定
                // 如果_VerticalBillboarding是0，认为向上固定
                normalDir.y=normalDir.y*_VerticalBillboarding;
                normalDir=normalize(normalDir);

                // Get the approximate up dir
                // If normal dir is already towards up, then the up dir is towards front
                // 得到近似的向上方向
                // 如果法线已经向上，那么向上方向应该朝前
                float3 upDir=abs(normalDir.y)>0.999?float3(0,0,1):float3(0,1,0);
                float3 rightDir=normalize(cross(upDir,normalDir));
                upDir=normalize(cross(normalDir,rightDir));

                // 根据原始的位置相对于锚点的偏移量以及3个正交基
                // 得到新的顶点位置
                float3 centerOffs=v.vertex.xyz-center;
                float3 localPos=center+rightDir*centerOffs.x+upDir*centerOffs.y+normalDir*centerOffs.z;
                o.pos=UnityObjectToClipPos(float4(localPos,1));

                o.uv=TRANSFORM_TEX(v.texcoord,_MainTex);

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