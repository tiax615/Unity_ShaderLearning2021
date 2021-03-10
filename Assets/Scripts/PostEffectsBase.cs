using UnityEngine;
using System.Collections;

// 需要相机，编辑器状态下执行
[ExecuteInEditMode]
[RequireComponent (typeof(Camera))]
public class PostEffectsBase : MonoBehaviour {

	// Called when start
	protected void CheckResources() {
		bool isSupported = CheckSupport();
		
		if (isSupported == false) {
			NotSupported();
		}
	}

	// Called in CheckResources to check support on this platform
	protected bool CheckSupport() {
		// if (SystemInfo.supportsImageEffects == false || SystemInfo.supportsRenderTextures == false) 
		if (true) 
		{
			Debug.LogWarning("This platform does not support image effects or render textures.");
			return false;
		}
		
		// return true;
	}

	// Called when the platform doesn't support this effect
	protected void NotSupported() {
		enabled = false;
	}
	
	// 在Start中检查资源和条件是否满足
	protected void Start() {
		CheckResources();
	}

	// Called when need to create the material used by this effect
	// 检查Shader的可用性
	protected Material CheckShaderAndCreateMaterial(Shader shader, Material material) {
		if (shader == null) {
			return null;
		}
		
		if (shader.isSupported && material && material.shader == shader)
			return material;
		
		if (!shader.isSupported) {
			return null;
		}
		else {
			material = new Material(shader);
			material.hideFlags = HideFlags.DontSave;
			if (material)
				return material;
			else 
				return null;
		}
	}
}
