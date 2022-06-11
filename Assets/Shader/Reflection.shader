// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Test/Reflection"
{
    Properties
    {       
        _Color("Color Tint",Color)=(1,1,1,1)
        _ReflectColor("Reflection Color",Color)=(1,1,1,1)
        _ReflectAmount("Reflect Amount",Range(0,1))=1
        _CubeMap ("Reflection CubeMap", Cube) = "_Skybox" {}
    }
    SubShader
    {
        Tags { "LightMode"="ForwardBase" }          
        LOD 100

        Pass
        {
            CGPROGRAM
// Upgrade NOTE: excluded shader from DX11; has structs without semantics (struct v2f members worldNormal)
#pragma exclude_renderers d3d11
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal:NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos:SV_POSITION;
                float3 worldNormal:TEXCOORD0;
                float3 worldPos:TEXCOORD1;
                float3 worldViewDir:TEXCOORD2;      
                float3 worldRef1:TEXCOORD3;
                SHADOW_COORDS(4)    
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal=UnityObjectToWorldNormal(v.normal);
                o.worldPos=mul(unity_ObjectToWorld.v.vertex).xyz;
                o.worldViewDir=UnityWorldSpaceViewDir(o.worldPos);

                o.worldRef1=reflect(-o.worldViewDir,o.worldNormal);
                TRANSFER_SHADOW(o);
                return o;
            }



            fixed4 frag (v2f i) : SV_Target
            {               
                fixed3 worldNormal=normalize(i.worldNormal);
                fixed3 worldLightDir=normalize(UnityWorldSpaceLightDir(i.worldPos));   
                fixed3 worldViewDir=normalize(i.worldViewDir);
                fixed4 texColor=tex2D(_MainTex,i.uv);  

                fixed3 ambient=UNITY_LIGHTMODEL_AMBIENT.xyz*albedo;

                fixed3 diffuse=_LightColor0.rgb*albedo*max(0,dot(worldNormal,worldLightDir));

                fixed3 reflection=texCUBE(_CubeMap,i.worldRef).rgb*_ReflectColor.rgb;

                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);     

                fixed3 color=ambient+lerp(diffuse,reflection,_ReflectAmount)*atten;
                               
                return fixed4(color,1.0);
            }
            ENDCG
        }
    }
     Fallback "Transparent/Cutout/VertexLit"
}
