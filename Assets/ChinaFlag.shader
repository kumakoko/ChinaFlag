// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "ChinaFlag"
{
    Properties
    {
    }

    CGINCLUDE
    #include "UnityCG.cginc"
    #pragma target 3.0

    struct v2f 
    {
        float4 pos : SV_POSITION;
        float4 scrPos : TEXCOORD0;
    };              

    v2f vert(appdata_base v)
    {
        v2f o;
        o.pos = UnityObjectToClipPos (v.vertex);
        o.scrPos = ComputeScreenPos(o.pos);
        return o;
    }  

    const float HALF_PI = 3.1415 / 2.0;

    // 判断C和P在直线AB的同一侧
    bool IsSameSide(float2 a, float2 b, float2 c, float2 p)
    {
        float2 AB = b - a;
        float2 AC = c - a;
        float2 AP = p - a;
        float f1 = AB.x * AC.y - AB.y * AC.x;
        float f2 = AB.x * AP.y - AB.y * AP.x;
        return f1*f2 >= 0.0;
    }

    bool IsPointInTriangle(float2 a, float2 b, float2 c, float2 p)
    {
        return IsSameSide(a, b, c, p) && IsSameSide(b, c, a, p) && IsSameSide(c, a, b, p);
    }

    float2 RotateStar(float2 star, float angle)
    {
        // star.x = star.x * cos(angle) - star.y * sin(angle)
        // star.y = star.x * sin(angle) + star.y * cos(angle)
        float cos_angle = cos(angle);
        float sin_angle = sin(angle);
        float2 rotated_star = float2(0.0,0.0);
        rotated_star.x = dot(star , float2(cos_angle,-sin_angle));
        rotated_star.y = dot(star , float2(sin_angle,cos_angle));
        return rotated_star;
    }

    // TSR的xy分量是水平和垂直方向上的平移度值，z分量是缩放值，w分量是旋转角度值
    // p是待检测顶点的xy值
    bool InStar(float4 TSR, float2 p)
    {
        float2 scale = float2(TSR.z,TSR.z);
        float2 translation = float2(TSR.x,TSR.y);
        
        float2 A = float2(0.0,1.0);
        float2 B = float2(-0.95,0.31);
        float2 C = float2(-0.59,-0.81);
        float2 D = float2(0.59,-0.81);
        float2 E = float2(0.95,0.31);
        float2 F = float2(0,-0.38);
        float2 G = float2(0.36,-0.12);
        float2 H = float2(0.22,0.31);
        float2 I = float2(-0.22,0.31);
        float2 J = float2(-0.36,-0.11);
        float2 O = float2(0.0,0.0);
        
        // AHO
        float2 a = RotateStar(A*scale, TSR.w) + translation;
        float2 h = RotateStar(H*scale, TSR.w) + translation;
        float2 o = RotateStar(O*scale, TSR.w) + translation;
        bool in_triangle = IsPointInTriangle(a,h,o,p);
        if (in_triangle) return in_triangle;
        
        // HEO
        float2 e = RotateStar(E*scale, TSR.w) + translation;
        in_triangle = IsPointInTriangle(h,e,o,p);
        if (in_triangle) return in_triangle;
        
        // EGO
        float2 g = RotateStar(G*scale, TSR.w) + translation;
        in_triangle = IsPointInTriangle(e,g,o,p);
        if (in_triangle) return in_triangle;
        
        // GDO
        float2 d = RotateStar(D*scale, TSR.w) + translation;
        in_triangle = IsPointInTriangle(g,d,o,p);
        if (in_triangle) return in_triangle;
        
        // DFO
        float2 f = RotateStar(F*scale, TSR.w) + translation;
        in_triangle = IsPointInTriangle(d,f,o,p);
        if (in_triangle) return in_triangle;
        
        // FCO
        float2 c = RotateStar(C*scale, TSR.w) + translation;
        in_triangle = IsPointInTriangle(f,c,o,p);
        if (in_triangle) return in_triangle;
        
        // CJO
        float2 j = RotateStar(J*scale, TSR.w) + translation;
        in_triangle = IsPointInTriangle(c,j,o,p);
        if (in_triangle) return in_triangle;
        
        // JBO
        float2 b = RotateStar(B*scale, TSR.w) + translation;
        in_triangle = IsPointInTriangle(j,b,o,p);
        if (in_triangle) return in_triangle;
        
        // BIO
        float2 i = RotateStar(I*scale, TSR.w) + translation;
        in_triangle = IsPointInTriangle(b,i,o,p);
        if (in_triangle) return in_triangle;
        
        // IAO
        in_triangle = IsPointInTriangle(i,a,o,p);
        if (in_triangle) return in_triangle;
        
        return false;
    }


    float4 frag(v2f _iParam) : COLOR0
    {
        float4 color_golden = float4(1.0,1.0,0.0,1.0);
        float4 color_red = float4(1.0,0.0,0.0,1.0);
        float2 fragCoord = _iParam.scrPos.xy/_iParam.scrPos.w * float2(960.0,640.0);
        float2 screen_resolution = float2(960.0,640.0);
        // 把旗帜水平方向水平分为30等分，垂直方向分为20等分，大五角星的中心点，在水平方向第5格右下角，垂直方向第5格右下角，所以
        // 大五角星的translation为 screen_resolution.x / 30.0 * 5.0, screen_resolution - screen_resolution.x / 20.0 * 5.0,
        // 大五角星的外接圆半径为垂直方向3个格子，所以scale为screen_resolution.x / 20.0 * 3.0
        float4 TSR = float4(screen_resolution.x / 6.0,screen_resolution.y -screen_resolution.y / 4.0,
                                                screen_resolution.y / 20.0 * 3.0,0.0);
        float2 p = float2(fragCoord.x, fragCoord.y);
        if (InStar(TSR,p))
            return color_golden;
        
        // 第一个小五角星的translation为 screen_resolution.x / 30.0 * 10.0, screen_resolution - screen_resolution.x / 20.0 * 2.0,
        // 第一个小五角星的外接圆半径为垂直方向3个格子，所以scale为screen_resolution.x / 20.0 * 1.0
        TSR = float4(screen_resolution.x / 30.0 * 10.0,screen_resolution.y - screen_resolution.y / 20.0 * 2.0,
                                                screen_resolution.y / 20.0, HALF_PI + atan(3.0/5.0));
        p = float2(fragCoord.x, fragCoord.y);
        if (InStar(TSR,p))
            return color_golden;
        
        // 第二个小五角星的translation为 screen_resolution.x / 30.0 * 12.0, screen_resolution - screen_resolution.x / 20.0 * 4.0,
        // 第二个小五角星的外接圆半径为垂直方向3个格子，所以scale为screen_resolution.x / 20.0 * 1.0
        TSR = float4(screen_resolution.x / 30.0 * 12.0,screen_resolution.y - screen_resolution.y / 20.0 * 4.0,
                                                screen_resolution.y / 20.0,HALF_PI + atan(1.0/7.0));
        p = float2(fragCoord.x, fragCoord.y);
        if (InStar(TSR,p))
            return color_golden;
        
        // 第三个小五角星的translation为 screen_resolution.x / 30.0 * 12.0, screen_resolution - screen_resolution.x / 20.0 * 7.0,
        // 第三个小五角星的外接圆半径为垂直方向3个格子，所以scale为screen_resolution.x / 20.0 * 1.0
        TSR = float4(screen_resolution.x / 30.0 * 12.0,screen_resolution.y - screen_resolution.y / 20.0 * 7.0,
                                                screen_resolution.y / 20.0, atan(7.0/2.0));
        p = float2(fragCoord.x, fragCoord.y);
        if (InStar(TSR,p))
            return color_golden;
        
        // 第四个小五角星的translation为 screen_resolution.x / 30.0 * 10.0, screen_resolution - screen_resolution.x / 20.0 * 9.0,
        // 第四个小五角星的外接圆半径为垂直方向3个格子，所以scale为screen_resolution.x / 20.0 * 1.0
        TSR = float4(screen_resolution.x / 30.0 * 10.0,screen_resolution.y - screen_resolution.y / 20.0 * 9.0,
                                                screen_resolution.y / 20.0, atan(5.0/4.0));
        p = float2(fragCoord.x, fragCoord.y);
        if (InStar(TSR,p))
            return color_golden;

        return color_red;
    }

    ENDCG

    SubShader
    {    
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            ENDCG    
        }    
    }
    
    FallBack Off    
}