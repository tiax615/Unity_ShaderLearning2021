Shader "ShaderLearning/Shader15.2_WaterWave"{
    Properties{
        _Color("Main Color", Color) = (0, 0.15, 0.115, 1) // 水面颜色
        _MainTex("Base (RGB)", 2D) = "white" {} // 水面波纹材质纹理
        _WaveMap("Wave Map", 2D) = "bump" {} // 由噪声纹理生成的法线纹理
        _Cubemap("Environment Cubemap", Cube) = "_Skybox" {} // 用于模拟反射的立方体纹理
        _WaveXSpeed("Wave Horizontal Speed", Range(-0.1, 0.1)) = 0.01 // 法线纹理在X方向的平移速度
        _WaveYSpeed("Wave Vertical Speed", Range(-0.1, 0.1)) = 0.01 // 法线纹理在Y方向的平移速度
        _Distortion("Distortion", Range(0, 100)) = 10 // 控制模拟折射时图像的扭曲程度
    }

    SubShader{
        // We must be transparent, so other objects are drawn before this one.
        // 确保其他所有不透明物体都已经被渲染到屏幕上了
        Tags{"Queue" = "Transparent" "RenderType" = "Opaque"}

        // This pass grabs the screen behind the object into a texture.
        // We can access the result in the next pass as _RefractionTex
        // 抓取屏幕图像，保存在_RefractionTex中
        GrabPass{"_RefractionTex"}

        Pass{
            CGPROGRAM

            #include "UnityCG.cginc"
            #pragma vertex vert
            #pragma fragment frag

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _WaveMap;
            float4 _WaveMap_ST;
            samplerCUBE _Cubemap;
            fixed _WaveXSpeed;
            fixed _WaveYSpeed;
            float _Distortion;
            sampler2D _RefractionTex;
            float4 _RefractionTex_TexelSize;

            struct a2v{
                float4 vertex : POSITION;
                float4 texcoord : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2f{
                float4 pos : SV_POSITION;
                float4 scrPos : TEXCOORD0;
                float4 uv : TEXCOORD1;
                float4 TtoW0 : TEXCOORD2;
                float4 TtoW1 : TEXCOORD3;
                float4 TtoW2 : TEXCOORD4;
            };

            v2f vert(a2v v){
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.scrPos = ComputeGrabScreenPos(o.pos); // 对应被抓取屏幕图像的采样坐标
                o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.uv.zw = TRANSFORM_TEX(v.texcoord, _WaveMap);

                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
                fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
                fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;

                o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
                o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
                o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);

                return o;
            }

            fixed4 frag(v2f i) : SV_Target{
                float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));
                float2 speed = _Time.y * float2(_WaveXSpeed, _WaveYSpeed);

                // Get the normal in tangent space
                // 模拟两层交叉的水面波动效果
                fixed3 bump1 = UnpackNormal(tex2D(_WaveMap, i.uv.zw + speed)).rgb;
                fixed3 bump2 = UnpackNormal(tex2D(_WaveMap, i.uv.zw - speed)).rgb;
                fixed3 bump = normalize(bump1 + bump2);

                // Compute the offset in tangent space
                // 模拟折射效果
                float2 offset = bump.xy * _Distortion * _RefractionTex_TexelSize.xy;
                // 偏移量和屏幕坐标的z分量相乘，模拟深度越大、折射越大的效果
                i.scrPos.xy = offset * i.scrPos.z + i.scrPos.xy;
                fixed3 refrCol = tex2D(_RefractionTex, i.scrPos.xy / i.scrPos.w).rgb;

                // Convert the normal to world space
                bump = normalize(half3(dot(i.TtoW0.xyz, bump), dot(i.TtoW1.xyz, bump), dot(i.TtoW2.xyz, bump)));
                fixed4 texColor = tex2D(_MainTex, i.uv.xy + speed);
                fixed3 reflDir = reflect(-viewDir, bump);
                fixed3 reflCol = texCUBE(_Cubemap, reflDir).rgb * texColor.rgb * _Color.rgb;

                fixed fresnel = pow(1 - saturate(dot(viewDir, bump)), 4);
                fixed3 finalColor = reflCol * fresnel +refrCol * (1 - fresnel);

                return fixed4(finalColor, 1);
            }

            ENDCG
        }
    }
}