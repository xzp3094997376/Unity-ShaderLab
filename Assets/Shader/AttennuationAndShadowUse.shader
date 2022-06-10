// Upgrade NOTE: replaced '_LightMatrix0' with 'unity_WorldToLight'

// Upgrade NOTE: replaced '_LightMatrix0' with 'unity_WorldToLight'

Shader "Test/AttennuationAndShadowUse"
{
      Properties
    {
        _Color ("Main Tint",Color)=(1,1,1,1)
        _MainTex ("Texture", 2D) = "white" {}        
    }
    SubShader
    {        
        LOD 100
        Pass
        {
            Tags { "LightMode"="ForwardBase" }           

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fwdbase

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            struct appdata
            {
                float4 vertex:POSITION;
                float3 normal:NORMAL;
                float2 texcoord:TEXCOORD0;
            };

            struct v2f
            {
                float4 pos:SV_POSITION;
                float3 worldNormal:TEXCOORD0;
                float3 worldPos:TEXCOORD1;
                float2 uv:TEXCOORD2;  
                SHADOW_COORDS(3)   
                                                     
            };

            fixed4 _Color;        
            sampler2D _MainTex;
            float4 _MainTex_ST;//
        

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal=UnityObjectToWorldNormal(v.normal);
                o.worldPos=mul(unity_ObjectToWorld,v.vertex).xyz;
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);       
                TRANSFER_SHADOW(o);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {

                fixed3 worldNormal=normalize(i.worldNormal);
                fixed3 worldLightDir=normalize(UnityWorldSpaceLightDir(i.worldPos));           
                fixed4 texColor=tex2D(_MainTex,i.uv);  
                //clip(texColor.a-_Cutoff);
                fixed3 albedo=texColor.rgb*_Color.rgb;
                fixed3 ambient=UNITY_LIGHTMODEL_AMBIENT.xyz*albedo;
                fixed3 diffuse=_LightColor0.rgb*albedo*max(0,dot(worldNormal,worldLightDir));
                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);                              
                return fixed4(ambient+diffuse*atten,1.0);
            }
            ENDCG
        }

        Pass
        {
            Tags { "LightMode"="ForwardAdd" }     
            Blend One One
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fwdadd_fullshadows     
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

             struct appdata
            {
                float4 vertex:POSITION;
                float3 normal:NORMAL;
                float2 texcoord:TEXCOORD0;
            };

            struct v2f
            {
                float4 pos:SV_POSITION;
                float3 worldNormal:TEXCOORD0;
                float3 worldPos:TEXCOORD1;
                float2 uv:TEXCOORD2;                              
            };
            
            fixed4 _Color;        
            sampler2D _MainTex;
            float4 _MainTex_ST;
        

            v2f vert (appdata v)
            {
                 v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal=UnityObjectToWorldNormal(v.normal);
                o.worldPos=mul(unity_ObjectToWorld,v.vertex).xyz;
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);           
                return o;           
            }

            fixed4 frag (v2f i) : SV_Target
            {   
                fixed3 worldNormal=normalize(i.worldNormal);
                #ifdef USING_DIRECTIONAL_LIGHT
                  fixed3 worldLightDir=normalize(_WorldSpaceLightPos0.xyz);      
                #else
                 fixed3 worldLightDir=normalize(_WorldSpaceLightPos0.xyz-i.worldPos.xyz);
                #endif

                 #ifdef USING_DIRECTIONAL_LIGHT
                  fixed atten=1.0;     
                #else
                float3 lightCoord = mul(unity_WorldToLight, float4(i.worldPos, 1)).xyz;
                fixed3 atten=tex2D(_LightTexture0,dot(lightCoord,lightCoord).rr).UNITY_ATTEN_CHANNEL;
                #endif
                          
                fixed4 texColor=tex2D(_MainTex,i.uv);       
                fixed3 albedo=texColor.rgb*_Color.rgb;             
                fixed3 diffuse=_LightColor0.rgb*albedo*max(0,dot(worldNormal,worldLightDir));

                return fixed4(diffuse,1.0);
            }
            ENDCG
        }
    }
    //Fallback "Specular"
}
