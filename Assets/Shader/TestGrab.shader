// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

//玻璃效果 10.2.2
 
Shader "Unlit/Chapter10-GlassRefraction"
{
	Properties
	{
		//玻璃的材质纹理
		_MainTex ("Texture", 2D) = "white" {}
		//玻璃的法线纹理
		_BumpMap("Normal Map",2D) = "bump"{}
		//模拟反射环境的纹理
		_Cubemap("Environment Cubemap",Cube) = "_Skybox"{}
		//模拟折射时的图像扭曲程度
		_Distortion("Distortion",Range(0,100))=10
		//控制折射程度
		_RefractAmount("Reftact Amount",Range(0.0,1.0))=1.0
	}
	SubShader
	{
			// We must be transparent, so other objects are drawn before this one.(transparent必须透明的，这样其他的物体就会被画在这个之前。)
			Tags{ "Queue" = "Transparent" "RenderType" = "Opaque" }
 
			// This pass grabs the screen behind the object into a texture.(这个传递将对象后面的屏幕抓取到一个纹理中。)
			// We can access the result in the next pass as _RefractionTex(我们可以在下一次传递中访问结果为_RefractionTex)
			GrabPass{ "_RefractionTex" }
 
			Pass{
			CGPROGRAM
 
#pragma vertex vert
#pragma fragment frag
 
#include "UnityCG.cginc"
 
		sampler2D _MainTex;
		float4 _MainTex_ST;
		sampler2D _BumpMap;
		float4 _BumpMap_ST;
		samplerCUBE _Cubemap;
		float _Distortion;
		fixed _RefractAmount;
		sampler2D _RefractionTex;
		float4 _RefractionTex_TexelSize;
 
		struct a2v {
			float4 vertex : POSITION;
			float3 normal : NORMAL;
			float4 tangent : TANGENT;
			float2 texcoord: TEXCOORD0;
		};
 
		struct v2f {
			float4 pos : SV_POSITION;
			float4 scrPos : TEXCOORD0;
			float4 uv : TEXCOORD1;
			float4 TtoW0 : TEXCOORD2;
			float4 TtoW1 : TEXCOORD3;
			float4 TtoW2 : TEXCOORD4;
		};
 
			
			
		v2f vert(a2v v) {
			v2f o;
			//坐标转换
			o.pos = UnityObjectToClipPos(v.vertex);
 
			//获取屏幕坐标
			o.scrPos = ComputeGrabScreenPos(o.pos);
 
			//TRANSFORM_TEX:根据比例尺/偏压特性转换2D UV,包含在#include "UnityCG.cginc"
			o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
			o.uv.zw = TRANSFORM_TEX(v.texcoord, _BumpMap);
 
			//坐标转换
			float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
			//法线转换
			fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
			//切线转换
			fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
			//副法线转换
			fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;
 
			//（切线，副法线，法线，位置）
			o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
			o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
			o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);
 
			return o;
		}
			
			fixed4 frag (v2f i) : SV_Target
			{
				//获取位置
				float3 worldPos = float3(i.TtoW0.w,i.TtoW1.w,i.TtoW2.w);
				//float3 UnityWorldSpaceViewDir(float4 v)  输入一个世界空间中的顶点位置，返回世界空间中从该点到摄像机的观察方向。
				fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
 
				// Get the normal in tangent space （获得切线空间下的法线位置）
				fixed3 bump = UnpackNormal(tex2D(_BumpMap, i.uv.zw));
 
				
				// 位移=法线位置*扭曲程度*抓取的纹理的纹素值
				float2 offset = bump.xy*_Distortion*_RefractionTex_TexelSize.xy;
				//屏幕坐标=位移+屏幕原坐标
				i.scrPos.xy = offset + i.scrPos.xy;
				//折射颜色=二维纹理查询（抓取的纹理，屏幕位置/深度）.rgb
				fixed3 refrCol = tex2D(_RefractionTex, i.scrPos.xy /i.scrPos.w).rgb;
				
				//把法线方向从切线空间变换到世界空间下,得到视角方向的相对于法线方向的反射方向
				//（使用变换矩阵的每一行，既切线、副法线、法线、TtoW，分别和切线空间下的法线方向点积，构成新的法线方向）
				bump = normalize(half3 (dot(i.TtoW0.xyz, bump), dot(i.TtoW1.xyz, bump), dot(i.TtoW2.xyz, bump)));
 
				//反射方向=反射函数（视角方向取反，新法线方向）
				fixed3 reflDir = reflect(-worldViewDir, bump);
				//纹理颜色=二维纹理查询（主纹理，纹理坐标）
				fixed4 texColor = tex2D(_MainTex, i.uv.xy);
				//反射颜色=在世界空间中使用反射方向访问立方体图
				fixed3 reflCol = texCUBE(_Cubemap, reflDir).rgb*texColor.rgb;
 
				//最终颜色=反射颜色*（1-折射程度）+反射颜色*折射程度
				fixed3 finalColor = reflCol * (1 - _RefractAmount) + refrCol * _RefractAmount;
 
				return fixed4(finalColor, 1);
			}
			ENDCG
		}
	}
		FallBack "Diffuse"
}