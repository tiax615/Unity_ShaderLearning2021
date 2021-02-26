// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_LightMatrix0' with 'unity_WorldToLight'

Shader "ShaderLearning/Shader9.2_ForwardRendering"{
    Properties{
        _Diffuse("Diffuse",Color)=(1,1,1,1)
        _Specular("Specular",Color)=(1,1,1,1)
        _Gloss("Gloss",Range(8.0,256))=20
    }

    SubShader{
        Tags { "RenderType"="Opaque" }

        // Base Pass
        Pass{
            // Pass for ambient light & first pixel light (directional light)
            Tags{"LightMode"="ForwardBase"}

            CGPROGRAM

            // Apparently need to add this declaration
            #pragma multi_compile_fwdbase

            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"

            fixed4 _Diffuse;
            fixed4 _Specular;
            float _Gloss;

            struct a2v{
                float4 vertex:POSITION;
                float3 normal:NORMAL;
            };

            struct v2f{
                float4 pos:SV_POSITION;
                float3 worldNormal:TEXCOORD0;
                float3 worldPos:TEXCOORD1;
            };

            v2f vert(a2v v){
                v2f o;
                o.pos=UnityObjectToClipPos(v.vertex);
                o.worldNormal=UnityObjectToWorldNormal(v.normal);
                // o.worldPos=UnityObjectToWorldDir(v.vertex);
                o.worldPos=mul(unity_ObjectToWorld,v.vertex).xyz;
                return o;
            }

            fixed4 frag(v2f i):SV_Target{
                // Get ambient term
                // 首先计算场景中的环境光
                fixed3 ambient=UNITY_LIGHTMODEL_AMBIENT.xyz;

                fixed3 worldNormal=normalize(i.worldNormal);
                // 使用_WorldSpaceLightPos0得到最亮平行光的方向（位置对平行光没有意义）
                fixed3 worldLight=normalize(_WorldSpaceLightPos0.xyz);

                fixed3 viewDir=normalize(_WorldSpaceCameraPos.xyz-i.worldPos.xyz);
                fixed3 halfDir=normalize(worldLight+viewDir);

                // Compute diffuse term
                // 使用_LightColor0得到最亮平行光的颜色和强度
                // _LightColor0已经是颜色和强度相乘后的结果
                fixed3 diffuse=_LightColor0.rgb*_Diffuse.rgb*max(0,dot(worldNormal,worldLight));

                // Compute specular term
                fixed3 specular=_LightColor0.rgb*_Specular.rgb*pow(max(0,dot(worldNormal,halfDir)),_Gloss);

                // The attenuation of directional light is always 1
                // 平行光没有衰减，令衰减值为1.0
                fixed atten=1.0;

                return fixed4(ambient+(diffuse+specular)*atten,1.0);
            }

            ENDCG
        }

        // Additional Pass
        Pass{
            // Pass for other pixel lights
            Tags{"LightMode"="ForwardAdd"}

            Blend One One

            CGPROGRAM

            // Apparently need to add this declaration
            #pragma multi_compile_fwdadd

            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"
            // 为了使用unity_WorldToLight（_LightMatrix0）
            #include "AutoLight.cginc" 

            fixed4 _Diffuse;
            fixed4 _Specular;
            float _Gloss;

            struct a2v{
                float4 vertex:POSITION;
                float3 normal:NORMAL;
            };

            struct v2f{
                float4 pos:SV_POSITION;
                float3 worldNormal:TEXCOORD0;
                float3 worldPos:TEXCOORD1;
            };

            v2f vert(a2v v){
                v2f o;
                o.pos=UnityObjectToClipPos(v.vertex);
                o.worldNormal=UnityObjectToWorldNormal(v.normal);
                // o.worldPos=UnityObjectToWorldDir(v.vertex);
                o.worldPos=mul(unity_ObjectToWorld,v.vertex).xyz;
                return o;
            }

            fixed4 frag(v2f i):SV_Target{
                fixed3 worldNormal=normalize(i.worldNormal);

                // 不同光源的光线方向
                #ifdef USING_DIRECTIONAL_LIGHT
                    // 如果是平行光，光线方向
                    fixed3 worldLight=normalize(_WorldSpaceLightPos0.xyz);
                #else
                    // 如果不是平行光，光线方向
                    fixed3 worldLight=normalize(_WorldSpaceLightPos0.xyz-i.worldPos.xyz);
                #endif

                fixed3 viewDir=normalize(_WorldSpaceCameraPos.xyz-i.worldPos.xyz);
                fixed3 halfDir=normalize(worldLight+viewDir);

                // Compute diffuse term
                fixed3 diffuse=_LightColor0.rgb*_Diffuse.rgb*max(0,dot(worldNormal,worldLight));

                // Compute specular term
                fixed3 specular=_LightColor0.rgb*_Specular.rgb*pow(max(0,dot(worldNormal,halfDir)),_Gloss);

                // 不同光源的衰减
                #ifdef USING_DIRECTIONAL_LIGHT
                    // 平行光没有衰减
                    fixed atten=1.0;
                #else
                    float3 lightCoord=mul(unity_WorldToLight,float4(i.worldPos,1)).xyz;
                    fixed atten=tex2D(_LightTexture0,dot(lightCoord,lightCoord).rr).UNITY_ATTEN_CHANNEL;
                #endif

                // AdditionalPass中，不计算环境光
                return fixed4((diffuse+specular)*atten,1.0);
            }

            ENDCG
        }
    }
    FallBack "Specular"
}