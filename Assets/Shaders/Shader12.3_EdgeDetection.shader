Shader "ShaderLearning/Shader12.3_EdgeDetection"{
    Properties{
        _MainTex("Base (RGB)",2D)="white"{}
        _EdgeOnly("Edge Only",Float)=1.0
        _EdgeColor("Edge Color",Color)=(0,0,0,1)
        _BackgroundColor("Background Color",Color)=(1,1,1,1)
    }

    SubShader{
        Pass{
            ZTest Always
            Cull Off
            ZWrite Off

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment fragSobel
            #include "UnityCG.cginc"

            sampler2D _MainTex;
            // 访问某纹理对应的每个纹素的大小
            // 例如一张512x512大小的纹理，该值大约为0.001953（1/512）
            half4 _MainTex_TexelSize; 
            fixed _EdgeOnly;
            fixed4 _EdgeColor;
            fixed4 _BackgroundColor;

            struct v2f{
                float4 pos:SV_POSITION;
                // 对应了使用Sobel算子采样时需要的9个邻域纹理坐标
                half2 uv[9]:TEXCOORD0;
            };

            v2f vert(appdata_img v){
                v2f o;
                o.pos=UnityObjectToClipPos(v.vertex);

                half2 uv=v.texcoord;

                // 把计算采样纹理坐标的代码从片元着色器转移到顶点着色器
                o.uv[0]=uv+_MainTex_TexelSize.xy*half2(-1,-1);
                o.uv[1]=uv+_MainTex_TexelSize.xy*half2(0,-1);
                o.uv[2]=uv+_MainTex_TexelSize.xy*half2(1,-1);
                o.uv[3]=uv+_MainTex_TexelSize.xy*half2(-1,0);
                o.uv[4]=uv+_MainTex_TexelSize.xy*half2(0,0);
                o.uv[5]=uv+_MainTex_TexelSize.xy*half2(1,0);
                o.uv[6]=uv+_MainTex_TexelSize.xy*half2(-1,1);
                o.uv[7]=uv+_MainTex_TexelSize.xy*half2(0,1);
                o.uv[8]=uv+_MainTex_TexelSize.xy*half2(1,1);

                return o;
            }

            // 计算亮度值
            fixed luminace(fixed4 color){
                return 0.2125*color.r+0.7154*color.g+0.0721*color.b;
            }

            // 计算edge值，使用Sobel算子
            half Sobel(v2f i){
                const half Gx[9]={-1,-2,-1,
                                   0,0,0,
                                   1,2,1};
                const half Gy[9]={-1,0,1,
                                  -2,0,2,
                                  -1,0,1};
                half texColor;
                half edgeX=0;
                half edgeY=0;
                for(int it=0;it<9;it++){
                    texColor=luminace(tex2D(_MainTex,i.uv[it]));
                    edgeX+=texColor*Gx[it]; // 叠加x方向梯度
                    edgeY+=texColor*Gy[it]; // 叠加y方向梯度
                }

                half edge=1-abs(edgeX)-abs(edgeY);
                return edge; // edge值越小，表明该位置越可能是一个边缘点
            }

            fixed4 fragSobel(v2f i):SV_Target{
                half edge=Sobel(i); // 得到edge值

                fixed4 withEdgeColor=lerp(_EdgeColor,tex2D(_MainTex,i.uv[4]),edge);
                fixed4 onlyEdgeColor=lerp(_EdgeColor,_BackgroundColor,edge);
                return lerp(withEdgeColor,onlyEdgeColor,_EdgeOnly);
            }    

            ENDCG
        }
    }
    Fallback Off
}