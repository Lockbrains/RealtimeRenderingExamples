Shader "Unlit/Fresnel"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _RimWidth ("Rim Width", float) = 2.0
        _RimIntensity("Rim Intensity", float) = 1.0
        _RimBias ("Rim Bias", float) = 0.2
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

            struct a2v
            {
                float4 pos : POSITION;
                float3 normal: NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float3 viewDir: TEXCOORD1;
                float3 normal: TEXCOORD2;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed _RimWidth;
            fixed _RimIntensity;
            fixed _RimBias;

            fixed fresnel(float3 worldNormal, float3 worldViewDir)
            {
                const float3 n = normalize(worldNormal);
                const float3 v = normalize(worldViewDir);
                return saturate(2.0 * pow((1 - max(0, dot(n,v)) + 0.2), 3.0));
            }

            fixed fresnel(float3 worldNormal, float3 worldViewDir, float bias, float power, float intensity)
            {
                const float3 n = normalize(worldNormal);
                const float3 v = normalize(worldViewDir);
                return saturate(intensity * pow((1 - max(0, dot(n,v)) + bias), power));
            }

            v2f vert (a2v v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.pos);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.viewDir = normalize(_WorldSpaceCameraPos - mul(unity_ObjectToWorld, v.pos).xyz);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed fresnelTerm = fresnel(i.normal, i.viewDir, _RimBias, _RimWidth, _RimIntensity);
                fixed4 col = tex2D(_MainTex, i.uv);
                col.a = fresnelTerm;
                return col;
            }
            ENDCG
        }
    }
}
