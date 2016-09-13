#version 120
#extension GL_EXT_gpu_shader4 : require

uniform mat4 transformMatrix[200];
uniform vec3 position[200];

varying vec3 vertex_light_position;
varying vec3 vertex_normal;

void main(){

    // Calculate the normal value for this vertex, in world coordinates
    // (multiply by gl_NormalMatrix and transformation matrix)
    vertex_normal = normalize( mat3(transformMatrix[gl_InstanceID] ) * gl_NormalMatrix * gl_Normal);

    // Calculate the light position for this vertex
    vertex_light_position = normalize( gl_LightSource[0].position.xyz );

    // Set the front color to the color passed through with glColor
    gl_FrontColor = gl_Color;
    gl_BackColor = gl_Color;

    // Multiply the shape coordinates by the transformation matrix
    // Offset by the position
    vec4 vPos = vec4( position[gl_InstanceID], 0 ) + ( transformMatrix[gl_InstanceID] *  gl_Vertex );

    // Multiply by the model view and projection matrix
    gl_Position = gl_ProjectionMatrix * gl_ModelViewMatrix  * vPos;
}
