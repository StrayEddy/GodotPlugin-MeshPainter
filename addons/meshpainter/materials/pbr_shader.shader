shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_back,diffuse_burley,specular_schlick_ggx;

uniform sampler2D texture_albedo : hint_albedo;
uniform sampler2D texture_metallic : hint_white;
uniform sampler2D texture_roughness : hint_white;
uniform sampler2D texture_emission : hint_black_albedo;

uniform vec4 albedo : hint_color;
uniform float specular : hint_range(0,1);
uniform float metallic : hint_range(0,1);
uniform float roughness : hint_range(0,1);
uniform float point_size : hint_range(0,128);
uniform vec4 emission : hint_color;
uniform float emission_energy;
uniform vec3 uv1_scale;
uniform vec3 uv1_offset;
uniform vec3 uv2_scale;
uniform vec3 uv2_offset;


void vertex() {
	UV=UV*uv1_scale.xy+uv1_offset.xy;
}


void fragment() {
	vec2 base_uv = UV;
	vec4 albedo_tex = texture(texture_albedo,base_uv);
	vec4 metallic_tex = texture(texture_metallic,base_uv);
	vec4 roughness_tex = texture(texture_roughness,base_uv);
	vec3 emission_tex = texture(texture_emission,base_uv).rgb;
	ALBEDO = albedo.rgb * albedo_tex.rgb;
	METALLIC = metallic * metallic_tex.r;
	ROUGHNESS = roughness * roughness_tex.r;
	SPECULAR = specular;
	EMISSION = (emission.rgb+emission_tex)*emission_energy;
}
