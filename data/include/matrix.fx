float4x4 inverseMatrix(float4x4 input)
{
     #define minor(a,b,c) determinant(float3x3(input.a, input.b, input.c))
     
     float4x4 cofactors = float4x4(
          minor(_22_23_24, _32_33_34, _42_43_44), 
         -minor(_21_23_24, _31_33_34, _41_43_44),
          minor(_21_22_24, _31_32_34, _41_42_44),
         -minor(_21_22_23, _31_32_33, _41_42_43),
         
         -minor(_12_13_14, _32_33_34, _42_43_44),
          minor(_11_13_14, _31_33_34, _41_43_44),
         -minor(_11_12_14, _31_32_34, _41_42_44),
          minor(_11_12_13, _31_32_33, _41_42_43),
         
          minor(_12_13_14, _22_23_24, _42_43_44),
         -minor(_11_13_14, _21_23_24, _41_43_44),
          minor(_11_12_14, _21_22_24, _41_42_44),
         -minor(_11_12_13, _21_22_23, _41_42_43),
         
         -minor(_12_13_14, _22_23_24, _32_33_34),
          minor(_11_13_14, _21_23_24, _31_33_34),
         -minor(_11_12_14, _21_22_24, _31_32_34),
          minor(_11_12_13, _21_22_23, _31_32_33)
     );
     #undef minor
     return transpose(cofactors) / determinant(input);
}

float4x4 makeZRotation( float angleInRadians) 
{
    float c = cos(angleInRadians);
    float s = sin(angleInRadians);
  
    return float4x4(
     c, s, 0, 0,
    -s, c, 0, 0,
     0, 0, 1, 0,
     0, 0, 0, 1
  );
}

float4x4 makeTranslation( float3 trans) 
{
    return float4x4(
     1,  0,  0,  0,
     0,  1,  0,  0,
     0,  0,  1,  0,
     trans.x, trans.y, trans.z, 1
    );
}

float4x4 createViewMatrix(float3 pos, float3 fwVec, float3 upVec)
{
    float3 zaxis = normalize(fwVec);
    float3 xaxis = normalize(cross(-upVec, zaxis));
    float3 yaxis = cross(xaxis, zaxis);

    float4x4 viewMatrix = {
        float4(xaxis.x, yaxis.x, zaxis.x, 0),
        float4(xaxis.y, yaxis.y, zaxis.y, 0),
        float4(xaxis.z, yaxis.z, zaxis.z, 0),
        float4(-dot(xaxis, pos), -dot(yaxis, pos), -dot(zaxis, pos),  1)
    };
    return viewMatrix;
}

float4x4 createProjectionMatrix(float near_plane, float far_plane, float fov_horiz, float fov_aspect)
{
    float h, w, Q;

    w = 1/tan(fov_horiz * 0.5);
    h = w / fov_aspect;
    Q = far_plane/(far_plane - near_plane);

    float4x4 projectionMatrix = {
        float4(w, 0, 0, 0),
        float4(0, h, 0, 0),
        float4(0, 0, Q, 1),
        float4(0, 0, -Q*near_plane, 0)
    };    
    return projectionMatrix;
}

float4x4 createOrthographicProjectionMatrix(float near_plane, float far_plane, float viewport_sizeX, float viewport_sizeY)
{
    float sizeX = 2 / viewport_sizeX;
    float sizeY = 2 / viewport_sizeY;
	
    float4x4 projectionMatrix = {
        float4(sizeX, 0,    0,  0),
        float4(0, sizeY, 0, 0),
        float4(0, 0, 1.0 / (near_plane - far_plane), 0),
        float4(0, 0, near_plane / (near_plane - far_plane), 1)
    };

    return projectionMatrix;
}

float4x4 createImageProjectionMatrix(float2 viewportPos, float2 viewportSize, float2 viewportScale, float adjustZFactor, float nearPlane, float farPlane)
{
    float Q = farPlane / ( farPlane - nearPlane );
    float rcpSizeX = 2.0f / viewportSize.x;
    float rcpSizeY = -2.0f / viewportSize.y;
    rcpSizeX *= adjustZFactor;
    rcpSizeY *= adjustZFactor;
    float viewportPosX = 2 * viewportPos.x;
    float viewportPosY = 2 * viewportPos.y;
	
    float4x4 sProjection = {
        float4(rcpSizeX * viewportScale.x, 0, 0,  0), float4(0, rcpSizeY * viewportScale.y, 0, 0), float4(viewportPosX, -viewportPosY, Q, 1),
        float4(( -viewportSize.x / 2.0f - 0.5f ) * rcpSizeX,( -viewportSize.y / 2.0f - 0.5f ) * rcpSizeY, -Q * nearPlane , 0)
    };

    return sProjection;
}