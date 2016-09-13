#version 120
#extension GL_EXT_gpu_shader4 : require

varying vec3 vertex_light_position;
varying vec3 vertex_normal;

void main(){

    // calculate the shading based on the normal
    float diffuse_value = max(dot(vertex_normal, vertex_light_position), 0.0);
    diffuse_value = 0.1 + diffuse_value * 0.9;

    // set the output color of our current pixel
    gl_FragColor = vec4( vec4(gl_Color * diffuse_value).rgb, 1.0 );
}
