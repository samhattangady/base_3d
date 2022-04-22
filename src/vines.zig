// vines is the code that allows vines to procedurally grow around objects.

const std = @import("std");
const c = @import("c.zig");
const constants = @import("constants.zig");

const helpers = @import("helpers.zig");
const Vector2 = helpers.Vector2;
const Vector3_gl = helpers.Vector3_gl;
const Matrix3_gl = helpers.Matrix3_gl;
const Camera2D = helpers.Camera2D;
const Camera3D = helpers.Camera3D;
const SingleInput = helpers.SingleInput;
const MouseState = helpers.MouseState;
const Mesh = helpers.Mesh;
const glf = c.GLfloat;

pub const Vines = struct {
    const Self = @This();
    mesh: Mesh,
    allocator: std.mem.Allocator,

    pub fn new(allocator: std.mem.Allocator) Self {
        return .{
            .mesh = Mesh.new(allocator),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Self) void {
        self.mesh.deinit();
    }

    pub fn grow(self: *Self, points: []Vector3_gl) void {
        self.mesh.deinit();
        self.mesh = Mesh.new(self.allocator);
        for (points) |point| {
            var cube = Mesh.unit_cube(self.allocator);
            defer cube.deinit();
            cube.set_scale(.{ .x = 0.2, .y = 0.2, .z = 0.2 });
            cube.set_position(point);
            self.mesh.append_mesh(&cube);
        }
    }
};
