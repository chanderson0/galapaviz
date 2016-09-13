#version 330

in vec4 position;

in vec2 texcoord;
out vec2 uv;

void main()
{
    uv = texcoord;
    gl_Position = position;
}
