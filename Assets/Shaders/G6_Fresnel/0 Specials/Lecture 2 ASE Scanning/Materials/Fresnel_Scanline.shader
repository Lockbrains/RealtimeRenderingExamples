Shader"Unlit/Fresne_Scanline"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _ScanlineTex ("Scanline Texture", 2D) = "white" {}
        _RimIntensity("Rim Intensity", float) = 1.0
        _FresnelPower("Fresnel Power", float) = 2.0
        _FresnelBias("Fresnel Bias", Range(0,1)) = 0.2
        _FresnelScale("Fresnel Scale", float) = 1.0
        _InnerRimColor("Inner Rim Color", color) = (1,1,1,1)
        _RimLightColor("Light Color", color) = (1,1,1,1)
        _RimColor("Color", color) = (1,1,1,1)
        _Speed("Scanline Speed", Vector) = (1,1,0,0)
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
                float2 worldPos: TEXCOORD4;
                float2 uvScanline: TEXCOORD5;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            sampler2D _ScanlineTex;
            float4 _MainTex_ST;
            fixed _FresnelPower;
            fixed _FresnelBias;
            fixed _FresnelScale;
            float4 _RimColor;
            float4 _RimLightColor;
            float4 _InnerRimColor;
            fixed _RimIntensity;
            fixed2 _Speed;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.pos);
                o.worldPos = mul(unity_ObjectToWorld, v.pos).xy;
                o.worldNormal = normalize(UnityObjectToWorldNormal(v.normal));
                o.viewDir = normalize(_WorldSpaceCameraPos - mul(unity_ObjectToWorld, v.pos).xyz);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.uvScanline = _Speed * _Time.y + o.worldPos;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed fresnel = _FresnelScale * pow(1 - saturate(dot(i.worldNormal, i.viewDir)), _FresnelPower);
                fixed4 rimColor = _RimColor * fresnel; 
                fixed4 scanline = tex2D(_ScanlineTex,  5 * i.uvScanline);
                scanline.a = Luminance(scanline);
                
                fixed4 col = tex2D(_MainTex, i.uv);
                fixed4 alpha = saturate(scanline.a + fresnel);
                
                fixed4 finalCol = fixed4(col.rgb, 0) +  scanline + rimColor;
                finalCol.a = clamp(alpha, _FresnelBias, 1);
                return finalCol;
            }
            ENDCG
        }
    }
}
