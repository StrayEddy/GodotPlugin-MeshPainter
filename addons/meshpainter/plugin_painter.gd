tool
extends Node

class_name PluginPainter

var mesh :Mesh
var mdt :MeshDataTool = MeshDataTool.new()

func _ready():
	pass

func setup(mesh):
	self.mesh = mesh
	mdt.create_from_surface(mesh, 0)

func paint_uv(texture :ImageTexture, point, normal, color):
	
	var uv = get_uv_coords(point, normal)
	if uv == null:
		return
		
	var image = texture.get_data()
	image.lock()
	
	uv *= image.get_size()
	for x in range(-8, 9):
		for y in range(-8, 9):
			image.set_pixel(uv.x-x, uv.y-y, color)
	
	image.unlock()
	texture.set_data(image)

func equals_with_epsilon(v1, v2, epsilon):
	if (v1.distance_to(v2) < epsilon):
		return true
	return false

func get_face(point, normal, epsilon = 0.2):
	for idx in range(mdt.get_face_count()):
		if !equals_with_epsilon(mdt.get_face_normal(idx), normal, epsilon):
			continue
		# Normal is the same-ish, so we need to check if the point is on this face
		var v1 = mdt.get_vertex(mdt.get_face_vertex(idx, 0))
		var v2 = mdt.get_vertex(mdt.get_face_vertex(idx, 1))
		var v3 = mdt.get_vertex(mdt.get_face_vertex(idx, 2))
		if is_point_in_triangle(point, v1, v2, v3):
			return idx
	return null

func barycentric(P, A, B, C) -> Vector3:
	# Returns barycentric co-ordinates of point P in triangle ABC
	var v0 = B - A
	var v1 = C - A
	var v2 = P - A
	var d00 = v0.dot(v0)
	var d01 = v0.dot(v1)
	var d11 = v1.dot(v1)
	var d20 = v2.dot(v0)
	var d21 = v2.dot(v1)
	var denom = d00 * d11 - d01 * d01
	var v = (d11 * d20 - d01 * d21) / denom
	var w = (d00 * d21 - d01 * d20) / denom
	var u = 1.0 - v - w
	return Vector3(u, v, w)

func is_point_in_triangle(point, v1, v2, v3):
	var bc = barycentric(point, v1, v2, v3)
	if bc.x < 0 or bc.x > 1:
		return false
	if bc.y < 0 or bc.y > 1:
		return false
	if bc.z < 0 or bc.z > 1:
		return false
	return true

func get_uv_coords(point, normal):
	# Gets the uv coordinates on the mesh given a point on the mesh and normal
	# these values can be obtained from a raycast
	var face = get_face(point, normal)
	if face == null:
		return null
	var v1 = mdt.get_vertex(mdt.get_face_vertex(face, 0))
	var v2 = mdt.get_vertex(mdt.get_face_vertex(face, 1))
	var v3 = mdt.get_vertex(mdt.get_face_vertex(face, 2))
	var bc = barycentric(point, v1, v2, v3)
	var uv1 = mdt.get_vertex_uv(mdt.get_face_vertex(face, 0))
	var uv2 = mdt.get_vertex_uv(mdt.get_face_vertex(face, 1))
	var uv3 = mdt.get_vertex_uv(mdt.get_face_vertex(face, 2))
	return (uv1 * bc.x) + (uv2 * bc.y) + (uv3 * bc.z)
