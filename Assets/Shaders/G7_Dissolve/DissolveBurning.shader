Shader "Unlit/DissolveBurning"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _GradientTex ("Gradient", 2D) = "white" {}
        _NoiseTex("Noise", 2D) = "white" {}
        _Progress("Progress", Range(0,1)) = 0.5
        _EdgeWidth("Edge Width", Range(0.1, 2.0)) = 0.2
        _EdgeColor("Edge Color", Color) = (0,0,0,0)
        _EdgeIntensity("Edge Intensity", float) = 2.0
        _EdgeHardness("Edge Hardness", Range(0,0.5)) = 0.45
        _UVSpeed("Speed", Vector) = (1.0, 1.0, 0.0, 0.0)
        _Spread("Spread", Range(0,1)) = 1.0
        _DefaultClipValue("Mask Clip Value", Range(0,1)) = 0.5
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" }
        LOD 100

        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha 
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
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            sampler2D _GradientTex;
            sampler2D _NoiseTex;
            float4 _GradientTex_ST;
            float4 _NoiseTex_ST; 
            float4 _MainTex_ST;
            fixed _Progress;
            fixed _DefaultClipValue;
            fixed _EdgeWidth;
            fixed4 _EdgeColor;
            fixed _EdgeIntensity;
            fixed _EdgeHardness;
            fixed _Spread;
            fixed2 _UVSpeed; 

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            float remap(float n, float old_min, float old_max,
                        float new_min, float new_max)
            {
                return new_min + (new_max-new_min) * (n - old_min)/(old_max - old_min);
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                fixed alpha = tex2D(_GradientTex, i.uv).r;
                _Progress = remap(_Progress, 0, 1, -_Spread, 1); 
                alpha -= -_Progress;
                fixed progressSubtracted = 2 * (alpha / _Spread);

                // edge burning animation
                float2 newUV = i.uv + _UVSpeed * _Time;
                newUV = TRANSFORM_TEX(newUV, _NoiseTex);
                fixed delta = tex2D(_NoiseTex, newUV).r; 
                
                // get dissolve edge
                progressSubtracted -= delta;
                fixed dist = distance(progressSubtracted, _EdgeHardness);
                dist /= _EdgeWidth;
                fixed edgeArea = saturate(1 - dist);
                fixed4 edgeColor = lerp(col, _EdgeColor * _EdgeIntensity * col, edgeArea);
                col.rgb = edgeColor;

                // soften the edge
                alpha = smoothstep(_EdgeHardness, 0.5, progressSubtracted);
                alpha = alpha < _DefaultClipValue ? 0.0 : alpha;
                col.a *= alpha;
                return col;
            }
            ENDCG
        }
    }
}
