// Spatial shader to paint albedo, roughness, metalness and emission unto mesh
// Brush textures hold brush sphere center positions and sizes (r: x, g: y, b:z, a: size)
// Color textures hold color of the texture to be used for that brush position

shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_back,diffuse_burley,specular_schlick_ggx;

uniform sampler2D tex_albedo_brush; // (r: x, g: y, b:z, a: size)
uniform sampler2D tex_albedo_color;
uniform sampler2D tex_albedo_layer_0;
uniform sampler2D tex_albedo_layer_1;
uniform sampler2D tex_albedo_layer_2;
uniform sampler2D tex_albedo_layer_3;

uniform sampler2D tex_roughness_brush; // (r: x, g: y, b:z, a: size)
uniform sampler2D tex_roughness_color; // r, g and b all at same value (0.0 - 1.0)
uniform sampler2D tex_roughness_layer_0;
uniform sampler2D tex_roughness_layer_1;
uniform sampler2D tex_roughness_layer_2;
uniform sampler2D tex_roughness_layer_3;

uniform sampler2D tex_metalness_brush; // (r: x, g: y, b:z, a: size)
uniform sampler2D tex_metalness_color; // r, g and b all at same value (0.0 - 1.0)
uniform sampler2D tex_metalness_layer_0;
uniform sampler2D tex_metalness_layer_1;
uniform sampler2D tex_metalness_layer_2;
uniform sampler2D tex_metalness_layer_3;

uniform sampler2D tex_emission_brush; // (r: x, g: y, b:z, a: size)
uniform sampler2D tex_emission_color; // rgb at same value (0.0 - 1.0) and a for intensity
uniform sampler2D tex_emission_layer_0;
uniform sampler2D tex_emission_layer_1;
uniform sampler2D tex_emission_layer_2;
uniform sampler2D tex_emission_layer_3;

uniform vec3 uv_scale = vec3(1.0,1.0,1.0);
uniform vec3 uv_offset = vec3(1.0,1.0,1.0);

varying vec3 vertex_pos;
varying vec3 triplanar_pos;
varying vec3 power_normal;

//void vertex() {
//	UV=UV*uv1_scale.xy+uv1_offset.xy;
//
//	// Keep vertex position to use in fragment()
//	vertex_pos = vec3(VERTEX.x, VERTEX.y, VERTEX.z);
//
//	// Prepare triplanar
//	uv1_power_normal=pow(abs(NORMAL),vec3(100));
//	uv1_power_normal/=dot(uv1_power_normal,vec3(1.0));
//	uv1_triplanar_pos = VERTEX * uv1_scale + uv1_offset;
//	uv1_triplanar_pos *= vec3(1.0,-1.0, 1.0);
//}
void vertex() {
	UV=UV*uv_scale.xy+uv_offset.xy;

	// Keep vertex position to use in fragment()
	vertex_pos = vec3(VERTEX.x, VERTEX.y, VERTEX.z);
	
	power_normal = pow(abs(NORMAL), vec3(10.0));
	power_normal = normalize(power_normal);
	
	triplanar_pos = VERTEX.xyz * vec3(1.0, -1.0, 1.0)  * uv_scale + uv_offset;
}

