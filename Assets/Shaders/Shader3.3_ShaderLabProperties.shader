Shader "ShaderLearning/Shader3.3_ShaderLabProperties"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        
        // Numbers and Sliders
        _Int("Int",Int)=666
        _Float("Float",Float)=6.66
        _Range("Range",Range(0.0,6.0))=3.3
        _Color("Color",Color)=(0,0,0,0)
        _Vector("Vector",Vector)=(2,4,6,8)
        
        // Textures
        _2D("2D",2D)=""{}
        _Cube("Cube",Cube)="blue"{}
        _3D("3D",3D)="red"{}
    }
    
    FallBack "Diffuse"
}