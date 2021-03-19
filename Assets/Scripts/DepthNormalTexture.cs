using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
[RequireComponent (typeof(Camera))]
public class DepthNormalTexture : PostEffectsBase
{
    public Shader DepthNormalShader;
    private Material DepthNormalMaterial=null;
    public Material material{
        get{
            DepthNormalMaterial=CheckShaderAndCreateMaterial(DepthNormalShader,DepthNormalMaterial);
            return DepthNormalMaterial;
        }
    }

    [Range(0,1)]
    public int DepthNormalValue=0;

    void Awake()
    {
        GetComponent<Camera>().depthTextureMode|=DepthTextureMode.Depth;
        GetComponent<Camera>().depthTextureMode|=DepthTextureMode.DepthNormals;
    }

    void OnRenderImage(RenderTexture src, RenderTexture dest){
        if(material!=null){
            // RenderTexture DepthNormalTexture=new RenderTexture(src.width,src.height,0);
            material.SetInt("_DepthNormalValue",DepthNormalValue);
            Graphics.Blit(src,dest,material);
        }else{
            Graphics.Blit(src,dest);
        }
    }
}