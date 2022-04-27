// leaves is a 3d visualisation of leaves climbing an object.

const std = @import("std");
const c = @import("c.zig");
const constants = @import("constants.zig");

const glyph_lib = @import("glyphee.zig");
const TypeSetter = glyph_lib.TypeSetter;

const vines_lib = @import("vines.zig");
const Vines = vines_lib.Vines;

const helpers = @import("helpers.zig");
const Vector2 = helpers.Vector2;
const Vector2_gl = helpers.Vector2_gl;
const Vector3_gl = helpers.Vector3_gl;
const Matrix3_gl = helpers.Matrix3_gl;
const Camera2D = helpers.Camera2D;
const Camera3D = helpers.Camera3D;
const SingleInput = helpers.SingleInput;
const MouseState = helpers.MouseState;
const EditableText = helpers.EditableText;
const Mesh = helpers.Mesh;
const MarchedCube = helpers.MarchedCube;
const TYPING_BUFFER_SIZE = 16;
const glf = c.GLfloat;

const InputKey = enum {
    shift,
    tab,
    enter,
    space,
    escape,
    ctrl,
};
const INPUT_KEYS_COUNT = @typeInfo(InputKey).Enum.fields.len;
const InputMap = struct {
    key: c.SDL_Keycode,
    input: InputKey,
};

const INPUT_MAPPING = [_]InputMap{
    .{ .key = c.SDLK_LSHIFT, .input = .shift },
    .{ .key = c.SDLK_LCTRL, .input = .ctrl },
    .{ .key = c.SDLK_TAB, .input = .tab },
    .{ .key = c.SDLK_RETURN, .input = .enter },
    .{ .key = c.SDLK_SPACE, .input = .space },
    .{ .key = c.SDLK_ESCAPE, .input = .escape },
};
const min = std.math.min;
const max = std.math.max;

pub const InputState = struct {
    const Self = @This();
    keys: [INPUT_KEYS_COUNT]SingleInput = [_]SingleInput{.{}} ** INPUT_KEYS_COUNT,
    mouse: MouseState = MouseState{},
    typed: [TYPING_BUFFER_SIZE]u8 = [_]u8{0} ** TYPING_BUFFER_SIZE,
    num_typed: usize = 0,

    pub fn get_key(self: *Self, key: InputKey) *SingleInput {
        return &self.keys[@enumToInt(key)];
    }

    pub fn type_key(self: *Self, k: u8) void {
        if (self.num_typed >= TYPING_BUFFER_SIZE) {
            std.debug.print("Typing buffer already filled.\n", .{});
            return;
        }
        self.typed[self.num_typed] = k;
        self.num_typed += 1;
    }

    pub fn reset(self: *Self) void {
        for (self.keys) |*key| key.reset();
        self.mouse.reset_mouse();
        self.num_typed = 0;
    }
};

pub fn smooth_sub(d1: glf, d2: glf, k: glf) glf {
    // float opSmoothSubtraction( float d1, float d2, float k ) {
    // float h = clamp( 0.5 - 0.5*(d2+d1)/k, 0.0, 1.0 );
    // return mix( d2, -d1, h ) + k*h*(1.0-h); }
    const h = std.math.clamp(0.5 - 0.5 * (d2 + d1) / k, 0.0, 1.0);
    return helpers.lerpf(d2, -d1, h) + k * h * (1.0 - h);
}

pub fn sdf_default_cube(point: Vector3_gl) glf {
    const size = Vector3_gl{ .x = 0.5, .y = 0.5, .z = 0.5 };
    // https://iquilezles.org/articles/distfunctions/
    // vec3 q = abs(p) - b;
    // return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0)
    const q = (point.absed()).subtracted(size);
    return q.maxed(0.0).length() + min(max(q.x, max(q.y, q.z)), 0.0);
}

pub fn sdf_default_sphere(point: Vector3_gl) glf {
    return point.length() - 0.5;
}

pub fn sdf_cylinder(point: Vector3_gl, height: glf, radius: glf) glf {
    // float sdCappedCylinder( vec3 p, float h, float r )
    // {
    //   vec2 d = abs(vec2(length(p.xz),p.y)) - vec2(h,r); <- had to change this
    //   return min(max(d.x,d.y),0.0) + length(max(d,0.0));
    // }
    const temp = Vector2_gl{ .x = Vector2_gl.length(.{ .x = point.x, .y = point.z }), .y = point.y };
    const d = temp.absed().subtracted(.{ .x = radius, .y = height });
    return min(max(d.x, d.y), 0.0) + d.maxed(0.0).lengthed();
}

pub fn my_sdf(point: Vector3_gl) glf {
    var d = sdf_default_cube(point);
    var d2 = sdf_cylinder(point.rotated_about_point_axis(.{}, .{ .x = 1 }, std.math.pi / 2.0), 3.13, 0.125);
    if (false) return smooth_sub(d2, d, 0.1);
    return d;
}

