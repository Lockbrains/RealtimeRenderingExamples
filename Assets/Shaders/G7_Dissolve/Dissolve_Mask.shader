Shader "Unlit/Dissolve_Mask"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _MaskTex ("Mask", 2D) = "white" {}
        _NoiseTex("Noise", 2D) = "white" {}
        _EdgeColor ("Edge Color", Color) = (0,0,0,0)
        _EdgeWidth ("Edge Width", Float) = 2.0
        _EdgeIntensity ("Edge Intensity", Float) = 2.0
        _Cutoff("Alpha cutoff", Range(0,1)) = 0.5
        _Progress("Progress", Range(0,1)) = 0.0
        _BurnDirection("Burn Direction", Vector) = (1.0, 1.0, 0.0, 0.0)
        _BurnSpeed("Speed", float) = 1.0
    }
    SubShader
    {
        Tags { "Queue"="AlphaTest" "RenderType"="TransparentCutout" }
        LOD 100

        Pass
        {
            AlphaTest Greater [_Cutoff]
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float2 noiseUV : TEXCOORD1;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _NoiseTex_ST;
            float4 _EdgeColor;
            sampler2D _MaskTex;
            sampler2D _NoiseTex;
            float _Cutoff;
            float _Progress;
            float _EdgeWidth;
            float _EdgeIntensity;
            float2 _BurnDirection;
            float _BurnSpeed;
            
            float remap (float x, float old_min, float old_max , float new_min, float new_max)
            {
                const float percentage = (x-old_min) / (old_max - old_min);
                return new_min + percentage * (new_max - new_min);
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.noiseUV = o.uv + _BurnSpeed * _BurnDirection * _Time;
                o.noiseUV = TRANSFORM_TEX(o.noiseUV, _NoiseTex);  
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                fixed maskAlpha = tex2D(_MaskTex, i.uv).r;
                maskAlpha -= remap(_Progress, 0, 1, -1.5, 0.51);
                fixed delta = tex2D(_NoiseTex, i.noiseUV).r;
                maskAlpha -= delta;
                col.a = maskAlpha;
                
                fixed dist = 1 - _EdgeWidth * distance(maskAlpha, _Cutoff);
                fixed edgeArea = saturate(dist);
                fixed4 edgeColor = lerp(col, _EdgeColor * _EdgeIntensity, edgeArea);
                col.rgb = edgeColor;
                
                clip(col.a - _Cutoff);
                return col;
            }
            ENDCG
        }
    }
}
