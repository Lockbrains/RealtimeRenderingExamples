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

            struct appdata
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

            v2f vert (appdata v)
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
                fixed fresnel = pow((1 - max(0, dot(i.normal, i.viewDir))  + _RimBias), _RimWidth);
                fresnel = saturate(_RimIntensity * fresnel); 
                fixed4 col = tex2D(_MainTex, i.uv);
                col.a = fresnel;
                return fresnel * col;
            }
            ENDCG
        }
    }
}
