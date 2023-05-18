#pragma header

uniform float rOffset;
uniform float gOffset;
uniform float bOffset;

void main()
{
	vec4 col1 = flixel_texture2D(bitmap, openfl_TextureCoordv.st - vec2(rOffset, 0.0));
	vec4 col2 = flixel_texture2D(bitmap, openfl_TextureCoordv.st - vec2(gOffset, 0.0));
	vec4 col3 = flixel_texture2D(bitmap, openfl_TextureCoordv.st - vec2(bOffset, 0.0));
	vec4 toUse = flixel_texture2D(bitmap, openfl_TextureCoordv);
	toUse.r = col1.r;
	toUse.g = col2.g;
	toUse.b = col3.b;
	toUse.a = flixel_alpha(bitmap, openfl_TextureCoordv);
	gl_FragColor = toUse;
}