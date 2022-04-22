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

const VinePoint = struct {
    position: Vector3_gl,
    direction: Vector3_gl,
    index: usize,
    vine_index: usize,
};

pub const Vines = struct {
    const Self = @This();
    mesh: Mesh,
    points: std.ArrayList(VinePoint),
    allocator: std.mem.Allocator,
    num_vines: usize = 0,

    pub fn init(allocator: std.mem.Allocator) Self {
        return .{
            .mesh = Mesh.new(allocator),
            .points = std.ArrayList(VinePoint).init(allocator),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Self) void {
        self.mesh.deinit();
        self.points.deinit();
    }

    pub fn grow(self: *Self, point: Vector3_gl, direction: Vector3_gl, sdf_fn: fn (helpers.Vector3_gl) glf) void {
        var pos = point;
        var dir = direction;
        var i: usize = 0;
        var scale: glf = 0.1;
        while (i < 14) : (i += 1) {
            var cube = Mesh.unit_cube(self.allocator);
            defer cube.deinit();
            cube.set_scalef(scale);
            cube.set_position(pos);
            self.mesh.append_mesh(&cube);
            pos = self.get_next_pos(pos, &dir, sdf_fn);
            // std.debug.print("{d}: pos = {d},{d},{d}, dist = {d}\n", .{ i, pos.x, pos.y, pos.z, sdf_fn(pos) });
            self.points.append(.{ .position = pos, .direction = dir, .index = i, .vine_index = self.num_vines });
            scale *= 0.95;
        }
        self.num_vines += 1;
    }

    pub fn get_next_pos(self: *Self, point: Vector3_gl, direction: *Vector3_gl, sdf_fn: fn (helpers.Vector3_gl) glf) Vector3_gl {
        _ = self;
        const end = point.added(direction.*);
        const dist = sdf_fn(end);
        // the vine is still growing along the sdf
        if (helpers.sdf_check(dist)) return end;
        std.debug.assert(dist > -0.02);
        // otherwise, somewhere between the previous position and now, we left the thing.
        if (helpers.sdf_check(sdf_fn(point.added(direction.*.scaled(0.01))))) {
            // the edge is somewhere between last and this, we have to find the edge.
            // TODO (22 Apr 2022 sam): Use some kind of binary search to make this faster.
            var t: glf = 0.0;
            var pos = point.lerped(end, t);
            while (helpers.sdf_check(sdf_fn(pos))) {
                t += 0.01;
                pos = point.lerped(end, t);
                if (t > 1.01) unreachable; // could not find an edge between previous point and now
            }
            t -= 0.01;
            pos = point.lerped(end, t);
            return pos;
        } else {
            // we left off at the edge last time, then we will have to turn and check now
            // TODO (22 Apr 2022 sam): Use some kind of binary search to make this faster.
            var count: usize = 0;
            var dir = direction.*.scaled(0.1);
            var pos = point.added(dir);
            while (!helpers.sdf_check(sdf_fn(pos))) {
                pos = pos.rotated_about_point_axis(point, .{ .y = 1 }, helpers.TWO_PI / 500.0);
                count += 1;
                if (count > 500) unreachable; // could not turn and find next point
            }
            direction.* = pos.subtracted(point).normalized();
            return pos;
        }
    }
};
