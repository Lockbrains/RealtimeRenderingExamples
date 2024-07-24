Shader"Unlit/Fresnel_Hologram"
{
    Properties
    {
        [Header(Textures)]
        [Space(10)]
        _MainTex ("Texture", 2D) = "white" {}
        _ScanlineTex ("Scanline Texture", 2D) = "white" {}
        _NoiseTex("Noise Texture", 2D) = "white" {}
        
        [Header(Rim Light)]
        [Space(10)]
        _RimIntensity("Rim Intensity", float) = 1.0
        _FresnelPower("Fresnel Power", float) = 2.0
        _FresnelBias("Fresnel Bias", Range(0,1)) = 0.2
        _FresnelScale("Fresnel Scale", float) = 1.0
        _InnerRimColor("Inner Rim Color", color) = (1,1,1,1)
        _RimLightColor("Light Color", color) = (1,1,1,1)
        _RimColor("Color", color) = (1,1,1,1)
        
        [Header(Signal Unstability)]
        [Space(10)]
        _FlickerSpeed("Flicker Speed", float) = 0.5
        _Speed("Scanline Speed", Vector) = (1,1,0,0)
        _GlitchTiling("Glitch Tiling", float) = 2.0
        _GlitchVertexOffset("Glitch Offset", Vector) = (1,1,1,0)
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
                float3 worldPos: TEXCOORD4;
                float2 uvScanline: TEXCOORD5;
                float2 noiseUV: TEXCOORD6;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            sampler2D _ScanlineTex;
            sampler2D _NoiseTex;
            float4 _MainTex_ST;
            float4 _ScanlineTex_ST;
            float4 _NoiseTex_ST;
            fixed _FresnelPower;
            fixed _FresnelBias;
            fixed _FresnelScale;
            float4 _RimColor;
            float4 _RimLightColor;
            float4 _InnerRimColor;
            fixed _RimIntensity;
            float _FlickerSpeed;
            float _GlitchTiling;
            float3 _GlitchVertexOffset;
            fixed2 _Speed;

            float remap (float In, float oldMin, float oldMax, float newMin, float newMax)
            {
                float percentage = (In - oldMin) / (oldMax - oldMin);
                return newMin + percentage * (newMax - newMin);
            }
            
            float flicker (float2 uv)
            {
                uv += _Time;
                return lerp(1.0, saturate(tex2D(_NoiseTex, uv).r * 2.0 - 1.0), _FlickerSpeed);
            }

            float glitchDisplacement(float3 worldPos)
            {
                float d = worldPos.y * _GlitchTiling + (-2.5 * _Time.y);
                float res = tex2Dlod(_NoiseTex, float4(d, -2 * _Time.y, 0, 0)).r * 2.0 - 1.0;
                return res;
            }
            
            v2f vert (appdata v)
            {
                v2f o;
                float3 worldPos = mul(unity_ObjectToWorld, v.pos).xyz;
                o.worldPos = worldPos;
                o.worldNormal = normalize(UnityObjectToWorldNormal(v.normal));
                o.viewDir = normalize(_WorldSpaceCameraPos - mul(unity_ObjectToWorld, v.pos).xyz);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.noiseUV = TRANSFORM_TEX(v.uv, _NoiseTex);
                o.uvScanline = _Speed * _Time.y + o.worldPos;
                float3 displacement =  glitchDisplacement(worldPos) * _GlitchVertexOffset * tex2Dlod(_NoiseTex, float4(o.noiseUV, 0,0));
                o.vertex = UnityObjectToClipPos(v.pos  + float4(displacement, 0));
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed fresnel = _FresnelScale * pow(1 - saturate(dot(i.worldNormal, i.viewDir)), _FresnelPower);
                fixed4 rimColor = _RimColor * fresnel;
                // get the scanline
                fixed4 scanline = tex2D(_ScanlineTex,  5 * i.uvScanline);
                scanline.a = Luminance(scanline);
                
                fixed4 col = tex2D(_MainTex, i.uv);
                fixed4 alpha = saturate(scanline.a + fresnel);
                
                fixed4 finalCol = fixed4(col.rgb, 0) +  scanline + rimColor;
                finalCol.a = clamp(alpha, _FresnelBias, 1);
                return flicker(i.noiseUV) * finalCol;
            }
            ENDCG
        }
    }
}
