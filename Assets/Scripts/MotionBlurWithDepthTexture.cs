using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MotionBlurWithDepthTexture : PostEffectsBase
{
    public Shader motionBlurShader;
    private Material motionBlurMaterial=null;
    public Material material{
        get{
            motionBlurMaterial=CheckShaderAndCreateMaterial(motionBlurShader,motionBlurMaterial);
            return motionBlurMaterial;
        }
    }
    [Range(0.0f,1.0f)]
    public float blurSize=0.5f; // 运动模糊时模糊图像使用的大小
    private Camera myCamera;
    public Camera camera{
        get{
            if(myCamera==null){
                myCamera=GetComponent<Camera>();
            }
            return myCamera;
        }
    }
    private Matrix4x4 previousViewProjectionMatrix; // 保存上一帧相机的视角*投影矩阵
    
    void OnEnable(){
        camera.depthTextureMode|=DepthTextureMode.Depth;
    }

    void OnRenderImage(RenderTexture src, RenderTexture dest){
        if(material!=null){
            material.SetFloat("_BlurSize",blurSize);

            // 前一帧的视角*投影矩阵
            material.SetMatrix("_PreviousViewProjectionMatrix",previousViewProjectionMatrix);
            Matrix4x4 currentViewProjectionMatrix=camera.projectionMatrix*camera.worldToCameraMatrix;
            Matrix4x4 currentViewProjectionInverseMatrix=currentViewProjectionMatrix.inverse;
            // 当前帧的视角*投影矩阵的逆矩阵
            material.SetMatrix("_CurrentViewProjectionInverseMatrix",currentViewProjectionInverseMatrix);
            previousViewProjectionMatrix=currentViewProjectionMatrix;

            Graphics.Blit(src,dest,material);
        }else{
            Graphics.Blit(src,dest);
        }
    }
}
