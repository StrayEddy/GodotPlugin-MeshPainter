shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_back,diffuse_burley,specular_schlick_ggx;

// Texture containing brush info (r: x, g: y, b:z, a: size)
uniform sampler2D texture_brush_info : hint_albedo;
// Texture containing albedo info
uniform sampler2D texture_albedo_info : hint_albedo;
// Texture packing metallic, roughness, ambient occlusion and emission
uniform sampler2D texture_mrae_info : hint_albedo;

uniform vec3 uv1_scale;
uniform vec3 uv1_offset;

varying vec4 vertex_pos;

void vertex() {
	UV=UV*uv1_scale.xy+uv1_offset.xy;
	vertex_pos = vec4(VERTEX.x, VERTEX.y, VERTEX.z, 0.0);
}

void fragment() {
	vec2 base_uv = UV;
	vec4 mrae_info = texture(texture_mrae_info, base_uv);
	
	vec4 albedo = vec4(1,1,1,1);
	
	for (int y = 0; y < textureSize(texture_brush_info, 0).y; y++) 
	{
		for (int x = 0; x < textureSize(texture_brush_info, 0).x; x++) 
		{
			vec4 brush_texel = texelFetch(texture_brush_info, ivec2(x, y), 0);
			float brush_size = brush_texel.a;
			float dist = distance(vertex_pos.xyz, brush_texel.xyz);
			if (brush_size == 0.0)
				break;
			
			if (dist < brush_size) {
				vec4 color = texelFetch(texture_albedo_info, ivec2(x, y), 0);
				albedo = mix(albedo, color, color.a);
			}
		}
	}
	
	ALBEDO = albedo.rgb;
	METALLIC = mrae_info.r;
	ROUGHNESS = mrae_info.g;
	EMISSION = albedo.rgb*mrae_info.a;
}
