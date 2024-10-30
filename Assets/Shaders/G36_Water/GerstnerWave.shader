Shader "WaterRendering/Gerstner"
{
    Properties
    {
        _BaseColor("Color", Color) = (1,1,1,1)
        _BaseMap("Base Map", 2D) = "white" {}
         [Header(Wave Parameters)]
        _Wave1Direction("Wave 1 Direction (kx, kz)", Vector) = (1, 0, 1, 1)
        _Wave2Direction("Wave 2 Direction (kx, kz)", Vector) = (0.7, 0, 0.7, 1)
        _Wave3Direction("Wave 3 Direction (kx, kz)", Vector) = (0.5, 0, 0.5, 1)

        _Wave1Amplitude("Wave 1 Amplitude (a)", Float) = 1.0
        _Wave2Amplitude("Wave 2 Amplitude (a)", Float) = 0.8
        _Wave3Amplitude("Wave 3 Amplitude (a)", Float) = 0.6

        _Wave1Frequency("Wave 1 Frequency (ω)", Float) = 1.0
        _Wave2Frequency("Wave 2 Frequency (ω)", Float) = 0.9
        _Wave3Frequency("Wave 3 Frequency (ω)", Float) = 0.7

        _Wave1Phase("Wave 1 Phase (φ)", Float) = 0.5
        _Wave2Phase("Wave 2 Phase (φ)", Float) = 0.3
        _Wave3Phase("Wave 3 Phase (φ)", Float) = 0.1
    }
    
    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }
        
        Pass
        {
            HLSLPROGRAM
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3dll_9x
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile_instancing

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normal: NORMAL;
                float4 tangent: TANGENT;
                float2 uv: TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varying
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            CBUFFER_START(UnityPerMaterial)
            half4 _BaseColor;
            float4 _BaseMap_ST;
            
            // Wave parameters
            float4 _Wave1Direction, _Wave2Direction, _Wave3Direction;
            float _Wave1Amplitude, _Wave2Amplitude, _Wave3Amplitude;
            float _Wave1Frequency, _Wave2Frequency, _Wave3Frequency;
            float _Wave1Phase, _Wave2Phase, _Wave3Phase;
            
            CBUFFER_END

            TEXTURE2D(_BaseMap); SAMPLER(sampler_BaseMap);

            float3 CalculateGerstnerWave(float3 position, float4 direction, float amplitude, float frequency, float phase, float time)
            {
                float3 waveDir = normalize(direction.xyz);
                float k = length(direction.xyz); // Calculate wave vector magnitude
                float theta = dot(waveDir.xz, position.xz) * k - frequency * time + phase;

                // Horizontal displacement in x and z directions
                float3 horizontalDisplacement = waveDir * (amplitude * sin(theta));
                
                // Vertical displacement in y direction
                float verticalDisplacement = amplitude * cos(theta);

                // Return the combined displacement vector
                return float3(-horizontalDisplacement.x, verticalDisplacement, horizontalDisplacement.z);
            }
            
            Varying vert (Attributes input)
            {
                Varying output = (Varying)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);

                float3 pos = input.positionOS.xyz;
                float time = _Time.y;
                // Calculate wave contributions in 3D space
                pos += CalculateGerstnerWave(pos, _Wave1Direction, _Wave1Amplitude, _Wave1Frequency, _Wave1Phase, time);
                pos += CalculateGerstnerWave(pos, _Wave2Direction, _Wave2Amplitude, _Wave2Frequency, _Wave2Phase, time);
                pos += CalculateGerstnerWave(pos, _Wave3Direction, _Wave3Amplitude, _Wave3Frequency, _Wave3Phase, time);
                
                output.positionHCS = TransformObjectToHClip(pos);
                output.uv = TRANSFORM_TEX(input.uv, _BaseMap);

                return output;
            }

            half4 frag(Varying input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                half4 color = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv);
                return color * _BaseColor;
            }
            
            ENDHLSL
        }
    }
}