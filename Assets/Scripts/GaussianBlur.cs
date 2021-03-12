using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GaussianBlur : PostEffectsBase
{
    public Shader gaussianBlurShader;
    private Material gaussianBlurMaterial=null;
    public Material material{
        get{
            gaussianBlurMaterial=CheckShaderAndCreateMaterial(gaussianBlurShader,gaussianBlurMaterial);
            return gaussianBlurMaterial;  
        }
    }

    // Blur iterations - larger number means more blur
    [Range(0,4)]
    public int iterations=3; // 迭代次数

    // Blur spread for each iteration - larget value means more blur
    [Range(0.2f,3.0f)]
    public float blurSpread=0.6f; // 模糊范围

    [Range(1,8)]
    public int downSample=2; // 缩放系数

    /// 1st edition: just apply blur
    /*
    void OnRenderImage(RenderTexture src, RenderTexture dest){
        if(material!=null){
            int rtW=src.width;
            int rtH=src.height;
            // 分配了一块与屏幕图像大小相同的缓冲区
            RenderTexture buffer=RenderTexture.GetTemporary(rtW,rtH,0);

            // Render the vertical pass
            // 第一个Pass，用竖直方向的一维高斯核进行滤波，结果存贮在buffer
            Graphics.Blit(src,buffer,material,0);
            // Render the horizontal pass
            // 第二个Pass，用水平方向的一维高斯核进行滤波，返回最终的屏幕图像
            Graphics.Blit(buffer,dest,material,1);

            // 释放之前分配的缓存
            RenderTexture.ReleaseTemporary(buffer);
        }else{
            Graphics.Blit(src,dest);
        }
    }*/

    /// 2nd edition: scale the render texture
    /// 利用缩放对图像进行降采样，减少需要处理的像素个数提高性能
    /// downSample值越大，性能越好，但过大可能造成像素化
    /*
    void OnRenderImage(RenderTexture src, RenderTexture dest){
        if(material!=null){
            int rtW=src.width/downSample;
            int rtH=src.height/downSample;
            RenderTexture buffer=RenderTexture.GetTemporary(rtW,rtH,0);
            buffer.filterMode=FilterMode.Bilinear; // 滤波模式：双线性

            // Render the vertical pass
            Graphics.Blit(src,buffer,material,0);
            // Render the horizontal pass
            Graphics.Blit(buffer,dest,material,1);

            RenderTexture.ReleaseTemporary(buffer);
        }else{
            Graphics.Blit(src,dest);
        }
    }*/

    /// 3rd edition: use iterations for larger blur
    /// 考虑了高斯模糊的迭代次数
    void OnRenderImage(RenderTexture src, RenderTexture dest){
        if(material!=null){
            int rtW=src.width/downSample;
            int rtH=src.height/downSample;

            RenderTexture buffer0=RenderTexture.GetTemporary(rtW,rtH,0);
            buffer0.filterMode=FilterMode.Bilinear;

            Graphics.Blit(src,buffer0);

            for(int i=0;i<iterations;i++){
                material.SetFloat("_BlurSize",1.0f+i*blurSpread);

                RenderTexture buffer1=RenderTexture.GetTemporary(rtW,rtH,0);

                // Render the vertical pass
                Graphics.Blit(buffer0,buffer1,material,0);

                RenderTexture.ReleaseTemporary(buffer0);
                buffer0=buffer1;
                buffer1=RenderTexture.GetTemporary(rtW,rtH,0);

                // Render the horizontal pass
                Graphics.Blit(buffer0,buffer1,material,1);

                RenderTexture.ReleaseTemporary(buffer0);
                buffer0=buffer1;
            }

            Graphics.Blit(buffer0,dest);
            RenderTexture.ReleaseTemporary(buffer0);
        }else{
            Graphics.Blit(src,dest);
        }
    }
}
