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
const MeshVertex = helpers.MeshVertex;
const glf = c.GLfloat;

const VinePoint = struct {
    position: Vector3_gl,
    direction: Vector3_gl,
    scale: glf = 1.0,
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

    pub fn grow(self: *Self, point: Vector3_gl, direction: Vector3_gl, sdf_fn: fn (helpers.Vector3_gl) glf, ccw: bool) void {
        var pos = point;
        var dir = direction;
        var i: usize = 0;
        const v_start_index = self.points.items.len;
        self.points.append(.{ .position = pos, .direction = dir, .vine_index = self.num_vines }) catch unreachable;
        while (i < 14) : (i += 1) {
            pos = self.get_next_pos(pos, &dir, sdf_fn, ccw);
            // std.debug.print("{d}: pos = {d},{d},{d}, dist = {d}\n", .{ i, pos.x, pos.y, pos.z, sdf_fn(pos) });
            self.points.append(.{ .position = pos, .direction = dir, .vine_index = self.num_vines }) catch unreachable;
        }
        const num_points = 1 + self.points.items.len - v_start_index;
        std.debug.assert(self.points.items.len > 0);
        // get length of current vine
        var total_len: glf = 0.0;
        {
            i = v_start_index;
            var len: glf = 0.0;
            while (i < self.points.items.len - 1) : (i += 1) {
                const p0 = self.points.items[i].position;
                const p1 = self.points.items[i + 1].position;
                len += Vector3_gl.distance(p0, p1);
            }
            total_len = len;
        }
        // set scale of each point;
        {
            i = v_start_index;
            var len: glf = 0.0;
            while (i < self.points.items.len - 1) : (i += 1) {
                const p0 = self.points.items[i].position;
                const p1 = self.points.items[i + 1].position;
                self.points.items[i].scale = 1.0 - (len / total_len);
                len += Vector3_gl.distance(p0, p1);
            }
            self.points.items[self.points.items.len - 1].scale = 0.0;
        }
        // generate mesh
        var vertices = std.ArrayList(MeshVertex).init(self.allocator);
        defer vertices.deinit();
        const NUM_EDGES = 7.0;
        const NUM_EDGESi = @floatToInt(usize, NUM_EDGES);
        i = v_start_index;
        while (i < self.points.items.len) : (i += 1) {
            const vp = self.points.items[i];
            const p1 = vp.position.added(.{ .y = 0.005 + 0.08 * vp.scale });
            var angle: glf = 0.0;
            while (angle < helpers.TWO_PI) : (angle += helpers.TWO_PI / (NUM_EDGES - 1.0)) {
                const p = p1.rotated_about_point_axis(vp.position, vp.direction, angle);
                vertices.append(.{ .position = p, .normal = p.subtracted(vp.position).normalized() }) catch unreachable;
            }
            if (false) {
                var cube = Mesh.unit_cube(self.allocator);
                defer cube.deinit();
                cube.set_position(vp.position);
                cube.set_scalef(0.03);
                self.mesh.append_mesh(&cube);
            }
        }
        i = 0;
        while (i < num_points - 2) : (i += 1) {
            var j: usize = 0;
            while (j < NUM_EDGESi) : (j += 1) {
                const ind0 = (i * NUM_EDGESi) + j;
                const ind1 = if (j == NUM_EDGESi - 1) (i * NUM_EDGESi) else ind0 + 1;
                const ind2 = ((i + 1) * NUM_EDGESi) + j;
                const ind3 = if (j == NUM_EDGESi - 1) ((i + 1) * NUM_EDGESi) else ind2 + 1;
                const vp0 = vertices.items[ind0];
                const vp1 = vertices.items[ind1];
                const vp2 = vertices.items[ind2];
                const vp3 = vertices.items[ind3];
                self.mesh.vertices.append(vp0) catch unreachable;
                self.mesh.vertices.append(vp1) catch unreachable;
                self.mesh.vertices.append(vp2) catch unreachable;
                self.mesh.vertices.append(vp1) catch unreachable;
                self.mesh.vertices.append(vp3) catch unreachable;
                self.mesh.vertices.append(vp2) catch unreachable;
            }
        }
        self.num_vines += 1;
    }

    pub fn get_next_pos(self: *Self, point: Vector3_gl, direction: *Vector3_gl, sdf_fn: fn (helpers.Vector3_gl) glf, ccw: bool) Vector3_gl {
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
            const mult: glf = if (ccw) 1.0 else -1.0;
            while (!helpers.sdf_check(sdf_fn(pos))) {
                pos = pos.rotated_about_point_axis(point, .{ .y = 1 }, mult * helpers.TWO_PI / 500.0);
                count += 1;
                if (count > 500) unreachable; // could not turn and find next point
            }
            direction.* = pos.subtracted(point).normalized();
            return pos;
        }
    }
};
