Shader "Custom/Phong"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Ka ("Ambient Factor", Range(0,1)) = 0.1
        _Kd ("Diffuse Factor", Range(0,1)) = 0.9
        _Ks ("Specular Factor", Range(0,1)) = 0.5
        _Smoothness ("Smoothness", Range(1, 100)) = 50 
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "UniversalRenderPipeline"="True"}
        LOD 100

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float3 normal: TEXCOORD1;
                float3 lightDir : TEXCOORD2;
                float3 reflect : TEXCOORD3;
                float3 viewDir: TEXCOORD4;
                float3 worldPos : TEXCOORD5;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Ka;
            float _Kd;
            float _Ks;
            float _Smoothness;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex);
                half3 worldPos = TransformObjectToWorld(v.vertex).xyz;
                o.worldPos = worldPos;
                
                // Light Direction
                Light mainLight = GetMainLight();
                o.lightDir = normalize(mainLight.direction);

                // View Direction
                o.viewDir = GetWorldSpaceNormalizeViewDir(worldPos);

                // Normal
                o.normal = normalize(TransformObjectToWorldNormal(v.normal));

                // Reflect
                o.reflect = reflect(-o.lightDir, o.normal);
                
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                // sample the texture
                half4 col = tex2D(_MainTex, i.uv);

                half3 ambient, diffuse, specular;
                half3 Id, Ia, Is;
                Light mainLight = GetMainLight();
                Ia = _GlossyEnvironmentColor.rgb;
                Id = mainLight.color;
                Is = mainLight.color;

                // Ambient
                ambient = _Ka * Ia;

                // Diffuse
                diffuse = _Kd * Id * saturate(dot(i.normal, i.lightDir));

                // Specular
                specular = _Ks * Is * pow(saturate(dot(i.reflect, i.viewDir)), _Smoothness);

                half3 color = saturate(ambient + diffuse + specular);
                return half4(color, 1.0) * col;

                
            }
            ENDHLSL
        }
    }
    Fallback "Diffuse"
}
