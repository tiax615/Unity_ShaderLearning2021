// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "ShaderLearning/Shader10.1_Fresnel"{
    Properties{
        _Color("Color Tint",Color)=(1,1,1,1)
        _FresnelScale("Fresnel Scale",Range(0,1))=0.5
        _Cubemap("Reflection Cubemap",Cube)="_Skybox"{} // 环境映射纹理
    }
    SubShader{
        Tags{"RenderType"="Opaque" "Queue"="Geometry"}
        Pass{
            Tags{"LightMode"="ForwardBase"}

            CGPROGRAM

            #pragma multi_compile_fwdbase

            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            fixed4 _Color;
            fixed _FresnelScale;
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
                fixed3 worldRefl:TEXCOORD3;
                SHADOW_COORDS(4)
            };

            v2f vert(a2v v){
                v2f o;

                o.pos=UnityObjectToClipPos(v.vertex);
                o.worldNormal=UnityObjectToWorldNormal(v.normal);
                o.worldPos=mul(unity_ObjectToWorld,v.vertex).xyz;
                o.worldViewDir=UnityWorldSpaceViewDir(o.worldPos); // 视角方向
                // Compute the reflect dir in world space
                // 光路可逆，计算视角方向关于顶点法线的反射方向求得入射光线的方向
                // 处于性能考虑，在顶点着色器中计算反射方向
                // 和在片元着色器中计算的视觉效果差不多
                o.worldRefl=reflect(-o.worldViewDir,o.worldNormal);

                TRANSFER_SHADOW(o);

                return o;
            }

            // 在片元着色器中计算菲涅尔反射
            fixed4 frag(v2f i):SV_Target{
                fixed3 worldNormal=normalize(i.worldNormal);
                fixed3 worldLightDir=normalize(UnityWorldSpaceLightDir(i.worldPos));
                fixed3 worldViewDir=normalize(i.worldViewDir);

                fixed3 ambient=UNITY_LIGHTMODEL_AMBIENT.xyz;

                fixed3 diffuse=_LightColor0.rgb*_Color.rgb*max(0,dot(worldNormal,worldLightDir));

                // Use the reflect dir in world space to access the cubemap
                // 使用texCUBE对立方体纹理采样，i.worldRef1不需要归一化
                fixed3 reflection=texCUBE(_Cubemap,i.worldRefl).rgb;

                // 菲涅尔
                fixed fresnel=_FresnelScale+(1-_FresnelScale)*pow(1-dot(worldViewDir,worldNormal),5);

                UNITY_LIGHT_ATTENUATION(atten,i,i.worldPos);

                // Mix the diffuse color with the reflected color
                // fixed3 color=ambient+lerp(diffuse,reflection,_ReflectAmount)*atten;
                fixed3 color=ambient+lerp(diffuse,reflection,saturate(fresnel)*atten);

                return fixed4(color,1.0);
            }

            ENDCG
        }
    }
    FallBack "Reflective/VertexLit"
}