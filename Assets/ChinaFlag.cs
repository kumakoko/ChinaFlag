using UnityEngine;

[ExecuteInEditMode]
public class ChinaFlag : MonoBehaviour
{
    [Tooltip("水平分辨率")]
    public int m_HoriResolution = 1024;

    [Tooltip("垂直分辨率")]
    public int m_VertResolution = 768;

    ["本示例的着色器代码文件"]
    public Shader m_StarNightShader;

    ["本示例的材质文件"]
    private Material m_StarNightMaterial = null;

    public Material material
    {
        get
        {
            m_StarNightMaterial = CheckShaderAndCreateMaterial(m_StarNightShader);
            return m_StarNightMaterial;
        }
    }

    /// <summary>
    /// 由摄像机调用的，执行的用来绘制全屏image effect效果的必然事件函数
    /// </summary>
    /// <param name="source"></param>
    /// <param name="destination"></param>
    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        // 获取到一个临时的rendered texture，用来存放经过后处理机制处理后的颜色数据
        RenderTexture scaled = RenderTexture.GetTemporary(m_HoriResolution, m_VertResolution);

        // 把源rendered texrture使用material进行处理后，拷贝到scaled rendered texture
        Graphics.Blit(source, scaled, this.material);

        // 经过处理后，把scaled rendered texture拷贝目标rendered texture，此处是最终颜色缓冲区
        Graphics.Blit(scaled, destination);

        // 释放这个临时的rendered texture
        RenderTexture.ReleaseTemporary(scaled);
    }

    /// <summary>
    /// 检测着色器是否被当前硬件支持，支持的话创建一个材质对象
    /// </summary>
    /// <param name="shader">后处理机制使用的着色器文件</param>
    /// <param name="material">已有的材质文件，如果传递一个null的值的话，会新创建一个</param>
    /// <returns>返回创建的材质文件</returns>
    protected Material CheckShaderAndCreateMaterial(Shader shader)
    {
        if (shader == null || !shader.isSupported)
            return null;

        Material material = new Material(shader);
        material.hideFlags = HideFlags.DontSave;
        return material;
    }
}