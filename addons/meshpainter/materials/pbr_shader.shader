// Spatial shader to paint albedo, roughness, metalness and emission unto mesh
// Brush textures hold brush sphere center positions and sizes (r: x, g: y, b:z, a: size)
// Color textures hold color of the texture to be used for that brush position

shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_back,diffuse_burley,specular_schlick_ggx;

uniform sampler2D tex_albedo_brush : hint_albedo; // (r: x, g: y, b:z, a: size)
uniform sampler2D tex_albedo_color : hint_albedo;
uniform sampler2DArray tex_albedo_layers : hint_albedo;

uniform sampler2D tex_roughness_brush : hint_albedo; // (r: x, g: y, b:z, a: size)
uniform sampler2D tex_roughness_color : hint_albedo; // r, g and b all at same value (0.0 - 1.0)
uniform sampler2DArray tex_roughness_layers : hint_albedo;

uniform sampler2D tex_metalness_brush : hint_albedo; // (r: x, g: y, b:z, a: size)
uniform sampler2D tex_metalness_color : hint_albedo; // r, g and b all at same value (0.0 - 1.0)
uniform sampler2DArray tex_metalness_layers : hint_albedo;

uniform sampler2D tex_emission_brush : hint_albedo; // (r: x, g: y, b:z, a: size)
uniform sampler2D tex_emission_color : hint_albedo; // rgb at same value (0.0 - 1.0) and a for intensity
uniform sampler2DArray tex_emission_layers : hint_albedo;

uniform vec3 uv1_scale;
uniform vec3 uv1_offset;
varying vec3 uv1_triplanar_pos;
varying vec3 uv1_power_normal;

varying vec3 vertex_pos;

void vertex() {
	UV=UV*uv1_scale.xy+uv1_offset.xy;
	
	// Keep vertex position to use in fragment()
	vertex_pos = vec3(VERTEX.x, VERTEX.y, VERTEX.z);

	// Prepare triplanar
	uv1_power_normal=pow(abs(NORMAL),vec3(100));
	uv1_power_normal/=dot(uv1_power_normal,vec3(1.0));
	uv1_triplanar_pos = VERTEX * uv1_scale + uv1_offset;
	uv1_triplanar_pos *= vec3(1.0,-1.0, 1.0);
}

vec4 triplanar_texture(sampler2DArray p_sampler_array, float layer_idx, vec3 p_weights,vec3 p_triplanar_pos) {
	vec4 samp=vec4(0.0);
	samp+= texture(p_sampler_array,vec3(p_triplanar_pos.xy,layer_idx)) * p_weights.z;
	samp+= texture(p_sampler_array,vec3(p_triplanar_pos.xz,layer_idx)) * p_weights.y;
	samp+= texture(p_sampler_array,vec3(p_triplanar_pos.zy * vec2(-1.0,1.0),layer_idx)) * p_weights.x;
	return samp;
}

// Albefo retrieval
vec4 get_albedo() {
	// Default albedo is white
	vec4 albedo = vec4(1,1,1,1);
	
	// Go through albedo brush texture to find brush centers that are close enough to current pixel
	// Then calculate albedo color based on the combination of all those brush distances
	for (int y = 0; y < textureSize(tex_albedo_brush, 0).y; y++) 
	{
		for (int x = 0; x < textureSize(tex_albedo_brush, 0).x; x++) 
		{
			// Get brush pixel info
			vec4 brush_texel = texelFetch(tex_albedo_brush, ivec2(x, y), 0);
			
			// Increase size of brush so it can be possible to have a huge size brush for bucket fill
			float brush_size = brush_texel.a * 100.0;
			float dist = distance(vertex_pos.xyz, brush_texel.xyz);
			// If we reach the end of brush buffer, we stop the loop
			if (brush_size == 0.0)
				break;
			// Get color of close enough brush to mix paint the current pixel
			if (dist < brush_size) {
				vec4 color = texelFetch(tex_albedo_color, ivec2(x, y), 0);
				if (color.a == 0.0) {
					vec4 new_albedo = triplanar_texture(tex_albedo_layers,color.r,uv1_power_normal,uv1_triplanar_pos);
					albedo = mix(albedo, new_albedo, color.g);
				}
				else {
					albedo = mix(albedo, color, color.a);
				}
			}
		}
	}
	return albedo;
}

