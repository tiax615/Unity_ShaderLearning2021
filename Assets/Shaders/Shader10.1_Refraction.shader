// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "ShaderLearning/Shader10.1_Refraction"{
    Properties{
        _Color("Color Tint",Color)=(1,1,1,1)
        _RefractColor("Reflection Color",Color)=(1,1,1,1) // 折射颜色
        _RefractAmount("Reflection Amount",Range(0,1))=1 // 折射程度
        _RefractRatio("Refraction Ratio",Range(0,1))=0.5 // 介质的透射比
        _Cubemap("Reflection Cubemap",Cube)="_Skybox"{} // 环境映射纹理
    }
    SubShader{
        Tags{"RenderrType"="Opaque" "Queue"="Geometry"}
        Pass{
            Tags{"LightMode"="ForwardBase"}

            CGPROGRAM

            #pragma multi_compile_fwdbase

            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            fixed4 _Color;
            fixed4 _RefractColor;
            fixed _RefractAmount;
            fixed _RefractRatio;
            samplerCUBE _Cubemap;

            struct a2v{
                float4 vertex:POSITION;
                float3 normal:NORMAL;
            };

            struct v2f{
                float4 pos:SV_POSITION;
                fixed3 worldNormal:TEXCOORD0;
                float3 worldPos:TEXCOORD1;
                fixed3 worldViewDir:TEXCOORD2;
                fixed3 worldRefr:TEXCOORD3;
                SHADOW_COORDS(4)
            };

            v2f vert(a2v v){
                v2f o;

                o.pos=UnityObjectToClipPos(v.vertex);
                o.worldNormal=UnityObjectToWorldNormal(v.normal);
                o.worldPos=mul(unity_ObjectToWorld,v.vertex).xyz;
                o.worldViewDir=UnityWorldSpaceViewDir(o.worldPos); // 视角方向

                // Compute the refract dir in world space
                // 计算折射方向
                // 使用refract函数，要归一化
                o.worldRefr=refract(-normalize(o.worldViewDir),normalize(o.worldNormal),_RefractRatio);

                TRANSFER_SHADOW(o);

                return o;
            }

            fixed4 frag(v2f i):SV_Target{
                fixed3 worldNormal=normalize(i.worldNormal);
                fixed3 worldLightDir=normalize(UnityWorldSpaceLightDir(i.worldPos));
                fixed3 worldViewDir=normalize(i.worldViewDir);

                fixed3 ambient=UNITY_LIGHTMODEL_AMBIENT.xyz;

                fixed3 diffuse=_LightColor0.rgb*_Color.rgb*max(0,dot(worldNormal,worldLightDir));

                // Use the refract dir in world space to access the cubemap
                // 使用texCUBE对立方体纹理采样，i.worldRefr不需要归一化
                fixed3 refraction=texCUBE(_Cubemap,i.worldRefr).rgb*_RefractColor.rgb;

                UNITY_LIGHT_ATTENUATION(atten,i,i.worldPos);

                // Mix the diffuse color with the refracted color
                fixed3 color=ambient+lerp(diffuse,refraction,_RefractAmount)*atten;

                return fixed4(color,1.0);
            }

            ENDCG
        }
    }
    FallBack "Reflective/VertexLit"
}