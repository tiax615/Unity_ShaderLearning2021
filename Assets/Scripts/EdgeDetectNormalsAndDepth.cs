using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class EdgeDetectNormalsAndDepth : PostEffectsBase
{
    public Shader edgeDetectShader;
    private Material edgeDetectMaterial = null;
    public Material material
    {
        get
        {
            edgeDetectMaterial = CheckShaderAndCreateMaterial(edgeDetectShader, edgeDetectMaterial);
            return edgeDetectMaterial;
        }
    }
    [Range(0.0f, 1.0f)]
    public float edgesOnly = 0.0f;
    public Color edgeColor = Color.black;
    public Color backgroundColor = Color.white;
    public float sampleDistance = 1.0f; // 采样距离。视觉上看，值越大描边越宽
    public float sensitivityDepth = 1.0f; // 邻域深度灵敏度
    public float sensitivityNormals = 1.0f; // 邻域法线灵敏度

    void OnEnable()
    {
        GetComponent<Camera>().depthTextureMode|=DepthTextureMode.DepthNormals;
    }
}