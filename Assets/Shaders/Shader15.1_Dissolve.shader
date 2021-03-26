// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "ShaderLearning/Shader15.1_Dissolve"{
    Properties{
        _BurnAmount("Burn Amount", Range(0.0, 1.0)) = 0.0 // 消融程度
        _LineWidth("Burn Line Width", Range(0.0, 0.2)) = 0.1 // 烧焦线宽
        _MainTex("Base (RGB)", 2D) = "white"{}
        _BumpMap("Normal Map", 2D) = "bump" {}
        _BurnFirstColor("Burn First Color", Color) = (1, 0, 0, 1) // 火焰边缘颜色1
        _BurnSecondColor("Burn Second Color", Color) = (1, 0, 0, 1) // 火焰边缘颜色2
        _BurnMap("Burn Map", 2D) = "white" {} // 噪声纹理
    }

    SubShader{
        Tags{"RenderType" = "Opaque" "Queue" = "Geometry"}
        Pass{
            Tags{"LightMode" = "ForwardBase"}
            Cull Off // 关闭剔除，渲染双面。因为消融会裸露模型内部

            CGPROGRAM

            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            #pragma multi_compile_fwdbase
            #pragma vertex vert
            #pragma fragment frag

            fixed _BurnAmount;
            fixed _LineWidth;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _BumpMap;
            float4 _BumpMap_ST;
            fixed4 _BurnFirstColor;
            fixed4 _BurnSecondColor;
            sampler2D _BurnMap;
            float4 _BurnMap_ST;

            struct a2v{
                float4 vertex : POSITION;
                float4 texcoord : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2f{
                float4 pos : SV_POSITION;
                float2 uvMainTex : TEXCOORD0;
                float2 uvBumpMap : TEXCOORD1;
                float2 uvBurnMap : TEXCOORD2;
                float3 lightDir : TEXCOORD3;
                float3 worldPos : TEXCOORD4;
                SHADOW_COORDS(5)
            };

            v2f vert(a2v v){
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                o.uvMainTex = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.uvBumpMap = TRANSFORM_TEX(v.texcoord, _BumpMap);
                o.uvBurnMap = TRANSFORM_TEX(v.texcoord, _BurnMap);

                TANGENT_SPACE_ROTATION; // 把光源方向从模型空间变换到切线空间
                o.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex)).xyz;
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

                TRANSFER_SHADOW(o);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target{
                fixed3 burn = tex2D(_BurnMap, i.uvBurnMap).rgb;

                clip(burn.r - _BurnAmount);

                float3 tangentLightDir = normalize(i.lightDir);
                fixed3 tangentNormal = UnpackNormal(tex2D(_BumpMap, i.uvBumpMap));

                fixed3 albedo = tex2D(_MainTex, i.uvMainTex).rgb;

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                fixed3 diffuse = _LightColor0.rgb * albedo * max(0,dot(tangentNormal,tangentLightDir));

                fixed t = 1 - smoothstep(0.0, _LineWidth, burn.r - _BurnAmount);
                fixed3 burnColor = lerp(_BurnFirstColor, _BurnSecondColor, t);
                burnColor = pow(burnColor, 5); // 让效果更接近烧焦的痕迹

                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);
                fixed3 finalColor = lerp(ambient + diffuse * atten, burnColor, t * step(0.0001, _BurnAmount));

                return fixed4(finalColor, 1);
            }

            ENDCG
        }

        // Pass to render object as a shadow caster
        // 投射阴影
        Pass{
            Tags{"LightMode" = "ShadowCaster"}

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_shadowcaster
            #include "UnityCG.cginc"

            fixed _BurnAmount;
            sampler2D _BurnMap;
            float4 _BurnMap_ST;

            struct v2f{
                V2F_SHADOW_CASTER;
                float2 uvBurnMap : TEXCOORD1;
            };

            v2f vert(appdata_base v){
                v2f o;

                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o);

                o.uvBurnMap = TRANSFORM_TEX(v.texcoord, _BurnMap);

                return o;
            }

            fixed4 frag(v2f i) : SV_Target{
                fixed3 burn = tex2D(_BurnMap, i.uvBurnMap).rgb;

                clip(burn.r - _BurnAmount);

                SHADOW_CASTER_FRAGMENT(i)
            }

            ENDCG
        }
    }
}