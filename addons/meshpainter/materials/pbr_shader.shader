shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_back,diffuse_burley,specular_schlick_ggx;

uniform sampler2D tex_albedo_brush : hint_albedo; // (r: x, g: y, b:z, a: size)
uniform sampler2D tex_albedo_color : hint_albedo;
uniform sampler2D tex_roughness_brush : hint_albedo; // (r: x, g: y, b:z, a: size)
uniform sampler2D tex_roughness_color : hint_albedo;
uniform sampler2D tex_metalness_brush : hint_albedo; // (r: x, g: y, b:z, a: size)
uniform sampler2D tex_metalness_color : hint_albedo;
uniform sampler2D tex_emission_brush : hint_albedo; // (r: x, g: y, b:z, a: size)
uniform sampler2D tex_emission_color : hint_albedo;

uniform vec3 uv1_scale;
uniform vec3 uv1_offset;

varying vec4 vertex_pos;

void vertex() {
	UV=UV*uv1_scale.xy+uv1_offset.xy;
	vertex_pos = vec4(VERTEX.x, VERTEX.y, VERTEX.z, 0.0);
}

vec4 get_albedo() {
	vec4 albedo = vec4(1,1,1,1);
	
	for (int y = 0; y < textureSize(tex_albedo_brush, 0).y; y++) 
	{
		for (int x = 0; x < textureSize(tex_albedo_brush, 0).x; x++) 
		{
			vec4 brush_texel = texelFetch(tex_albedo_brush, ivec2(x, y), 0);
			float brush_size = brush_texel.a * 100.0;
			float dist = distance(vertex_pos.xyz, brush_texel.xyz);
			if (brush_size == 0.0)
				break;
			
			if (dist < brush_size) {
				vec4 color = texelFetch(tex_albedo_color, ivec2(x, y), 0);
				albedo = mix(albedo, color, color.a);
			}
		}
	}
	return albedo;
}

vec4 get_roughness() {
	vec4 roughness = vec4(1,1,1,1);
	
	for (int y = 0; y < textureSize(tex_roughness_brush, 0).y; y++) 
	{
		for (int x = 0; x < textureSize(tex_roughness_brush, 0).x; x++) 
		{
			vec4 brush_texel = texelFetch(tex_roughness_brush, ivec2(x, y), 0);
			float brush_size = brush_texel.a * 100.0;
			float dist = distance(vertex_pos.xyz, brush_texel.xyz);
			if (brush_size == 0.0)
				break;
			
			if (dist < brush_size) {
				vec4 color = texelFetch(tex_roughness_color, ivec2(x, y), 0);
				roughness = color;
			}
		}
	}
	return roughness;
}

void fragment() {
	vec4 albedo = get_albedo();
	vec4 roughness = get_roughness();
	ALBEDO = albedo.rgb;
	ROUGHNESS = roughness.r;
//	METALLIC = mrae_info.r;
//	EMISSION = albedo.rgb*mrae_info.a;
}
