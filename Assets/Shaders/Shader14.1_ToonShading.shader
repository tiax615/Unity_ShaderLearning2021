// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "ShaderLearning/Shader14.1_ToonShading"{
    Properties{
        _Color("Color Tint", Color) = (1, 1, 1, 1)
        _MainTex("Main Tex", 2D) = "white"{}
        _Ramp("Ramp Texture", 2D) = "white"{} // 漫反射色调的渐变纹理
        _Outline("Outline", Range(0, 1)) = 0.1 // 轮廓线宽度
        _OutlineColor("Outline Color", Color) = (0, 0, 0, 1) // 轮廓线颜色
        _Specular("Specular", Color) = (1, 1, 1, 1) // 高光反射颜色
        _SpecularScale("Specular Scale", Range(0, 0.1)) = 0.01 // 高光反射阈值
    }
    SubShader{
        CGINCLUDE

        #include "UnityCG.cginc"
        #include "AutoLight.cginc"
        #include "Lighting.cginc"

        fixed4 _Color;
        sampler2D _MainTex;
        float4 _MainTex_ST;
        sampler2D _Ramp;
        fixed _Outline;
        fixed4 _OutlineColor;
        fixed4 _Specular;
        fixed _SpecularScale;

        ENDCG

        // 渲染背面
        Pass{
            NAME "OUTLINE"
            Cull Front

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            struct a2v{
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f{
                float4 pos : SV_POSITION;
            };

            // 扩张顶点
            v2f vert(a2v v){
                v2f o;

                // 顶点坐标从模型到观察空间
                // float4 pos = mul(UNITY_MATRIX_MV, v.vertex);
                float3 pos = UnityObjectToViewPos(v.vertex);
                // 法线方向从模型到观察空间
                float3 normal = mul((float3x3)UNITY_MATRIX_IT_MV, v.normal);
                // 设置法线z分量，归一化后将顶点沿其方向扩张
                normal.z = -0.5;
                pos = pos + float4(normalize(normal), 0) * _Outline;
                // 顶点坐标从观察到裁剪空间
                // o.pos = mul(UNITY_MATRIX_P, pos);
                o.pos = mul(UNITY_MATRIX_P, float4(pos, 1));

                return o;
            }

            // 用轮廓线颜色渲染整个背面
            float4 frag(v2f i) : SV_Target{
                return float4(_OutlineColor.rgb, 1);
            }
            
            ENDCG
        }
        
        // 渲染正面
        Pass{
            Tags{ "LightMode" = "ForwardBase"}

            Cull Back

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase

            struct a2v{
                float4 vertex : POSITION;
                float4 texcoord : TEXCOORD0;
                float3 normal : NORMAL;
            };
            
            struct v2f{
                float4 pos : POSITION;
                float2 uv : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
                SHADOW_COORDS(3)
            };

            v2f vert(a2v v){
                v2f o;

                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.worldNormal = mul(v.normal, (float3x3)unity_WorldToObject);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

                TRANSFER_SHADOW(o);

                return o;
            }

            fixed4 frag(v2f i) : SV_Target{
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                fixed3 worldHalfDir = normalize(worldLightDir + worldViewDir);

                fixed4 c = tex2D(_MainTex, i.uv);
                fixed3 albedo = c.rgb * _Color.rgb;

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT * albedo;

                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);

                fixed diff = dot(worldNormal, worldLightDir);
                diff = (diff * 0.5 + 0.5) * atten;

                fixed3 diffuse = _LightColor0.rgb * albedo * tex2D(_Ramp, float2(diff,diff)).rgb;

                fixed spec = dot(worldNormal, worldHalfDir);
                fixed w = fwidth(spec) * 2.0; // 对高光区域边界抗锯齿的阈值
                fixed3 specular = _Specular.rgb * lerp(0, 1, smoothstep(-w, w, spec + _SpecularScale -1)) *
                    step(0.0001, _SpecularScale);

                return fixed4(ambient + diffuse + specular, 1.0);
            }

            ENDCG
        }
    }
    Fallback "Diffuse"
}