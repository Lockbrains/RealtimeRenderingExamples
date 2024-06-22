Shader "Unlit/Fresnel"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _FresnelPower("Fresnel Power", float) = 2.0
        _FresnelBias("Fresnel Bias", float) = 0.2
        _FresnelScale("Fresnel Scale", float) = 1.0
        _RimColor("Color", color) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" }
        LOD 100

        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite On
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 pos : POSITION;
                float3 normal: NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float3 worldNormal: TEXCOORD1;
                float3 viewDir: TEXCOORD2;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed _FresnelPower;
            fixed _FresnelBias;
            fixed _FresnelScale;
            float4 _RimColor;

            fixed remap(fixed value, fixed original_min, fixed original_max,
                                     fixed new_min,      fixed new_max )
            {
                const fixed percentage = (value - original_min)
                                       / (original_max - original_min);
                
                return new_min + percentage * (new_max - new_min); 
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.pos);
                o.worldNormal = normalize(UnityObjectToWorldNormal(v.normal));
                o.viewDir = normalize(_WorldSpaceCameraPos - mul(unity_ObjectToWorld, v.pos).xyz);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed fresnel = saturate(_FresnelScale * pow(1 - dot(i.worldNormal, i.viewDir), _FresnelPower) + _FresnelBias);
                fixed4 rimColor = _RimColor * fresnel;
                fixed4 col = tex2D(_MainTex, i.uv);
                col.a = fresnel;
                col += rimColor;
                return col;
            }
            ENDCG
        }
    }
}