vec4 triplanar_texture(sampler2D p_sampler, vec3 p_weights,vec3 p_triplanar_pos) {
	vec4 samp=vec4(0.0);
	samp+= texture(p_sampler,p_triplanar_pos.xy) * p_weights.z;
	samp+= texture(p_sampler,p_triplanar_pos.xz) * p_weights.y;
	samp+= texture(p_sampler,p_triplanar_pos.zy * vec2(-1.0,1.0)) * p_weights.x;
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
			float brush_size = brush_texel.a;
			float dist = distance(vertex_pos.xyz, brush_texel.xyz);
			// If we reach the end of brush buffer, we stop the loop
			if (brush_size == 0.0)
				break;
			else if (brush_size == 1.0)
				brush_size *= 100.0;
			
			// Get color of close enough brush to mix paint the current pixel
			if (dist < brush_size) {
				vec4 color = texelFetch(tex_albedo_color, ivec2(x, y), 0);
				if (color.a == 0.0) {
					vec4 new_albedo;
					if (color.r == 0.0) {
						new_albedo = triplanar_texture(tex_albedo_layer_0,power_normal,triplanar_pos);
					}
					else if (color.r == 1.0) {
						new_albedo = triplanar_texture(tex_albedo_layer_1,power_normal,triplanar_pos);
					}
					else if (color.r == 2.0) {
						new_albedo = triplanar_texture(tex_albedo_layer_2,power_normal,triplanar_pos);
					}
					else if (color.r == 3.0) {
						new_albedo = triplanar_texture(tex_albedo_layer_3,power_normal,triplanar_pos);
					}
						
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
float get_roughness() {
	// Default roughness is 1.0
	float roughness = 1.0;
	
	// Go through roughness brush texture to find brush centers that are close enough to current pixel
	// Then calculate roughness based on the combination of all those brush distances
	for (int y = 0; y < textureSize(tex_roughness_brush, 0).y; y++) 
	{
		for (int x = 0; x < textureSize(tex_roughness_brush, 0).x; x++) 
		{
			// Get brush pixel info
			vec4 brush_texel = texelFetch(tex_roughness_brush, ivec2(x, y), 0);
			// Increase size of brush so it can be possible to have a huge size brush for bucket fill
			float brush_size = brush_texel.a;
			float dist = distance(vertex_pos.xyz, brush_texel.xyz);
			// If we reach the end of brush buffer, we stop the loop
			if (brush_size == 0.0)
				break;
			else if (brush_size == 1.0)
				brush_size *= 100.0;
			
			// Get color of close enough brush to mix paint the current pixel
			if (dist < brush_size) {
				vec4 color = texelFetch(tex_roughness_color, ivec2(x, y), 0);
				if (color.a == 0.0) {
					vec4 new_roughness;
					if (color.r == 0.0) {
						new_roughness = triplanar_texture(tex_roughness_layer_0,power_normal,triplanar_pos);
					}
					else if (color.r == 1.0) {
						new_roughness = triplanar_texture(tex_roughness_layer_1,power_normal,triplanar_pos);
					}
					else if (color.r == 2.0) {
						new_roughness = triplanar_texture(tex_roughness_layer_2,power_normal,triplanar_pos);
					}
					else if (color.r == 3.0) {
						new_roughness = triplanar_texture(tex_roughness_layer_3,power_normal,triplanar_pos);
					}
					roughness = clamp(roughness - color.g/10.0, 1.0-new_roughness.g, 1.0);
				}
				else if (color.a == 1.0) {
					roughness = clamp(roughness + .1, 0.0, 1.0);
				}
				else {
					roughness = clamp(roughness - color.a/10.0, 0.0, 1.0);
				}
			}
		}
	}
	return roughness;
}

// Metalness retrieval
float get_metalness() {
	// Default metalness is 0.0
	float metalness = 0.0;
	
	// Go through metalness brush texture to find brush centers that are close enough to current pixel
	// Then calculate metalness based on the combination of all those brush distances
	for (int y = 0; y < textureSize(tex_metalness_brush, 0).y; y++) 
	{
		for (int x = 0; x < textureSize(tex_metalness_brush, 0).x; x++) 
		{
			// Get brush pixel info
			vec4 brush_texel = texelFetch(tex_metalness_brush, ivec2(x, y), 0);
			// Increase size of brush so it can be possible to have a huge size brush for bucket fill
			float brush_size = brush_texel.a;
			float dist = distance(vertex_pos.xyz, brush_texel.xyz);
			// If we reach the end of brush buffer, we stop the loop
			if (brush_size == 0.0)
				break;
			else if (brush_size == 1.0)
				brush_size *= 100.0;
			
			// Use last color of close enough brush for current pixel
			if (dist < brush_size) {
				vec4 color = texelFetch(tex_metalness_color, ivec2(x, y), 0);
				if (color.a == 0.0) {
					vec4 new_metalness;
					if (color.r == 0.0) {
						new_metalness = triplanar_texture(tex_metalness_layer_0,power_normal,triplanar_pos);
					}
					else if (color.r == 1.0) {
						new_metalness = triplanar_texture(tex_metalness_layer_1,power_normal,triplanar_pos);
					}
					else if (color.r == 2.0) {
						new_metalness = triplanar_texture(tex_metalness_layer_2,power_normal,triplanar_pos);
					}
					else if (color.r == 3.0) {
						new_metalness = triplanar_texture(tex_metalness_layer_3,power_normal,triplanar_pos);
					}
					metalness = clamp(metalness + color.g/10.0, 0.0, new_metalness.g);
				}
				else if (color.a == 1.0) {
					metalness = clamp(metalness - .1, 0.0, 1.0);
				}
				else {
					metalness = clamp(metalness + color.a/10.0, 0.0, 1.0);
				}
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
			float brush_size = brush_texel.a;
			float dist = distance(vertex_pos.xyz, brush_texel.xyz);
			// If we reach the end of brush buffer, we stop the loop
			if (brush_size == 0.0)
				break;
			else if (brush_size == 1.0)
				brush_size *= 100.0;
			
			// Get color of close enough brush to mix paint the current pixel
			if (dist < brush_size) {
				vec4 color = texelFetch(tex_emission_color, ivec2(x, y), 0);
				if (color.a == 0.0) {
					vec4 new_emission;
					if (color.r == 0.0) {
						new_emission = triplanar_texture(tex_emission_layer_0,power_normal,triplanar_pos);
					}
					else if (color.r == 1.0) {
						new_emission = triplanar_texture(tex_emission_layer_1,power_normal,triplanar_pos);
					}
					else if (color.r == 2.0) {
						new_emission = triplanar_texture(tex_emission_layer_2,power_normal,triplanar_pos);
					}
					else if (color.r == 3.0) {
						new_emission = triplanar_texture(tex_emission_layer_3,power_normal,triplanar_pos);
					}
					emission = clamp(emission + color.g/10.0, 0.0, new_emission.g*5.0);
				}
				else if (color.a == 1.0) {
					emission.a = clamp(emission.a - .1, 0.0, 5.0);
				}
				else {
					emission.rgb = color.rgb;
					emission.a = clamp(emission.a + color.a, 0.0, 5.0);
				}
			}
		}
	}
	return emission;
}

void fragment() {
	// Get albedo, roughness, metalness and emission from brush and color textures
	vec4 albedo = get_albedo();
	float roughness = get_roughness();
	float metalness = get_metalness();
	vec4 emission = get_emission();
	
	ALBEDO = albedo.rgb;
	ROUGHNESS = roughness; // r, g or b all have same value
	METALLIC = metalness; // r, g or b all have same value
	EMISSION = emission.rgb * emission.a; // rgb is color of emission, a is intensity
}