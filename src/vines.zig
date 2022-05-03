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
const sdf_check = helpers.sdf_check;
const STEP_MULTIPLIER = 0.1;

const VinePoint = struct {
    position: Vector3_gl,
    direction: Vector3_gl,
    axis: Vector3_gl,
    scale: glf = 1.0,
};

const Vine = struct {
    const Self = @This();
    points: std.ArrayList(VinePoint),

    /// axis about which the vine rotates while growing
    pub fn init(allocator: std.mem.Allocator, axis: Vector3_gl) Self {
        _ = axis;
        return Self{
            .points = std.ArrayList(VinePoint).init(allocator),
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
    debug: std.ArrayList(Vector3_gl),
    /// the last point rendered by regenerate mesh.
    tip: Vector3_gl = .{},
    ticks: u32 = 0,

    pub fn init(allocator: std.mem.Allocator, arena: std.mem.Allocator) Self {
        return .{
            .mesh = Mesh.init(allocator),
            .vines = std.ArrayList(Vine).init(allocator),
            .debug = std.ArrayList(Vector3_gl).init(allocator),
            .allocator = allocator,
            .arena = arena,
        };
    }

    pub fn deinit(self: *Self) void {
        self.mesh.deinit();
        for (self.vines.items) |*vine| vine.deinit();
        self.vines.deinit();
        self.debug.deinit();
    }

    pub fn update(self: *Self, ticks: u32, arena: std.mem.Allocator) void {
        self.ticks = ticks;
        self.arena = arena;
    }

    pub fn grow(self: *Self, point: Vector3_gl, direction: Vector3_gl, sdf_fn: fn (helpers.Vector3_gl) glf, axis: Vector3_gl, ccw: bool, step_size: glf) void {
        // TODO (24 Apr 2022 sam): Automatically calculate ccw here. It should be possible
        _ = ccw;
        if (!helpers.sdf_check(sdf_fn(point))) {
            std.debug.print("dist from surface = {d}\n", .{sdf_fn(point)});
            unreachable; // the vine does not start at the sdf surface.
        }
        var vine = Vine.init(self.allocator, axis);
        if (false) {
            // testing the rotation matrix.
            const forward = direction.normalized();
            const side = helpers.sdf_gradient(point, sdf_fn);
            const up = forward.crossed(side);
            const rot = Matrix3_gl.rotation_matrix(side, up, forward);
            const p1 = Matrix3_gl.vec3_multiply(rot, .{ .x = 1 }).added(point);
            const p2 = Matrix3_gl.vec3_multiply(rot, .{ .y = 1 }).added(point);
            const p3 = Matrix3_gl.vec3_multiply(rot, .{ .z = 1 }).added(point);
            _ = p1.added(p2).added(p3);
            if (false) {
                self.debug.append(forward.added(point)) catch unreachable;
                self.debug.append(side.added(point)) catch unreachable;
                self.debug.append(up.added(point)) catch unreachable;
            }
            if (false) {
                self.debug.append(p1) catch unreachable;
                self.debug.append(p2) catch unreachable;
                self.debug.append(p3) catch unreachable;
            }
        }
        self.grow_vine(&vine, point, direction, sdf_fn, axis, step_size);
        std.debug.assert(vine.points.items.len > 0);
        std.debug.print("vine num points = {d}\n", .{vine.points.items.len});
        var i: usize = 0;
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
        // Update axis of each point so that the transitions are smoother...
        // TODO (03 May 2022 sam): Use a better approach for this, we want the
        // axis to change smoothly, so we should probably have some kind of offset
        // and then slowly resolve that instead of the way we're doing now...
        {
            for (vine.points.items) |*vp, j| {
                if (j == 0 or j == vine.points.items.len - 1) continue;
                const prev = vine.points.items[j - 1];
                const next = vine.points.items[j + 1];
                vp.axis = prev.axis.lerped(next.axis, 0.5).normalized();
            }
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
            if (false) std.debug.print("last_point_index = {d}\n", .{last});
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
                    .axis = prev_point.axis.lerped(cur_point.axis, t),
                    .scale = helpers.lerpf(amount * prev_point.scale, amount * cur_point.scale, t),
                };
                current_points.append(point) catch unreachable;
            }
            if (current_points.items.len > 0)
                self.generate_single_vine_mesh(current_points.items[0..]);
            if (current_points.items.len > 0) {
                self.tip = current_points.items[current_points.items.len - 1].position;
            }
        }
    }

    fn generate_single_vine_mesh(self: *Self, points: []VinePoint) void {
        var vertices = std.ArrayList(MeshVertex).init(self.arena);
        defer vertices.deinit();
        // TODO (23 Apr 2022 sam): I have a feeling there is something odd with NUMEDGES. with the -1s etc.
        const NUM_EDGES = 7.0;
        const NUM_EDGESi = @floatToInt(usize, NUM_EDGES);
        for (points) |vp| {
            const p1 = vp.position.added(vp.axis.scaled(0.005 + 0.08 * vp.scale));
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

    fn grow_vine(self: *Self, vine: *Vine, point: Vector3_gl, direction: Vector3_gl, sdf_fn: fn (helpers.Vector3_gl) glf, axis: Vector3_gl, step_size: glf) void {
        _ = self;
        _ = axis;
        var pos = point;
        var dir = direction;
        // TODO (29 Apr 2022 sam): Rather than asserting, we should instead find
        // the closest point along the sdf or something along those lines maybe.
        std.debug.assert(sdf_check(sdf_fn(point)));
        const point_axis = helpers.sdf_gradient(point, sdf_fn);
        vine.points.append(.{ .position = point, .direction = direction, .axis = point_axis }) catch unreachable;
        var prng = std.rand.DefaultPrng.init(0);
        var rand = prng.random();
        var i: usize = 0;
        while (i < 150) : (i += 1) {
            // first we find the points along a circle that lie along the plane
            // that we are travelling on that are STEP_MULTIPLIER * step_size from
            // the current position.
            // we find 4 points, and check whether the edge lies between them. we
            // assume that there is only one edge. We start at -135 deg so that we
            // dont accidentally go back the way that we came.
            var angles = [4]glf{ 0, 0, 0, 0 };
            const step: glf = 360.0 / 4.0;
            for (angles) |*a, j| {
                const deg: glf = -180 + (step / 2) + (step * @intToFloat(glf, j));
                a.* = deg * std.math.pi / 180;
            }
            const forward = dir.normalized();
            const inside = helpers.sdf_gradient(pos, sdf_fn);
            var up = dir.crossed(inside).negated();
            if (up.dotted(axis) < 0) up = up.negated();
            const rot = Matrix3_gl.rotation_matrix(inside, up, forward);
            const rad = STEP_MULTIPLIER * step_size;
            var a_neg: glf = undefined;
            var a_pos: glf = undefined;
            var new_pos: Vector3_gl = undefined;
            var found_new = false;
            if (false) {
                // debug points along plane.
                for (angles) |a| {
                    const p1 = helpers.xz_circle(a, rad).mat3_multiply(rot).added(pos);
                    self.debug.append(p1) catch unreachable;
                }
            }
            for (angles) |a, j| {
                if (j == angles.len - 1) unreachable; // couldn't find the angle pair
                const p1 = helpers.xz_circle(a, rad).mat3_multiply(rot).added(pos);
                const p2 = helpers.xz_circle(angles[j + 1], rad).mat3_multiply(rot).added(pos);
                const d1 = sdf_fn(p1);
                const d2 = sdf_fn(p2);
                if (sdf_check(d1)) {
                    new_pos = p1;
                    found_new = true;
                    break;
                }
                if (sdf_check(d2)) {
                    new_pos = p2;
                    found_new = true;
                    break;
                }
                if (helpers.opposite_signs(d1, d2)) {
                    if (d1 < 0) {
                        a_neg = angles[j];
                        a_pos = angles[j + 1];
                        break;
                    }
                    if (d2 < 0) {
                        a_neg = angles[j + 1];
                        a_pos = angles[j];
                        break;
                    }
                    unreachable; // neither is less than 0.
                }
            }
            if (!found_new) {
                // use a binary search type algo to find the angle between
                // a_neg and a_pos that lies along the radius of the circle
                // that is along the surface.
                new_pos = helpers.xz_circle((a_neg + a_pos) / 2.0, rad).mat3_multiply(rot).added(pos);
                if (false) {
                    std.debug.print("apos = {d}\t", .{(a_pos) / 2.0 * 180 / std.math.pi});
                    std.debug.print("aneg = {d}\t", .{(a_neg) / 2.0 * 180 / std.math.pi});
                    std.debug.print("finding thing...\n", .{});
                }
                while (!sdf_check(sdf_fn(new_pos))) {
                    if (@fabs(a_neg - a_pos) < 0.0000000001) unreachable; // no angle found.
                    const dist = sdf_fn(new_pos);
                    if (false) {
                        const ap = helpers.xz_circle((a_pos), rad).mat3_multiply(rot).added(pos);
                        const an = helpers.xz_circle((a_neg), rad).mat3_multiply(rot).added(pos);
                        const dap = sdf_fn(ap);
                        const dan = sdf_fn(an);
                        std.debug.print("d-pos = {d}\t d-neg = {d}\n", .{ dap, dan });
                        std.debug.assert(dap > dan);

                        std.debug.print("apos=  {d}\t", .{(a_pos) / 2.0 * 180 / std.math.pi});
                        std.debug.print("aneg=  {d}\t", .{(a_neg) / 2.0 * 180 / std.math.pi});
                        std.debug.print("dist = {d}\n", .{dist});
                    }
                    if (dist > 0) {
                        a_pos = (a_neg + a_pos) / 2.0;
                    } else {
                        a_neg = (a_neg + a_pos) / 2.0;
                    }
                    new_pos = helpers.xz_circle((a_neg + a_pos) / 2.0, rad).mat3_multiply(rot).added(pos);
                }
            }
            const angle = helpers.lerpf(-std.math.pi / 8.0, std.math.pi / 8.0, rand.float(glf));
            const nudged_pos = new_pos.rotated_about_point_axis(pos, inside, angle);
            // This sometimes gives us an infinite loop, so it's an opt
            if (helpers.sdf_closest(nudged_pos, sdf_fn)) |closest| {
                new_pos = closest;
            }
            dir = new_pos.subtracted(pos).normalized();
            pos = new_pos;
            vine.points.append(.{ .position = pos, .direction = dir, .axis = inside }) catch unreachable;
        }
    }
};
