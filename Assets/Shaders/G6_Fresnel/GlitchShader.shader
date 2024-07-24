Shader "Unlit/GlitchShader"
{
    Properties
    {
        _MainTex("Base Map", 2D) = "white" {}
        [HDR] _Tint ("Base Map Tint", Color) = (1,1,1,1)
        _N_map("Noise", 2D) = "white" {}
        _M_map("Mask", 2D) = "white" {}
        _GlitchIntensity("Glitch Intensity", float) = 5

        [Space(20)]
        _Bias("Fresnel Bias", range (0,1)) = 0
        _Scale ("Fresnel Scale ", range (0,10)) = 0
        _Power("Fresnel Power", range (0,3)) = 0
        _Speed("Glitch Speed", range (-1,1)) = 0
        
        [Space(20)]
        [Toggle] _EnableX("Active X axis", Float) = 1
        [Toggle] _EnableY("Active Y axis", Float) = 0
        [Toggle] _EnableZ("Active Z axis", Float) = 0
        
        [Space(20)]
        [Header(Anim)]
        [HDR] _Color ("Vertex Outline Color Mult", Color) = (1,1,1,1)
        _Amount("Vertex Animation Amount", Range(0, 1)) = 0

        [Space(20)]
        [Toggle] _EnableDirColor("开启方向颜色(不开为彩色)", Float) = 0
        [HDR] _DirColor1("_DirColor1",Color) = (1,0,0,0)
        [HDR] _DirColor2("_DirColor2",Color) = (0,1,0,0)
    }

    Subshader
    {
        //http://docs.unity3d.com/462/Documentation/Manual/SL-SubshaderTags.html
        // Background : 1000     -        0 - 1499 = Background
        // Geometry   : 2000     -     1500 - 2399 = Geometry
        // AlphaTest  : 2450     -     2400 - 2699 = AlphaTest
        // Transparent: 3000     -     2700 - 3599 = Transparent
        // Overlay    : 4000     -     3600 - 5000 = Overlay
        Tags
        {
            "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Geometry"
        }
        
        Pass
        {
            CGPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            //http://docs.unity3d.com/ru/current/Manual/SL-ShaderPerformance.html
            //http://docs.unity3d.com/Manual/SL-ShaderPerformance.html

            // VARIABLES ///////////////////////////////////////////////////////////////////////////////////////////
            sampler2D _MainTex;
            float4 _Color;
            float4 _Tint;
            sampler2D _N_map;
            sampler2D _M_map;

            float4 _N_map_ST;
            float4 _M_map_ST;
            float _GlitchIntensity;
            float _Bias;
            float _Scale;
            float _Power;
            float _Speed;
            float _EnableX,_EnableY,_EnableZ;

            float _Distance;
            float _Amplitude;
            float _Amount;

            float _EnableDirColor;
            float4 _DirColor1,_DirColor2;

            // STRUCTURS  //////////////////////////////////////////////////////////////////////////////////////////
            struct MeshData
            {
                float4 vertex : POSITION;
                float2 uv     : TEXCOORD0;
                float4 normal : NORMAL;
            };

            struct V2FData
            {
                float4 pos      : SV_POSITION;
                float2 uv       : TEXCOORD0;
                float3 normalWS : TEXCOORD3;
                float3 posWS    : TEXCOORD4;
            };

            ////////////////////////////////////////////////////////////////////////////////////////////////////////

            
            // FUNCTIONS /////////////////////////////////////////////////////////////////////////////////////////////
            float4 GlitchNoise(float2 coord)
            {
                float4 c = float4(coord, 0, 1);
                float4 d;
                float4 e;
                for (int j = 16; j > 0; j--)
                {
                    e = floor(c);
                    d += sin(e * e.yxyx + e * (_Time / 10));
                    c *= 2.5;
                }
                float4 glitch_res = d;
                return glitch_res;
            }
            
            #define SPEED_TIME  _Time.x * _Speed * 30

            float4 GetMask(float2 uv)
            {
                float SpeedTime = SPEED_TIME;
                float offset_sin = sin(SpeedTime * 2) + 1;//值域(-1,1)->(0,1)
                float offset_cos = cos(SpeedTime * 2);
                
                //在顶点中采样贴图必须需要用 tex2Dlod 手动制定采样贴图的mip
                //tex2D在PS中采样，gpu会根据当相机的距离自动 切换贴图的mip
                //tex2Dlod 在vs与ps中都可以使用
                float4 Mask = tex2Dlod(_M_map, float4(uv * float2(_M_map_ST.y, _M_map_ST.y * offset_cos) + float2(_M_map_ST.z, _M_map_ST.w * offset_sin), 0, 0));
                return Mask;
            }
            
            // VERTEX OPERATIONS ////////////////////////////////////////////////////////////////////////////////////
            V2FData vert(MeshData input)
            {
                V2FData output;
                
                float4 Mask = GetMask(input.uv);
                float4 glitchNoise = GlitchNoise(input.uv.xy)*0.002 * Mask.x;
                
                float3 Direction = float3(_EnableX,_EnableY, _EnableZ);
                //根据噪音 做顶点偏移 顶点动画
                input.vertex.xyz += glitchNoise.xyz * Direction * input.normal.xyz * 10*_Amount;

                output.pos = UnityObjectToClipPos(input.vertex);

                //将UV从vs传入到PS
                output.uv = input.uv;
                output.posWS =mul(unity_ObjectToWorld, input.vertex).xyz;

                //将法线从局部空间变换到世界空间，需要乘上 逆转矩阵
                output.normalWS = UnityObjectToWorldNormal(input.normal);

                return output;
            }

            float3 HSVToRGB( float3 c )
			{
				float4 K = float4( 1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0 );
				float3 p = abs( frac( c.xxx + K.xyz ) * 6.0 - K.www );
				return c.z * lerp( K.xxx, saturate( p - K.xxx ), c.y );
			}

            float4 frag(V2FData input) : SV_Target
            {
                /// TIME ANIMATION
                float SpeedTime = SPEED_TIME;
                
                //采样噪音 采样Mask
                float4 Mask = GetMask(input.uv);
                float4 Noise = tex2D(_N_map, float2(input.uv.xy * _N_map_ST.xy + _N_map_ST.zw * SpeedTime));
                float4 BaseMap = tex2D(_MainTex, input.uv);

                //程序化噪音 扰动UV&颜色
                float noiseMask = Noise.x * Mask.x;
               
                float2 distortUV = input.uv + noiseMask * sin(SpeedTime) * input.uv.x * _GlitchIntensity;
                
                float4 glitchNoise = GlitchNoise(distortUV);
               
                float4 glitchColor = (float4)0;
             
                if(_EnableDirColor==1)
                {
                    //将法线变换到相机空间坐标系
                    float3 normalVS = mul((float3x3)unity_WorldToCamera,input.normalWS);
                    // glitchColor = saturate(normalVS.x) * _DirColor2;
                    // glitchColor += saturate(-normalVS.x) * _DirColor1;
                    glitchColor = lerp(_DirColor1,_DirColor2,normalVS.x*0.5+0.5);
                }
                else
                {
                    glitchColor = HSVToRGB(float3 (frac(input.posWS.x),1,0.5)).xyzz;
                }
                
                //// Color distortion
                glitchColor.r += noiseMask * saturate( sin(SpeedTime))   * glitchNoise.x * _GlitchIntensity * 0.08;
                glitchColor.g += noiseMask * saturate(sin(SpeedTime * 2)) * glitchNoise.y * _GlitchIntensity * 0.325;
                glitchColor.b += noiseMask * saturate(sin(SpeedTime * 4)) * glitchNoise.x * _GlitchIntensity * 0.75;

                BaseMap *= _Tint;

                //视线方向
                float3 V = normalize(input.posWS - _WorldSpaceCameraPos.xyz);
                float3 L = normalize(_WorldSpaceLightPos0);
                float3 N = normalize(input.normalWS);
                float NV_Bias = saturate( dot(V, input.normalWS) + _Bias);
                float Fresnel =  _Scale * pow(NV_Bias, _Power);

                /// Results
                float4 FinalColor = lerp(BaseMap, glitchColor,Fresnel);//*noiseMask;
                return FinalColor;
            }

            ENDCG
        }
    }

    Fallback "Diffuse"
}