// Roughness retrieval
vec4 get_roughness() {
	// Default roughness is 1.0
	vec4 roughness = vec4(1,1,1,1);
	
	// Go through roughness brush texture to find brush centers that are close enough to current pixel
	// Then calculate roughness based on the combination of all those brush distances
	for (int y = 0; y < textureSize(tex_roughness_brush, 0).y; y++) 
	{
		for (int x = 0; x < textureSize(tex_roughness_brush, 0).x; x++) 
		{
			// Get brush pixel info
			vec4 brush_texel = texelFetch(tex_roughness_brush, ivec2(x, y), 0);
			// Increase size of brush so it can be possible to have a huge size brush for bucket fill
			float brush_size = brush_texel.a * 100.0;
			float dist = distance(vertex_pos.xyz, brush_texel.xyz);
			// If we reach the end of brush buffer, we stop the loop
			if (brush_size == 0.0)
				break;
			
			// Use last color of close enough brush for current pixel
			if (dist < brush_size) {
				vec4 color = texelFetch(tex_roughness_color, ivec2(x, y), 0);
				roughness = color;
			}
		}
	}
	return roughness;
}

// Metalness retrieval
vec4 get_metalness() {
	// Default metalness is 0.0
	vec4 metalness = vec4(0,0,0,1);
	
	// Go through metalness brush texture to find brush centers that are close enough to current pixel
	// Then calculate metalness based on the combination of all those brush distances
	for (int y = 0; y < textureSize(tex_metalness_brush, 0).y; y++) 
	{
		for (int x = 0; x < textureSize(tex_metalness_brush, 0).x; x++) 
		{
			// Get brush pixel info
			vec4 brush_texel = texelFetch(tex_metalness_brush, ivec2(x, y), 0);
			// Increase size of brush so it can be possible to have a huge size brush for bucket fill
			float brush_size = brush_texel.a * 100.0;
			float dist = distance(vertex_pos.xyz, brush_texel.xyz);
			// If we reach the end of brush buffer, we stop the loop
			if (brush_size == 0.0)
				break;
			
			// Use last color of close enough brush for current pixel
			if (dist < brush_size) {
				vec4 color = texelFetch(tex_metalness_color, ivec2(x, y), 0);
				metalness = color;
			}
		}
	}
	return metalness;
}

// Emission retrieval
vec4 get_emission() {
	// Default emission is 0.0
	vec4 emission = vec4(0,0,0,0);
	
	// Go through metalness brush texture to find brush centers that are close enough to current pixel
	// Then calculate metalness based on the combination of all those brush distances
	for (int y = 0; y < textureSize(tex_emission_brush, 0).y; y++) 
	{
		for (int x = 0; x < textureSize(tex_emission_brush, 0).x; x++) 
		{
			// Get brush pixel info
			vec4 brush_texel = texelFetch(tex_emission_brush, ivec2(x, y), 0);
			// Increase size of brush so it can be possible to have a huge size brush for bucket fill
			float brush_size = brush_texel.a * 100.0;
			float dist = distance(vertex_pos.xyz, brush_texel.xyz);
			// If we reach the end of brush buffer, we stop the loop
			if (brush_size == 0.0)
				break;
			
			// Use last color of close enough brush for current pixel
			if (dist < brush_size) {
				vec4 color = texelFetch(tex_emission_color, ivec2(x, y), 0);
				emission = color;
			}
		}
	}
	return emission;
}

void fragment() {
	// Get albedo, roughness, metalness and emission from brush and color textures
	vec4 albedo = get_albedo();
	vec4 roughness = get_roughness();
	vec4 metalness = get_metalness();
	vec4 emission = get_emission();
	
	ALBEDO = albedo.rgb;
	ROUGHNESS = roughness.r; // r, g or b all have same value
	METALLIC = metalness.r; // r, g or b all have same value
	EMISSION = emission.rgb * emission.a; // rgb is color of emission, a is intensity
}









