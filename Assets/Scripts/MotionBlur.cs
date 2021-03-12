using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MotionBlur : PostEffectsBase{
    public Shader motionBlurShader;
    private Material motionBlurMaterial=null;
    public Material material{
        get{
            motionBlurMaterial=CheckShaderAndCreateMaterial(motionBlurShader,motionBlurMaterial);
            return motionBlurMaterial;
        }
    }

    [Range(0.0f,0.9f)]
    public float blurAmount=0.5f; // 越大运动拖尾的效果越明显
    private RenderTexture accumulationTexture;

    // 在脚本不运行时，销毁accumulationTexture
    // 因为希望在下一次开始应用运动模糊时重新叠加图像
    void OnDisable(){
        DestroyImmediate(accumulationTexture);
    }

    void OnRenderImage(RenderTexture src,RenderTexture dest){
        if(material!=null){
            // Create the accumulation texture
            // 判断accumulationTexture是否有效
            if(accumulationTexture==null || accumulationTexture.width!=src.width ||
            accumulationTexture.height!=src.height){
                DestroyImmediate(accumulationTexture);
                accumulationTexture=new RenderTexture(src.width,src.height,0);
                // 使它不会显示在Hierarchy中，也不会保存到场景中
                accumulationTexture.hideFlags=HideFlags.HideAndDontSave;
                Graphics.Blit(src,accumulationTexture);
            }

            // We are accumulating motion over frames without clear/discard
            // by design, so silence any performance warnings from Unity
            // 恢复操作
            accumulationTexture.MarkRestoreExpected();

            material.SetFloat("_BlurAmount",1.0f-blurAmount);

            Graphics.Blit(src,accumulationTexture,material);
            Graphics.Blit(accumulationTexture,dest);
        }else{
            Graphics.Blit(src,dest);
        }
    }
}