pub const App = struct {
    const Self = @This();
    typesetter: TypeSetter = undefined,
    cam2d: Camera2D = .{},
    cam3d: Camera3D,
    allocator: std.mem.Allocator,
    arena: std.mem.Allocator,
    ticks: u32 = 0,
    quit: bool = false,
    cube: Mesh,
    inputs: InputState = .{},
    vines: Vines,
    debug: c.GLint = 0,

    pub fn new(allocator: std.mem.Allocator, arena: std.mem.Allocator) Self {
        return Self{
            .allocator = allocator,
            .arena = arena,
            .cube = Mesh.init(allocator),
            .vines = Vines.init(allocator, arena),
            .cam3d = Camera3D.new(),
        };
    }

    pub fn init(self: *Self) !void {
        try self.typesetter.init(&self.cam2d, self.allocator);
        self.cube.generate_from_sdf(my_sdf, .{}, .{ .x = 1.5, .y = 1.5, .z = 1.5 }, 1.5 / 20.0, self.arena);
        if (true) {
            // cube
            {
                const point = Vector3_gl{ .z = -0.5, .y = 0.5, .x = -0.3 };
                const dir = Vector3_gl{ .x = 1.0, .y = -1.2 };
                const axis = Vector3_gl{ .y = 1.0 };
                self.vines.grow(point, dir.normalized(), my_sdf, axis, true);
            }
            if (false) {
                const point = Vector3_gl{ .x = -0.5, .y = 0.5, .z = -0.3 };
                const dir = Vector3_gl{ .z = 1.0, .y = -0.1 };
                const axis = Vector3_gl{ .y = 1.0 };
                self.vines.grow(point, dir.normalized(), sdf_default_cube, axis, false);
            }
        }
        if (false) {
            {
                const point = Vector3_gl{ .x = 0.0, .y = 0.5, .z = 0.0 };
                const dir = Vector3_gl{ .x = 1.0, .y = -0.2 };
                const axis = Vector3_gl{ .y = 1.0 };
                self.vines.grow(point, dir.normalized(), sdf_default_sphere, axis, false);
            }
            // {
            //     const point = Vector3_gl{ .x = 0.0, .y = 0.5, .z = 0.0 };
            //     const dir = Vector3_gl{ .z = -1.0, .y = -0.1 };
            //     const axis = Vector3_gl{ .x = 1.0 };
            //     self.vines.grow(point, dir.normalized(), sdf_default_sphere, axis, true);
            // }
            if (false) {
                self.cube.generate_from_sdf(sdf_default_sphere, .{}, .{ .x = 1.5, .y = 1.5, .z = 1.5 }, 1.5 / 90.0, self.arena);
                self.cube.align_normals(sdf_default_sphere);
            }
            if (false) {
                const verts = [8]bool{
                    //true, true, true, false, false, false, false, false,
                    true, true, true, false, true, false, false, false,
                };
                const pos = [8]Vector3_gl{
                    .{ .x = -0.5, .y = -0.5, .z = -0.5 },
                    .{ .x = -0.5, .y = 0.5, .z = -0.5 },
                    .{ .x = 0.5, .y = 0.5, .z = -0.5 },
                    .{ .x = 0.5, .y = -0.5, .z = -0.5 },
                    .{ .x = -0.5, .y = -0.5, .z = 0.5 },
                    .{ .x = -0.5, .y = 0.5, .z = 0.5 },
                    .{ .x = 0.5, .y = 0.5, .z = 0.5 },
                    .{ .x = 0.5, .y = -0.5, .z = 0.5 },
                };
                for (verts) |v, i| {
                    if (v) {
                        const p = pos[i];
                        var cube = Mesh.unit_cube(self.arena);
                        defer cube.deinit();
                        cube.set_position(p);
                        cube.set_scalef(0.03);
                        self.cube.append_mesh(&cube);
                    }
                }
                var marched_cube = MarchedCube.init();
                marched_cube.generate_mesh(pos, .{}, verts, &self.cube, self.arena);
            }
        }
        if (true) {
            // cubes at vine points
            for (self.vines.vines.items) |vine| {
                for (vine.points.items) |point| {
                    var cube = Mesh.unit_cube(self.arena);
                    defer cube.deinit();
                    cube.set_position(point.position);
                    cube.set_scalef(0.1);
                    self.cube.append_mesh(&cube);
                }
            }
        }
        self.vines.regenerate_mesh(0.95);
        if (false) {
            // Marching Cubes test
            var m = MarchedCube.init();
            const verts = [8]bool{
                // true, false, false, false, false, false, false, false,
                true, false, false, false, false, true, false, true,
            };
            m.generate_mesh(undefined, .{}, verts, &self.cube, self.arena);
            self.quit = true;
        }
    }

    pub fn deinit(self: *Self) void {
        self.typesetter.deinit();
        self.cube.deinit();
        self.vines.deinit();
    }

    pub fn handle_inputs(self: *Self, event: c.SDL_Event) void {
        if (event.@"type" == c.SDL_KEYDOWN and event.key.keysym.sym == c.SDLK_END)
            self.quit = true;
        self.inputs.mouse.handle_input(event, self.ticks, &self.cam2d);
        if (event.@"type" == c.SDL_KEYDOWN) {
            for (INPUT_MAPPING) |map| {
                if (event.key.keysym.sym == map.key) self.inputs.get_key(map.input).set_down(self.ticks);
            }
        } else if (event.@"type" == c.SDL_KEYUP) {
            for (INPUT_MAPPING) |map| {
                if (event.key.keysym.sym == map.key) self.inputs.get_key(map.input).set_release();
            }
        }
    }

    pub fn sdf_cube(self: *Self, point: Vector3_gl) c.GLfloat {
        _ = self;
        return sdf_default_cube(point);
    }

    // TODO (22 Apr 2022 sam): The direction calculation of the ray is wrong here. Needs to be fixed.
    pub fn ray_march(self: *Self, mouse_pos: Vector2) bool {
        const start = self.cam3d.position;
        // const forward = Vector3_gl{ .z = 1 };
        const lookat = self.cam3d.target.subtracted(self.cam3d.position).normalized();
        // we want a plane at z = 1, assuming the camera is at origin.
        const dx = std.math.tan(self.cam3d.fov * self.cam3d.aspect_ratio / 2.0);
        const dy = std.math.tan(self.cam3d.fov / 2.0);
        // we then find the point on that plane wrt mouse position, and get its length
        const px = ((mouse_pos.x / self.cam2d.render_size().x) * 2.0 - 1.0) * dx;
        const py = ((mouse_pos.y / self.cam2d.render_size().y) * 2.0 - 1.0) * dy;
        const point = Vector3_gl{ .x = px, .y = py, .z = 1 };
        // We then rotate the lookat based on the mouse pos, and scale to fit length
        const yaw_angle = ((mouse_pos.x / self.cam2d.render_size().x) * 2.0 - 1.0) * (self.cam3d.fov * self.cam3d.aspect_ratio / 2.0);
        const pitch_angle = ((mouse_pos.y / self.cam2d.render_size().y) * 2.0 - 1.0) * (self.cam3d.fov / 2.0);
        var direction = lookat.rotated_about_point_axis(.{}, self.cam3d.up, yaw_angle);
        direction = direction.rotated_about_point_axis(.{}, lookat.crossed(self.cam3d.up), -pitch_angle);
        const length = point.length();
        direction = direction.scaled(length);
        var dist: glf = 0.0;
        var i: usize = 0;
        var pos = start;
        while (i < 100) : (i += 1) {
            var d = self.sdf_cube(pos);
            pos = pos.added(direction.scaled(d));
            dist += d;
            if (d < 0.01) {
                return true;
            }
            if (dist > 20.0) {
                break;
            }
        }
        return false;
    }

    pub fn debug_ray_march(self: *Self) void {
        if (false) {
            self.debug = if (self.ray_march(self.inputs.mouse.current_pos)) 1 else 0;
            var x: f32 = 0;
            while (x < self.cam2d.render_size().x) : (x += 8) {
                var y: f32 = 0;
                while (y < self.cam2d.render_size().y) : (y += 8) {
                    if (self.ray_march(.{ .x = x, .y = y })) {
                        self.typesetter.draw_text_world_centered_font_color(.{ .x = x, .y = y }, "+", .debug, .{ .x = 1, .y = 0, .z = 0, .w = 1 });
                    }
                }
            }
        }
    }

    pub fn update(self: *Self, ticks: u32, arena: std.mem.Allocator) void {
        self.ticks = ticks;
        self.arena = arena;
        self.debug = if (self.inputs.get_key(.space).is_down) 1 else 0;
        self.debug_ray_march();
        self.vines.update(ticks, arena);
        if (self.inputs.mouse.r_button.is_down) {
            const amount = self.inputs.mouse.current_pos.x / self.cam2d.render_size().x;
            self.vines.regenerate_mesh(amount);
        }
        self.camera_controls();
    }

    pub fn camera_controls(self: *Self) void {
        var should_update_view = false;
        if (self.inputs.mouse.l_button.is_down) {
            if (self.inputs.mouse.movement()) |moved| {
                const x_rad = 1.0 * (moved.x * std.math.pi * 2) / self.cam2d.render_size().x;
                const y_rad = -1.0 * (moved.y * std.math.pi * 2) / self.cam2d.render_size().y;
                // rotation axis for y mouse movement... not actual y axis...
                const y_axis = Vector3_gl.cross(self.cam3d.position.subtracted(self.cam3d.target), .{ .y = 1 }).normalized();
                self.cam3d.position = self.cam3d.position.rotated_about_point_axis(self.cam3d.target, .{ .y = 1 }, x_rad);
                self.cam3d.position = self.cam3d.position.rotated_about_point_axis(self.cam3d.target, y_axis, y_rad);
                should_update_view = true;
            }
        }
        if (self.inputs.mouse.wheel_y != 0) {
            const scrolled = @intToFloat(c.GLfloat, -self.inputs.mouse.wheel_y);
            const zoom = std.math.pow(c.GLfloat, 1.1, scrolled);
            self.cam3d.position = self.cam3d.position.scaled_anchor(zoom, self.cam3d.target);
            should_update_view = true;
        }
        if (should_update_view) self.cam3d.update_view();
    }

    pub fn end_frame(self: *Self) void {
        self.inputs.mouse.reset_mouse();
    }
};
