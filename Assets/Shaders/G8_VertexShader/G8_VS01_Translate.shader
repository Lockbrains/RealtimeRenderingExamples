Shader "Unlit/G8_VS01_Translate"
{
        Properties
    {
        [Header(Basic Phong)]
        [Space(10)]
        _MainTex ("Texture", 2D) = "white" {}
        _Ka ("Ambient Factor", Range(0,1)) = 0.1
        _Kd ("Diffuse Factor", Range(0,1)) = 0.9
        _Ks ("Specular Factor", Range(0,1)) = 0.5
        _Smoothness ("Smoothness", Range(1, 100)) = 50 
        
        [Header(Vertex Shader)]
        [Space(10)]
        _VertexOffset("Vertex Offset", Vector) = (0,0,0,0)
        _VertexScale("Vertex Scale", Vector) = (1,1,1,1)
        _VertexRotation("Rotation In Degrees", float) = 0.0
        _VertexRotateAxis("Rotate Along Axis", Vector) = (1,0,0,0)
        _VertexRotatePivotPoint("Rotate Pivot Point", Vector) = (0,0,0,0)
        
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
            
            float4 _VertexOffset;
            float4 _VertexScale;
            float _VertexRotation;
            float4 _VertexRotateAxis;
            float3 _VertexRotatePivotPoint;

            float4 vertexOffset(appdata i, float4 offset)
            {
                float4 vertex = i.vertex + offset;
                return TransformObjectToHClip(vertex);
            }

            float4 vertexScaleAndOffset(appdata i, float4 scale, float4 offset)
            {
                float4 vertex = i.vertex * scale;
                vertex += offset;
                return TransformObjectToHClip(vertex);
            }
            
            float3 rotateAlongAxis(float3 p, float3 axis, float3 pivot, float angle)
            {
                float3 translatedP = p - pivot;
                
                float rad = radians(angle);
                float s = sin(rad);
                float c = cos(rad);
                float oc = 1.0 - c;

                axis = normalize(axis);

                float3x3 rotMatrix = float3x3(
                    oc * axis.x * axis.x +c, oc * axis.x * axis.y - axis.z * s, oc * axis.z * axis.x + axis.y * s,
                    oc * axis.x * axis.y + axis.z * s, oc * axis.y * axis.y + c,        oc * axis.y * axis.z - axis.x * s,
                    oc * axis.z * axis.x - axis.y * s, oc * axis.y * axis.z + axis.x * s, oc * axis.z * axis.z + c
                );

                float3 rotatedP = mul(rotMatrix, translatedP);
                return rotatedP + pivot;
            }

            float4 vertexSRT(appdata i, float4 scale, float3 rotAxis, float3 pivot, float angle, float4 offset)
            {
                // Scale, Rotation, Translate
                float4 vertex = i.vertex * scale;
                vertex = float4(rotateAlongAxis(vertex.xyz, rotAxis, pivot, angle), vertex.w);
                vertex += offset;
                return TransformObjectToHClip(vertex);
            }
            
            v2f vert (appdata v)
            {
                v2f o;
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

                // set vertex position

                /// offset
                // o.vertex = vertexOffset(v, _VertexOffset);
                /// Scale And Offset
                // o.vertex = vertexScaleAndOffset(v, _VertexScale, _VertexOffset);
                /// Scale, Rotate and Offset
                o.vertex = vertexSRT(v, _VertexScale, _VertexRotateAxis, _VertexRotatePivotPoint ,_VertexRotation, _VertexOffset);
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
