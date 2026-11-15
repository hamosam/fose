import random
import math

class Color:
    def __init__(self, r, g, b, a=1.0):
        self.r = r
        self.g = g
        self.b = b
        self.a = a
    def __getitem__(self, idx):
        return [self.r, self.g, self.b, self.a][idx]

def build_scene():
    random.seed(42)

    ext_resources = [
        ('ground_shader', 'res://grass_ground.gdshader', 'Shader'),
        ('brick_shader', 'res://brick_wall.gdshader', 'Shader'),
        ('player', 'res://player.tscn', 'PackedScene'),
        ('monster', 'res://monster.tscn', 'PackedScene'),
        ('note', 'res://note.tscn', 'PackedScene'),
        ('game_manager', 'res://game_manager.gd', 'Script'),
        ('flicker', 'res://flicker_light.gd', 'Script'),
        ('crypt', 'res://models/spooky/gltf/crypt.gltf', 'PackedScene'),
        ('arch_gate', 'res://models/spooky/gltf/arch_gate.gltf', 'PackedScene'),
        ('shrine_candles', 'res://models/spooky/gltf/shrine_candles.gltf', 'PackedScene'),
        ('shrine', 'res://models/spooky/gltf/shrine.gltf', 'PackedScene'),
        ('tree_large', 'res://models/spooky/gltf/tree_dead_large.gltf', 'PackedScene'),
        ('tree_med', 'res://models/spooky/gltf/tree_dead_medium.gltf', 'PackedScene'),
        ('tree_small', 'res://models/spooky/gltf/tree_dead_small.gltf', 'PackedScene'),
        ('pine_large', 'res://models/spooky/gltf/tree_pine_yellow_large.gltf', 'PackedScene'),
        ('pine_med', 'res://models/spooky/gltf/tree_pine_orange_medium.gltf', 'PackedScene'),
        ('fence', 'res://models/spooky/gltf/fence.gltf', 'PackedScene'),
        ('fence_broken', 'res://models/spooky/gltf/fence_broken.gltf', 'PackedScene'),
        ('fence_gate', 'res://models/spooky/gltf/fence_gate.gltf', 'PackedScene'),
        ('gravestone', 'res://models/spooky/gltf/gravestone.gltf', 'PackedScene'),
        ('grave_A', 'res://models/spooky/gltf/grave_A.gltf', 'PackedScene'),
        ('grave_dest', 'res://models/spooky/gltf/grave_A_destroyed.gltf', 'PackedScene'),
        ('coffin', 'res://models/spooky/gltf/coffin.gltf', 'PackedScene'),
        ('skull_candle', 'res://models/spooky/gltf/skull_candle.gltf', 'PackedScene'),
        ('jack', 'res://models/spooky/gltf/pumpkin_orange_jackolantern.gltf', 'PackedScene'),
        ('post_lantern', 'res://models/spooky/gltf/post_lantern.gltf', 'PackedScene'),
        ('bench', 'res://models/spooky/gltf/bench_decorated.gltf', 'PackedScene'),
        ('path', 'res://models/spooky/gltf/path_A.gltf', 'PackedScene'),
        ('ribcage', 'res://models/spooky/gltf/ribcage.gltf', 'PackedScene'),
        ('skull', 'res://models/spooky/gltf/skull.gltf', 'PackedScene'),
        ('bone', 'res://models/spooky/gltf/bone_A.gltf', 'PackedScene'),
    ]

    out = []
    out.append('[gd_scene load_steps=%d format=3 uid="uid://b2x7d1k9y5q4e"]\n' % (len(ext_resources) + 4))

    for rid, path, rtype in ext_resources:
        if rid == 'player':
            out.append('[ext_resource type="%s" uid="uid://c8vj7q6x1u4a2" path="%s" id="%s"]' % (rtype, path, rid))
        else:
            out.append('[ext_resource type="%s" path="%s" id="%s"]' % (rtype, path, rid))
    out.append('')

    # Sub-resources
    out.append('''[sub_resource type="Environment" id="Environment_horror"]
background_mode = 1
background_color = Color(0.012, 0.015, 0.02, 1)
ambient_light_source = 2
ambient_light_color = Color(0.06, 0.08, 0.12, 1)
ambient_light_energy = 0.45
tonemap_mode = 2
glow_enabled = true
glow_intensity = 0.8
fog_enabled = true
fog_light_color = Color(0.05, 0.07, 0.1, 1)
fog_light_energy = 0.7
fog_density = 0.018

[sub_resource type="ShaderMaterial" id="ShaderMaterial_ground"]
render_priority = 0
shader = ExtResource("ground_shader")
shader_parameter/grass_color_dark = Color(0.08, 0.16, 0.08, 1)
shader_parameter/grass_color_mid = Color(0.12, 0.22, 0.10, 1)
shader_parameter/grass_color_dry = Color(0.16, 0.18, 0.11, 1)
shader_parameter/soil_color = Color(0.10, 0.08, 0.07, 1)
shader_parameter/roughness = 0.88

[sub_resource type="ShaderMaterial" id="ShaderMaterial_brick_wall"]
render_priority = 0
shader = ExtResource("brick_shader")
shader_parameter/brick_color = Color(0.38, 0.20, 0.17, 1)
shader_parameter/brick_color_alt = Color(0.26, 0.14, 0.12, 1)
shader_parameter/mortar_color = Color(0.12, 0.12, 0.13, 1)
shader_parameter/brick_size = Vector2(0.5, 0.22)
shader_parameter/mortar_size = 0.025
shader_parameter/roughness = 0.88
''')

    # Root Node
    out.append('[node name="Main" type="Node3D"]')
    out.append('')
    out.append('[node name="GameManager" type="Node" parent="."]')
    out.append('script = ExtResource("game_manager")\n')

    out.append('[node name="WorldEnvironment" type="WorldEnvironment" parent="."]')
    out.append('environment = SubResource("Environment_horror")\n')
    out.append('[node name="Moonlight" type="DirectionalLight3D" parent="."]')
    out.append('transform = Transform3D(0.866025, -0.353553, 0.353553, 0, 0.707107, 0.707107, -0.5, -0.612372, 0.612372, 0, 30, 0)')
    out.append('light_color = Color(0.4, 0.5, 0.7, 1)')
    out.append('light_energy = 0.38')
    out.append('shadow_enabled = true')
    out.append('directional_shadow_max_distance = 65.0\n')

    # Floor (Grass Material)
    out.append('[node name="Floor" type="CSGBox3D" parent="."]')
    out.append('transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, -0.5, 0)')
    out.append('use_collision = true')
    out.append('collision_mask = 0')
    out.append('size = Vector3(90, 1, 90)')
    out.append('material = SubResource("ShaderMaterial_ground")\n')

    # Player
    out.append('[node name="Player" parent="." instance=ExtResource("player")]')
    out.append('transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 18)\n')

    # Monster (Cute Monster)
    out.append('[node name="Monster" parent="." instance=ExtResource("monster")]')
    out.append('transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, -12)\n')

    # Outer Walls (Brick Wall Material)
    out.append('[node name="OuterWalls" type="Node3D" parent="."]')
    walls = [
        ('WallN', '0, 3, -42', '86, 6, 2'),
        ('WallS', '0, 3, 42', '86, 6, 2'),
        ('WallW', '-42, 3, 0', '2, 6, 86'),
        ('WallE', '42, 3, 0', '2, 6, 86'),
    ]
    for wname, pos, size in walls:
        out.append('[node name="%s" type="CSGBox3D" parent="OuterWalls"]' % wname)
        out.append('transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %s)' % pos)
        out.append('use_collision = true')
        out.append('collision_mask = 0')
        out.append('size = Vector3(%s)' % size)
        out.append('material = SubResource("ShaderMaterial_brick_wall")\n')

    def make_transform(x, y, z, yaw_deg=0.0, sx=1.0, sy=1.0, sz=1.0):
        rad = math.radians(yaw_deg)
        c = math.cos(rad)
        s = math.sin(rad)
        return 'Transform3D(%g, 0, %g, 0, %g, 0, %g, 0, %g, %g, %g, %g)' % (
            c * sx, s * sx, sy, -s * sz, c * sz, x, y, z
        )

    # 10 Slender-style Notes
    out.append('[node name="Notes" type="Node3D" parent="."]')
    note_data = [
        (1, 3.2, 0.4, 10.0, 15, "DONT LOOK BEHIND"),
        (2, -2.2, 0.4, 2.0, -20, "HE IS WATCHING"),
        (3, -10.0, 0.5, -6.0, 45, "HELP ME"),
        (4, -22.0, 0.4, -14.0, -90, "ITS TOO LATE"),
        (5, -25.0, 0.6, 2.0, 30, "LEAVE NOW"),
        (6, -2.2, 0.8, -21.0, 0, "NO ESCAPE"),
        (7, 24.0, 0.7, -24.0, -45, "BEHIND YOU"),
        (8, 16.0, 0.6, -10.0, 90, "HE CAN HEAR YOU"),
        (9, 11.5, 0.4, -2.0, 0, "RUN"),
        (10, 16.0, 0.4, 26.0, 120, "CUTE BUT DEADLY"),
    ]
    for nid, nx, ny, nz, nry, ntext in note_data:
        out.append('[node name="Note_%d" parent="Notes" instance=ExtResource("note")]' % nid)
        out.append('transform = %s' % make_transform(nx, ny, nz, nry))
        out.append('note_id = %d' % nid)
        out.append('note_text = "%s"\n' % ntext)

    # Pathways
    out.append('[node name="Pathways" type="Node3D" parent="."]')
    path_points = [
        (0, 16), (0, 12), (0, 8), (0, 4), (0, 0), (0, -4), (0, -8), (0, -12), (0, -16), (0, -20),
        (-4, 0), (-8, 0), (-12, 0), (-16, 0), (-20, 0), (-20, -4), (-20, -8), (-20, -12),
        (4, 4), (8, 4), (12, 4), (16, 4), (16, 0), (16, -4), (16, -8), (20, -8), (24, -8),
        (-4, 16), (-8, 18), (-12, 22), (-16, 26),
        (4, 16), (8, 20), (12, 24), (16, 28)
    ]
    for idx, (px, pz) in enumerate(path_points):
        out.append('[node name="Path_%d" parent="Pathways" instance=ExtResource("path")]' % idx)
        out.append('transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %g, 0, %g)\n' % (px, pz))

    # Buildings (Crypts & Brick Walls)
    out.append('[node name="Buildings" type="Node3D" parent="."]')
    
    out.append('[node name="Crypt_Main" parent="Buildings" instance=ExtResource("crypt")]')
    out.append('transform = %s\n' % make_transform(0, 0, -28, 0, 1.3, 1.3, 1.3))
    out.append('[node name="Crypt_Main_Col" type="CSGBox3D" parent="Buildings"]')
    out.append('transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 4, -28)')
    out.append('use_collision = true\ncollision_mask = 0\nsize = Vector3(8, 8, 10.5)\nvisible = false\n')

    out.append('[node name="Arch_Main" parent="Buildings" instance=ExtResource("arch_gate")]')
    out.append('transform = %s\n' % make_transform(0, 0, -21, 0))

    out.append('[node name="Crypt_Main_Light" type="OmniLight3D" parent="Buildings"]')
    out.append('transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 3, -24)')
    out.append('light_color = Color(1, 0.2, 0.08, 1)\nlight_energy = 2.8\nshadow_enabled = true\nomni_range = 16.0\nscript = ExtResource("flicker")\n')

    out.append('[node name="Crypt_East" parent="Buildings" instance=ExtResource("crypt")]')
    out.append('transform = %s\n' % make_transform(26, 0, -26, -45, 1.1, 1.1, 1.1))
    out.append('[node name="Crypt_East_Col" type="CSGBox3D" parent="Buildings"]')
    out.append('transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 26, 4, -26)')
    out.append('use_collision = true\ncollision_mask = 0\nsize = Vector3(7, 7, 9)\nvisible = false\n')

    out.append('[node name="Crypt_SouthEast" parent="Buildings" instance=ExtResource("crypt")]')
    out.append('transform = %s\n' % make_transform(28, 0, 16, -135, 1.0, 1.0, 1.0))
    out.append('[node name="Crypt_SouthEast_Col" type="CSGBox3D" parent="Buildings"]')
    out.append('transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 28, 4, 16)')
    out.append('use_collision = true\ncollision_mask = 0\nsize = Vector3(6.5, 7, 8.5)\nvisible = false\n')

    alley_walls = [
        ('Wall_A1', '10, 2.5, -4', '1, 5, 22'),
        ('Wall_A2', '18, 2.5, -12', '1, 5, 18'),
        ('Wall_A3', '24, 2.5, -4', '14, 5, 1'),
        ('Wall_A4', '32, 2.5, -14', '1, 5, 20'),
        ('Wall_A5', '20, 2.5, 6', '16, 5, 1'),
        ('Wall_A6', '14, 2.5, 14', '1, 5, 16'),
        ('Wall_A7', '22, 2.5, 24', '1, 5, 14'),
        ('Wall_A8', '34, 2.5, 6', '1, 5, 24'),
        ('Wall_Cross1', '28, 2.5, -18', '10, 5, 1'),
        ('Wall_Cross2', '14, 2.5, -20', '8, 5, 1'),
        ('Wall_Cross3', '8, 2.5, 12', '6, 5, 1'),
        ('Wall_Cross4', '6, 2.5, -22', '1, 5, 8'),
    ]
    for wname, pos, size in alley_walls:
        out.append('[node name="%s" type="CSGBox3D" parent="Buildings"]' % wname)
        out.append('transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %s)' % pos)
        out.append('use_collision = true\ncollision_mask = 0\nsize = Vector3(%s)\nmaterial = SubResource("ShaderMaterial_brick_wall")\n' % size)

    alley_props = [
        ('shrine', 14, 0, -8, 90),
        ('shrine_candles', 24, 0, -12, 0),
        ('bench', 11.5, 0, -2, 90),
        ('bench', 25, 0, 4, 180),
        ('jack', 11, 0, 5, 45),
        ('jack', 17, 0, -6, -30),
        ('jack', 30, 0, -10, 120),
        ('jack', 23, 0, 10, -80),
        ('post_lantern', 11, 0, 2, 0),
        ('post_lantern', 19, 0, -2, 0),
        ('post_lantern', 27, 0, -8, 0),
        ('post_lantern', 15, 0, 20, 0),
    ]
    for idx, (res_id, px, py, pz, ry) in enumerate(alley_props):
        out.append('[node name="AlleyProp_%d" parent="Buildings" instance=ExtResource("%s")]' % (idx, res_id))
        out.append('transform = %s\n' % make_transform(px, py, pz, ry))

    alley_lights = [
        (11, 2.8, 2, Color(1, 0.7, 0.35)),
        (19, 2.8, -2, Color(1, 0.15, 0.08)),
        (27, 2.8, -8, Color(1, 0.75, 0.4)),
        (15, 2.8, 20, Color(1, 0.65, 0.3)),
    ]
    for idx, (lx, ly, lz, col) in enumerate(alley_lights):
        out.append('[node name="AlleyLight_%d" type="OmniLight3D" parent="Buildings"]' % idx)
        out.append('transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %g, %g, %g)' % (lx, ly, lz))
        out.append('light_color = Color(%g, %g, %g, 1)\nlight_energy = 1.8\nomni_range = 10.0\nscript = ExtResource("flicker")\n' % (col[0], col[1], col[2]))

    # Graveyard Zone
    out.append('[node name="Graveyard" type="Node3D" parent="."]')
    fences = [
        ('fence', -8, 0, -22, 0), ('fence_broken', -12, 0, -22, 0),
        ('fence', -16, 0, -22, 0), ('fence', -20, 0, -22, 0),
        ('fence_broken', -24, 0, -22, 0), ('fence', -28, 0, -22, 0),
        ('fence', -6, 0, -18, 90), ('fence_gate', -6, 0, -14, 90),
        ('fence', -6, 0, -10, 90), ('fence_broken', -6, 0, -6, 90),
        ('fence', -6, 0, -2, 90), ('fence_gate', -6, 0, 2, 90),
        ('fence', -6, 0, 6, 90), ('fence_broken', -6, 0, 10, 90),
        ('fence', -8, 0, 12, 0), ('fence_broken', -12, 0, 12, 0),
        ('fence', -16, 0, 12, 0), ('fence', -20, 0, 12, 0),
        ('fence_broken', -24, 0, 12, 0), ('fence', -28, 0, 12, 0),
        ('fence', -18, 0, -14, 90), ('fence_broken', -18, 0, -10, 90),
        ('fence', -18, 0, 0, 90), ('fence_broken', -18, 0, 4, 90),
        ('fence', -24, 0, -6, 0), ('fence_broken', -28, 0, -6, 0),
    ]
    for idx, (res_id, fx, fy, fz, fry) in enumerate(fences):
        out.append('[node name="GraveFence_%d" parent="Graveyard" instance=ExtResource("%s")]' % (idx, res_id))
        out.append('transform = %s\n' % make_transform(fx, fy, fz, fry))

    grave_items = [
        ('grave_A', -10, -18), ('gravestone', -14, -18), ('grave_dest', -18, -18), ('grave_A', -22, -18), ('gravestone', -26, -18), ('grave_dest', -30, -18),
        ('gravestone', -10, -14), ('grave_A', -14, -14), ('coffin', -22, -14), ('grave_A', -26, -14), ('gravestone', -30, -14),
        ('grave_dest', -10, -10), ('coffin', -14, -10), ('gravestone', -22, -10), ('grave_A', -26, -10), ('grave_dest', -30, -10),
        ('grave_A', -10, -6), ('gravestone', -14, -6), ('grave_A', -22, -6), ('grave_dest', -26, -6), ('coffin', -30, -6),
        ('gravestone', -10, -2), ('grave_dest', -14, -2), ('gravestone', -22, -2), ('grave_A', -26, -2), ('gravestone', -30, -2),
        ('grave_A', -10, 2), ('coffin', -14, 2), ('grave_dest', -22, 2), ('gravestone', -26, 2), ('grave_A', -30, 2),
        ('gravestone', -10, 6), ('grave_A', -14, 6), ('grave_A', -22, 6), ('coffin', -26, 6), ('grave_dest', -30, 6),
        ('grave_dest', -10, 10), ('gravestone', -14, 10), ('gravestone', -22, 10), ('grave_A', -26, 10), ('gravestone', -30, 10),
    ]
    for idx, (res_id, gx, gz) in enumerate(grave_items):
        yaw = random.uniform(-25, 25)
        out.append('[node name="GraveItem_%d" parent="Graveyard" instance=ExtResource("%s")]' % (idx, res_id))
        out.append('transform = %s\n' % make_transform(gx + random.uniform(-0.5, 0.5), 0, gz + random.uniform(-0.5, 0.5), yaw))

    decorations = [
        ('shrine_candles', -12, -8, 45),
        ('shrine_candles', -25, 2, -45),
        ('skull_candle', -15, -4, 0),
        ('skull_candle', -23, -12, 0),
        ('skull_candle', -28, 5, 0),
        ('ribcage', -13, 0, 20),
        ('skull', -21, -13, 110),
        ('bone', -16, 5, -40),
        ('jack', -12, 11, 20),
        ('jack', -26, -16, -60),
    ]
    for idx, (res_id, dx, dz, dry) in enumerate(decorations):
        out.append('[node name="GraveDeco_%d" parent="Graveyard" instance=ExtResource("%s")]' % (idx, res_id))
        out.append('transform = %s\n' % make_transform(dx, 0, dz, dry))

    grave_lights = [
        (-12, 2.0, -8, Color(1, 0.6, 0.2)),
        (-25, 2.0, 2, Color(1, 0.55, 0.15)),
        (-18, 3.0, -2, Color(1, 0.75, 0.35)),
    ]
    for idx, (lx, ly, lz, col) in enumerate(grave_lights):
        out.append('[node name="GraveLight_%d" type="OmniLight3D" parent="Graveyard"]' % idx)
        out.append('transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %g, %g, %g)' % (lx, ly, lz))
        out.append('light_color = Color(%g, %g, %g, 1)\nlight_energy = 1.6\nomni_range = 10.0\nscript = ExtResource("flicker")\n' % (col[0], col[1], col[2]))

    # Forest Zone
    out.append('[node name="Forest" type="Node3D" parent="."]')
    tree_types = ['tree_large', 'tree_med', 'tree_small', 'pine_large', 'pine_med']

    def is_reserved(x, z):
        if abs(x) <= 3 and -24 <= z <= 20:
            return True
        if abs(x) <= 6 and -34 <= z <= -22:
            return True
        if 20 <= x <= 32 and -32 <= z <= -20:
            return True
        if 22 <= x <= 34 and 10 <= z <= 22:
            return True
        if -32 <= x <= -8 and -20 <= z <= 10:
            return True
        if 8 <= x <= 36 and -16 <= z <= 4:
            return True
        return False

    tree_count = 0
    for gx in range(-36, 38, 4):
        for gz in range(-36, 38, 4):
            if is_reserved(gx, gz):
                continue
            if random.random() < 0.72:
                tx = gx + random.uniform(-1.2, 1.2)
                tz = gz + random.uniform(-1.2, 1.2)
                res_id = random.choice(tree_types)
                scale = random.uniform(0.85, 1.3)
                yaw = random.uniform(0, 360)
                
                out.append('[node name="Tree_%d" parent="Forest" instance=ExtResource("%s")]' % (tree_count, res_id))
                out.append('transform = %s\n' % make_transform(tx, 0, tz, yaw, scale, scale, scale))
                tree_count += 1
                
                if random.random() < 0.15:
                    deco_id = random.choice(['jack', 'skull', 'ribcage', 'skull_candle'])
                    out.append('[node name="ForestDeco_%d" parent="Forest" instance=ExtResource("%s")]' % (tree_count, deco_id))
                    out.append('transform = %s\n' % make_transform(tx + 0.8, 0, tz + 0.8, yaw + 45))

    forest_lanterns = [
        (-2.5, 0, 10), (2.5, 0, -6), (-2.5, 0, -16),
        (-10, 0, 22), (10, 0, 24), (-22, 0, 24),
    ]
    for idx, (flx, fly, flz) in enumerate(forest_lanterns):
        out.append('[node name="ForestLantern_%d" parent="Forest" instance=ExtResource("post_lantern")]' % idx)
        out.append('transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %g, %g, %g)\n' % (flx, fly, flz))
        out.append('[node name="ForestLanternLight_%d" type="OmniLight3D" parent="Forest"]' % idx)
        out.append('transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %g, 2.8, %g)' % (flx, flz))
        out.append('light_color = Color(1, 0.75, 0.45, 1)\nlight_energy = 1.5\nomni_range = 9.0\nscript = ExtResource("flicker")\n')

    # HUD (Slender-man style note counter, static overlay, game over / win popup)
    out.append('''[node name="HUD" type="CanvasLayer" parent="."]

[node name="NoteCountPanel" type="PanelContainer" parent="HUD"]
anchors_preset = 0
offset_left = 24.0
offset_top = 24.0
offset_right = 160.0
offset_bottom = 68.0

[node name="MarginContainer" type="MarginContainer" parent="HUD/NoteCountPanel"]
layout_mode = 2
theme_override_constants/margin_left = 14
theme_override_constants/margin_top = 6
theme_override_constants/margin_right = 14
theme_override_constants/margin_bottom = 6

[node name="NoteLabel" type="Label" parent="HUD/NoteCountPanel/MarginContainer"]
layout_mode = 2
theme_override_font_sizes/font_size = 20
text = "쪽지: 0 / 10"
vertical_alignment = 1

[node name="MessageLabel" type="Label" parent="HUD"]
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -300.0
offset_top = -120.0
offset_right = 300.0
offset_bottom = -70.0
grow_horizontal = 2
grow_vertical = 2
theme_override_font_sizes/font_size = 26
horizontal_alignment = 1
vertical_alignment = 1

[node name="StaticOverlay" type="ColorRect" parent="HUD"]
visible = false
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2
color = Color(0.85, 0.1, 0.1, 0.35)

[node name="GameOverPanel" type="PanelContainer" parent="HUD"]
visible = false
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -260.0
offset_top = -100.0
offset_right = 260.0
offset_bottom = 100.0
grow_horizontal = 2
grow_vertical = 2

[node name="Margin" type="MarginContainer" parent="HUD/GameOverPanel"]
layout_mode = 2
theme_override_constants/margin_left = 24
theme_override_constants/margin_top = 20
theme_override_constants/margin_right = 24
theme_override_constants/margin_bottom = 20

[node name="VBox" type="VBoxContainer" parent="HUD/GameOverPanel/Margin"]
layout_mode = 2
theme_override_constants/separation = 16
alignment = 1

[node name="TitleLabel" type="Label" parent="HUD/GameOverPanel/Margin/VBox"]
layout_mode = 2
theme_override_font_sizes/font_size = 24
text = "잡혔습니다!"
horizontal_alignment = 1

[node name="SubLabel" type="Label" parent="HUD/GameOverPanel/Margin/VBox"]
layout_mode = 2
theme_override_font_sizes/font_size = 18
text = "[R] 키를 눌러 다시 도전하세요"
horizontal_alignment = 1

[node name="HelpPanel" type="PanelContainer" parent="HUD"]
anchors_preset = 7
anchor_left = 0.5
anchor_top = 1.0
anchor_right = 0.5
anchor_bottom = 1.0
offset_left = -380.0
offset_top = -65.0
offset_right = 380.0
offset_bottom = -15.0
grow_horizontal = 2
grow_vertical = 0

[node name="MarginContainer" type="MarginContainer" parent="HUD/HelpPanel"]
layout_mode = 2
theme_override_constants/margin_left = 16
theme_override_constants/margin_top = 8
theme_override_constants/margin_right = 16
theme_override_constants/margin_bottom = 8

[node name="Label" type="Label" parent="HUD/HelpPanel/MarginContainer"]
layout_mode = 2
text = "WASD: 이동 | Shift: 달리기 | E: 쪽지 줍기 | F: 손전등 | 마우스: 시점 | ESC: 커서"
horizontal_alignment = 1
vertical_alignment = 1
''')

    content = '\n'.join(out)
    with open('main.tscn', 'w', encoding='utf-8') as f:
        f.write(content)
    print(f'Successfully built full game main.tscn with monster and 10 notes!')

if __name__ == '__main__':
    build_scene()
