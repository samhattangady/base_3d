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
};

const Vine = struct {
    const Self = @This();
    points: std.ArrayList(VinePoint),
    /// axis about which the vine rotates while growing
    axis: Vector3_gl,

    pub fn init(allocator: std.mem.Allocator, axis: Vector3_gl) Self {
        return Self{
            .points = std.ArrayList(VinePoint).init(allocator),
            .axis = axis,
        };
    }

    pub fn deinit(self: *Self) void {
        self.points.deinit();
    }
};

pub const Vines = struct {
    const Self = @This();
    mesh: Mesh,
    vines: std.ArrayList(Vine),
    allocator: std.mem.Allocator,
    arena: std.mem.Allocator,
    ticks: u32 = 0,

    pub fn init(allocator: std.mem.Allocator, arena: std.mem.Allocator) Self {
        return .{
            .mesh = Mesh.init(allocator),
            .vines = std.ArrayList(Vine).init(allocator),
            .allocator = allocator,
            .arena = arena,
        };
    }

    pub fn deinit(self: *Self) void {
        self.mesh.deinit();
        for (self.vines.items) |*vine| vine.deinit();
        self.vines.deinit();
    }

    pub fn update(self: *Self, ticks: u32, arena: std.mem.Allocator) void {
        self.ticks = ticks;
        self.arena = arena;
    }

    pub fn grow(self: *Self, point: Vector3_gl, direction: Vector3_gl, sdf_fn: fn (helpers.Vector3_gl) glf, axis: Vector3_gl, ccw: bool) void {
        // TODO (24 Apr 2022 sam): Automatically calculate ccw here. It should be possible
        if (!helpers.sdf_check(sdf_fn(point)))
            unreachable; // the vine does not start at the sdf surface.
        var pos = point;
        var dir = direction;
        var i: usize = 0;
        var vine = Vine.init(self.allocator, axis);
        vine.points.append(.{ .position = pos, .direction = dir }) catch unreachable;
        while (true) : (i += 1) {
            const next = self.get_next_pos(pos, &dir, sdf_fn, axis, ccw);
            if (next) |next_pos| {
                pos = next_pos;
                vine.points.append(.{ .position = pos, .direction = dir }) catch unreachable;
            } else {
                break;
            }
            if (i > 100000) {
                std.debug.print("Ending vine generation. Vine has become very long\n", .{});
                break;
            }
            if (dir.dotted(direction) < -0.99) {
                std.debug.print("ending vine generation. going opposite direction\n", .{});
                break;
            }
        }
        std.debug.assert(vine.points.items.len > 0);
        // get length of current vine
        var total_len: glf = 0.0;
        {
            i = 0;
            var len: glf = 0.0;
            while (i < vine.points.items.len - 1) : (i += 1) {
                const p0 = vine.points.items[i].position;
                const p1 = vine.points.items[i + 1].position;
                len += Vector3_gl.distance(p0, p1);
            }
            total_len = len;
        }
        // set scale of each point;
        {
            i = 0;
            var len: glf = 0.0;
            while (i < vine.points.items.len - 1) : (i += 1) {
                const p0 = vine.points.items[i].position;
                const p1 = vine.points.items[i + 1].position;
                vine.points.items[i].scale = 1.0 - (len / total_len);
                len += Vector3_gl.distance(p0, p1);
            }
            vine.points.items[vine.points.items.len - 1].scale = 0.0;
        }
        self.vines.append(vine) catch unreachable;
    }

    pub fn regenerate_mesh(self: *Self, raw_amount: glf) void {
        self.mesh.deinit();
        self.mesh = Mesh.init(self.allocator);
        if (raw_amount < 0) return;
        const amount = std.math.clamp(raw_amount, 0.001, 1.0);
        for (self.vines.items) |vine| {
            var last: usize = 0;
            // calculate all the points that are present in amount
            var current_points = std.ArrayList(VinePoint).init(self.arena);
            defer current_points.deinit();
            last = 0;
            var need_lerped_point = false;
            for (vine.points.items) |vp, vpi| {
                last = vpi;
                const progress = 1.0 - vp.scale;
                if (progress < amount) {
                    var new_vp = vp;
                    new_vp.scale = amount * vp.scale;
                    // TODO (23 Apr 2022 sam): update point scale to match the progress
                    current_points.append(new_vp) catch unreachable;
                    need_lerped_point = true;
                } else {
                    if (progress == amount) need_lerped_point = false;
                    break;
                }
            }
            if (need_lerped_point) {
                // generate a point that is at exactly progress = amount
                std.debug.assert(last > 0);
                const prev_point = vine.points.items[last - 1];
                const cur_point = vine.points.items[last];
                const prev_progress = 1.0 - prev_point.scale;
                const cur_progress = 1.0 - cur_point.scale;
                std.debug.assert(prev_progress < amount and amount < cur_progress);
                const t = helpers.unlerpf(prev_progress, cur_progress, amount);
                const point = VinePoint{
                    .position = prev_point.position.lerped(cur_point.position, t),
                    // TODO (23 Apr 2022 sam): what should the direction be?
                    .direction = prev_point.direction,
                    .scale = helpers.lerpf(amount * prev_point.scale, amount * cur_point.scale, t),
                };
                current_points.append(point) catch unreachable;
            }
            if (current_points.items.len > 0)
                self.generate_single_vine_mesh(current_points.items[0..], vine.axis);
        }
    }

    fn generate_single_vine_mesh(self: *Self, points: []VinePoint, axis: Vector3_gl) void {
        var vertices = std.ArrayList(MeshVertex).init(self.arena);
        defer vertices.deinit();
        // TODO (23 Apr 2022 sam): I have a feeling there is something odd with NUMEDGES. with the -1s etc.
        const NUM_EDGES = 7.0;
        const NUM_EDGESi = @floatToInt(usize, NUM_EDGES);
        for (points) |vp| {
            const p1 = vp.position.added(axis.scaled(0.005 + 0.08 * vp.scale));
            var angle: glf = 0.0;
            while (angle < helpers.TWO_PI) : (angle += helpers.TWO_PI / (NUM_EDGES - 1.0)) {
                const p = p1.rotated_about_point_axis(vp.position, vp.direction, angle);
                vertices.append(.{ .position = p, .normal = p.subtracted(vp.position).normalized() }) catch unreachable;
            }
            if (false) {
                var cube = Mesh.unit_cube(self.arena);
                defer cube.deinit();
                cube.set_position(vp.position);
                cube.set_scalef(0.03);
                self.mesh.append_mesh(&cube);
            }
        }
        {
            // round off base end
            const p0 = points[0];
            const size = vertices.items[0].position.subtracted(p0.position).length();
            const base = p0.position.added(p0.direction.scaled(-size * 0.5));
            const base_vertex = MeshVertex{ .position = base, .normal = p0.direction.negated() };
            var j: usize = 0;
            while (j < NUM_EDGESi) : (j += 1) {
                const v0 = vertices.items[j];
                const v1 = if (j == NUM_EDGESi - 1) vertices.items[0] else vertices.items[j + 1];
                self.mesh.vertices.append(base_vertex) catch unreachable;
                self.mesh.vertices.append(v0) catch unreachable;
                self.mesh.vertices.append(v1) catch unreachable;
            }
        }
        var i: usize = 0;
        while (i < points.len - 1) : (i += 1) {
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
        {
            // round off tip end
            const p0 = points[points.len - 1];
            const size = vertices.items[vertices.items.len - 1].position.subtracted(p0.position).length();
            const tip = p0.position.added(p0.direction.scaled(size * 1.0));
            const tip_vertex = MeshVertex{ .position = tip, .normal = p0.direction };
            var j: usize = 0;
            const last_loop = vertices.items.len - NUM_EDGESi;
            while (j < NUM_EDGESi) : (j += 1) {
                const v0 = vertices.items[j + last_loop];
                const v1 = if (j == NUM_EDGESi - 1) vertices.items[last_loop] else vertices.items[last_loop + j + 1];
                self.mesh.vertices.append(tip_vertex) catch unreachable;
                self.mesh.vertices.append(v0) catch unreachable;
                self.mesh.vertices.append(v1) catch unreachable;
            }
        }
    }

    pub fn get_next_pos(self: *Self, point: Vector3_gl, direction: *Vector3_gl, sdf_fn: fn (helpers.Vector3_gl) glf, axis: Vector3_gl, ccw: bool) ?Vector3_gl {
        _ = self;
        _ = ccw;
        _ = axis;
        const end = point.added(direction.*.scaled(0.2));
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
            const gradient = helpers.sdf_gradient(end, sdf_fn);
            const pos = end.added(gradient.scaled(-dist));
            direction.* = pos.subtracted(point).normalized();
            return pos;
        }
    }
};
