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
const BRANCH_PROB = 0.05;
const FIRST_BRANCH = 20;
// fraction of the total that the branch will be.
const BRANCH_LENGTH = 0.06;
const LEAF_PROB = 0.7;
const LEAF_LENGTH = 0.2;
const LEAF_WIDTH = LEAF_LENGTH * 0.25;
const LEAF_GROWTH_TIME = 0.04;

comptime {
    std.debug.assert(LEAF_PROB <= 1.0);
}

const Leaf = struct {
    // point at which the leaf should start forming
    start_scale: glf,
    position: Vector3_gl,
    direction: Vector3_gl,
    axis: Vector3_gl,
};

const VinePoint = struct {
    position: Vector3_gl,
    direction: Vector3_gl,
    axis: Vector3_gl,
    scale: glf = 1.0,
};

const Vine = struct {
    const Self = @This();
    points: std.ArrayList(VinePoint),
    start_scale: glf = 1.0,
    end_scale: glf = 0.0,

    /// axis about which the vine rotates while growing
    pub fn init(allocator: std.mem.Allocator, start_scale: glf, end_scale: glf) Self {
        return Self{
            .points = std.ArrayList(VinePoint).init(allocator),
            .start_scale = start_scale,
            .end_scale = end_scale,
        };
    }

    pub fn deinit(self: *Self) void {
        self.points.deinit();
    }
};

pub const Vines = struct {
    const Self = @This();
    mesh: Mesh,
    leaf_mesh: Mesh,
    vines: std.ArrayList(Vine),
    leaves: std.ArrayList(Leaf),
    allocator: std.mem.Allocator,
    arena: std.mem.Allocator,
    debug: std.ArrayList(Vector3_gl),
    /// the last point rendered by regenerate mesh.
    tip: Vector3_gl = .{},
    ticks: u32 = 0,

    pub fn init(allocator: std.mem.Allocator, arena: std.mem.Allocator) Self {
        return .{
            .mesh = Mesh.init(allocator),
            .leaf_mesh = Mesh.init(allocator),
            .vines = std.ArrayList(Vine).init(allocator),
            .leaves = std.ArrayList(Leaf).init(allocator),
            .debug = std.ArrayList(Vector3_gl).init(allocator),
            .allocator = allocator,
            .arena = arena,
        };
    }

    pub fn deinit(self: *Self) void {
        self.mesh.deinit();
        self.leaf_mesh.deinit();
        for (self.vines.items) |*vine| vine.deinit();
        self.vines.deinit();
        self.leaves.deinit();
        self.debug.deinit();
    }

    pub fn update(self: *Self, ticks: u32, arena: std.mem.Allocator) void {
        self.ticks = ticks;
        self.arena = arena;
    }

    pub fn grow(self: *Self, point: Vector3_gl, direction: Vector3_gl, sdf_fn: fn (helpers.Vector3_gl) glf, step_size: glf, vine_length: glf) void {
        self.grow_single_vine(point, direction, sdf_fn, step_size, vine_length, 1.0, 0.0);
        var prng = std.rand.DefaultPrng.init(0);
        var rand = prng.random();
        const vine = self.vines.items[0];
        {
            // TODO (03 May 2022 sam): What is the best branching behaviour?
            var branches = std.ArrayList([3]Vector3_gl).init(self.arena);
            defer branches.deinit();
            var neg = false;
            for (vine.points.items) |vp, vp_index| {
                if (vp_index < FIRST_BRANCH) continue;
                if (rand.float(glf) > BRANCH_PROB) continue;
                const pos = vp.position;
                var angle = helpers.lerpf(std.math.pi / 6.0, std.math.pi / 5.0, rand.float(glf));
                if (neg) angle *= -1.0;
                neg = !neg;
                const dir = vp.direction.rotated_about_point_axis(.{}, vp.axis, angle);
                branches.append(.{ pos, dir, .{ .x = vp.scale } }) catch unreachable;
            }
            for (branches.items) |branch| {
                const start_scale = branch[2].x;
                const end_scale = std.math.max(0.0, start_scale - BRANCH_LENGTH);
                self.grow_single_vine(branch[0], branch[1], sdf_fn, step_size, vine_length * (start_scale - end_scale), start_scale, end_scale);
                const vine_index = self.vines.items.len - 1;
                self.add_leaves_to_vine(vine_index, rand);
            }
        }
        std.debug.print("num_leaves = {d}\n", .{self.leaves.items.len});
    }

    fn add_leaves_to_vine(self: *Self, vine_index: usize, rand: std.rand.Random) void {
        const vine = &self.vines.items[vine_index];
        var angle: glf = 0.0;
        for (vine.points.items) |vp| {
            if (rand.float(glf) > LEAF_PROB) continue;
            const direction = vp.axis.rotated_about_point_axis(vp.position, vp.direction, angle).lerped(vp.direction, 0.3).normalized();
            const axis = direction.crossed(vp.axis).normalized();
            // fibonacci angle
            angle += 137.5 / 180.0 * std.math.pi;
            const leaf = Leaf{ .position = vp.position, .direction = direction, .axis = axis, .start_scale = vp.scale };
            self.leaves.append(leaf) catch unreachable;
        }
    }

    fn grow_single_vine(self: *Self, point: Vector3_gl, direction: Vector3_gl, sdf_fn: fn (helpers.Vector3_gl) glf, step_size: glf, vine_length: glf, start_scale: glf, end_scale: glf) void {
        var pos = point;
        var dir = direction;
        var vine = Vine.init(self.allocator, start_scale, end_scale);
        if (!helpers.sdf_check(sdf_fn(point))) {
            if (helpers.sdf_along_direction(pos, dir, sdf_fn)) |p| {
                // TODO (04 May 2022 sam): Don't just add a straight line here.
                // create some amount of jitter as the vine moves towards the
                // connection point
                vine.points.append(.{ .position = point, .direction = direction, .axis = direction.crossed(.{ .z = 1 }).normalized() }) catch unreachable;
                pos = p;
                const inside = helpers.sdf_gradient(pos, sdf_fn);
                const perp = inside.crossed(direction).normalized();
                dir = perp.crossed(inside).normalized();
            } else {
                unreachable; // the vine does not approach surface.
            }
        }
        self.simulate_vine_growth(&vine, pos, dir, sdf_fn, step_size, vine_length);
        // get length of current vine
        var total_len: glf = 0.0;
        {
            var i: usize = 0;
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
            var i: usize = 0;
            var len: glf = 0.0;
            while (i < vine.points.items.len - 1) : (i += 1) {
                const p0 = vine.points.items[i].position;
                const p1 = vine.points.items[i + 1].position;
                vine.points.items[i].scale = helpers.lerpf(start_scale, end_scale, (len / total_len));
                len += Vector3_gl.distance(p0, p1);
            }
            vine.points.items[vine.points.items.len - 1].scale = end_scale;
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

    pub fn regenerate_mesh(self: *Self, raw_amount: glf, fall_amount: glf, ticks: u32) void {
        self.mesh.clear();
        self.leaf_mesh.clear();
        if (raw_amount <= 0) return;
        var amount = std.math.clamp(raw_amount, 0.001, 1.0);
        for (self.vines.items) |vine, vine_index| {
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
                    const vine_scale = (vine.start_scale - vine.end_scale) * helpers.unlerpf(vine.end_scale, vine.start_scale, vp.scale);
                    new_vp.scale = std.math.min(amount, (1.0 - vine.end_scale)) * vine_scale;
                    current_points.append(new_vp) catch unreachable;
                    need_lerped_point = true;
                } else {
                    if (progress == amount) need_lerped_point = false;
                    break;
                }
            }
            if (last == vine.points.items.len - 1) need_lerped_point = false;
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
            if (vine_index == 0 and current_points.items.len > 0) {
                self.tip = current_points.items[current_points.items.len - 1].position;
            }
        }
        for (self.leaves.items) |raw_leaf| {
            const leaf = self.leaf_fall(raw_leaf, fall_amount);
            const pos1 = helpers.Vector2{ .x = leaf.position.x, .y = leaf.position.z };
            const pos2 = helpers.Vector2{ .x = leaf.position.x, .y = leaf.position.y };
            const speed = helpers.noise_range(pos2, 4, 0, 400, 1400);
            const displacement: glf = helpers.noise(pos1, 4, @intToFloat(glf, ticks) / speed);
            const displacement2: glf = helpers.noise(pos2, 4, @intToFloat(glf, ticks) / speed);
            // TODO (04 May 2022 sam): Does this handle the last few leaves that
            // that are near scale = 0 correctly?
            // TODO (04 May 2022 sam): We want leaves that are viewed from above to
            // have different normals from below.
            const end_scale = leaf.start_scale - LEAF_GROWTH_TIME;
            var leaf_growth = std.math.clamp(helpers.unlerpf(leaf.start_scale, end_scale, (1.0 - amount)), 0.0, 1.0);
            const leaf_size = (1.0 - fall_amount) * helpers.noise_range(pos2, 1, 0, 0.4, 1.0);
            const perp = leaf.direction.crossed(leaf.axis);
            leaf_growth = helpers.easeinoutf(0.0, 1.0, leaf_growth);
            if (leaf_growth == 0) continue;
            const p1 = leaf.position;
            const p2 = p1.added(leaf.direction.scaled(leaf_size * LEAF_LENGTH * leaf_growth)).added(leaf.axis.scaled(leaf_size * LEAF_LENGTH * 0.1 * leaf_growth)).added(perp.scaled(displacement * 0.8 * leaf_size * LEAF_WIDTH)).added(leaf.axis.scaled(displacement2 * 0.3 * leaf_size * LEAF_WIDTH));
            const mid = p1.added(leaf.direction.scaled(leaf_size * LEAF_LENGTH * 0.5 * leaf_growth));
            const p3 = mid.added(perp.scaled(leaf_size * LEAF_WIDTH * leaf_growth));
            const p4 = mid.added(perp.scaled(leaf_size * -LEAF_WIDTH * leaf_growth));
            const base_color = helpers.Vector4_gl.lerp(self.leaf_mesh.color, .{ .x = 1.0, .y = 0.4, .z = 0.4, .w = 1.0 }, 0.5);
            const tip_color = helpers.Vector4_gl.lerp(self.leaf_mesh.color, .{ .x = 1.0, .y = 1.0, .z = 0.2, .w = 1.0 }, 0.5);
            const v1 = MeshVertex{ .position = p1, .normal = leaf.axis.lerped(mid.subtracted(p1).normalized(), 0.3).normalized(), .color = base_color };
            const v2 = MeshVertex{ .position = p2, .normal = leaf.axis.lerped(mid.subtracted(p2).normalized(), 0.3).normalized(), .color = tip_color };
            const v3 = MeshVertex{ .position = p3, .normal = leaf.axis.lerped(mid.subtracted(p3).normalized(), 0.3).normalized(), .color = self.leaf_mesh.color };
            const v4 = MeshVertex{ .position = p4, .normal = leaf.axis.lerped(mid.subtracted(p4).normalized(), 0.3).normalized(), .color = self.leaf_mesh.color };
            self.leaf_mesh.vertices.append(v1) catch unreachable;
            self.leaf_mesh.vertices.append(v4) catch unreachable;
            self.leaf_mesh.vertices.append(v3) catch unreachable;
            self.leaf_mesh.vertices.append(v2) catch unreachable;
            self.leaf_mesh.vertices.append(v4) catch unreachable;
            self.leaf_mesh.vertices.append(v3) catch unreachable;
        }
    }

    fn leaf_fall(self: *Self, leaf: Leaf, fall_amount: glf) Leaf {
        _ = self;
        if (fall_amount == 0.0) return leaf;
        const MAX_FALL: f32 = 2.0;
        const MAX_RADIUS: f32 = 0.4;
        const seed = Vector2{ .x = leaf.position.x * 1000, .y = leaf.position.z * 1000 };
        const leaf_fall_amount = MAX_FALL * helpers.noise_range(seed, 0.5, 0, 0.6, 1.0);
        const amount1 = helpers.noise_range(seed, 1, 3000, 0.1, 0.4);
        const amount2 = amount1 + helpers.noise_range(seed, 1, 7000, 0.1, 0.4);
        const amount3 = amount2 + helpers.noise_range(seed, 1, 15000, 0.1, 0.4);
        const ring1_center = leaf.position.added(.{ .y = leaf_fall_amount * amount1 });
        const ring2_center = leaf.position.added(.{ .y = leaf_fall_amount * amount2 });
        const ring3_center = leaf.position.added(.{ .y = leaf_fall_amount * amount3 });
        const ring1_angle = helpers.noise_range(seed, 1, 1000, 0, helpers.TWO_PI);
        const ring2_angle = helpers.noise_range(seed, 1, 1200, 0, helpers.TWO_PI);
        const ring3_angle = helpers.noise_range(seed, 1, 1500, 0, helpers.TWO_PI);
        const ring1_radius = MAX_RADIUS * helpers.noise_range(seed, 1, 2000, 0.7, MAX_RADIUS);
        const ring2_radius = MAX_RADIUS * helpers.noise_range(seed, 1, 2030, 0.7, MAX_RADIUS);
        const ring3_radius = MAX_RADIUS * helpers.noise_range(seed, 1, 2060, 0.7, MAX_RADIUS);
        const pos0 = leaf.position;
        const pos1 = ring1_center.added(.{ .x = ring1_radius }).rotated_about_point_axis(ring1_center, .{ .y = 1 }, ring1_angle);
        const pos2 = ring2_center.added(.{ .x = ring2_radius }).rotated_about_point_axis(ring2_center, .{ .y = 1 }, ring2_angle);
        const pos3 = ring3_center.added(.{ .x = ring3_radius }).rotated_about_point_axis(ring3_center, .{ .y = 1 }, ring3_angle);
        var l = leaf;
        l.position = self.lerp_multiple(pos0, pos1, pos2, pos3, fall_amount);
        return l;
    }

    fn lerp_multiple(self: *Self, p0: Vector3_gl, p1: Vector3_gl, p2: Vector3_gl, p3: Vector3_gl, amount: glf) Vector3_gl {
        _ = self;
        const dist1 = p0.distance_to(p1);
        const dist2 = p1.distance_to(p2);
        const dist3 = p2.distance_to(p3);
        const total_dist = dist1 + dist2 + dist3;
        const portion1 = dist1 / total_dist;
        const portion2 = dist2 / total_dist;
        const portion3 = dist3 / total_dist;
        if (amount < portion1) {
            const fract = amount / portion1;
            return arc_lerp(p0, p1, fract);
        } else if (amount < (portion1 + portion2)) {
            const fract = (amount - portion1) / portion2;
            return arc_lerp(p1, p2, fract);
        } else {
            const fract = (amount - portion1 - portion2) / portion3;
            return arc_lerp(p2, p3, fract);
        }
    }

    // bezier lerp with mid point between point right below p0 and mid of p0-p1
    fn arc_lerp(p0: Vector3_gl, p1: Vector3_gl, amount: glf) Vector3_gl {
        const fract = helpers.easeinoutf(0.0, 1.0, amount);
        const mid1 = Vector3_gl{ .x = p0.x, .y = p1.y, .z = p0.z };
        const mid2 = p0.lerped(p1, 0.5);
        const mid = mid1.lerped(mid2, 0.5);
        const m1 = p0.lerped(mid, fract);
        const m2 = mid.lerped(p1, fract);
        return m1.lerped(m2, fract);
    }

    fn generate_single_vine_mesh(self: *Self, points: []VinePoint) void {
        var vertices = std.ArrayList(MeshVertex).init(self.arena);
        defer vertices.deinit();
        // TODO (23 Apr 2022 sam): I have a feeling there is something odd with NUMEDGES. with the -1s etc.
        const NUM_EDGES = 7.0;
        const NUM_EDGESi = @floatToInt(usize, NUM_EDGES);
        for (points) |vp| {
            const p1 = vp.position.added(vp.axis.scaled(0.005 + 0.02 * vp.scale));
            var angle: glf = 0.0;
            while (angle < helpers.TWO_PI) : (angle += helpers.TWO_PI / (NUM_EDGES - 1.0)) {
                const p = p1.rotated_about_point_axis(vp.position, vp.direction, angle);
                const color = helpers.Vector4_gl.lerp(self.mesh.color, .{ .x = 0.2, .w = 1.0 }, 0.1 * angle / helpers.TWO_PI);
                vertices.append(.{ .position = p, .normal = p.subtracted(vp.position).normalized(), .color = color }) catch unreachable;
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
            const base_vertex = MeshVertex{ .position = base, .normal = p0.direction.negated(), .color = self.mesh.color };
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
            const tip_vertex = MeshVertex{ .position = tip, .normal = p0.direction, .color = self.mesh.color };
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

    fn simulate_vine_growth(self: *Self, vine: *Vine, point: Vector3_gl, direction: Vector3_gl, sdf_fn: fn (helpers.Vector3_gl) glf, step_size: glf, vine_length: glf) void {
        _ = self;
        var pos = point;
        var dir = direction;
        // TODO (29 Apr 2022 sam): Rather than asserting, we should instead find
        // the closest point along the sdf or something along those lines maybe.
        std.debug.assert(sdf_check(sdf_fn(point)));
        const point_axis = helpers.sdf_gradient(point, sdf_fn);
        vine.points.append(.{ .position = point, .direction = direction, .axis = point_axis }) catch unreachable;
        var prng = std.rand.DefaultPrng.init(0);
        var rand = prng.random();
        var length: glf = 0;
        while (length < vine_length) {
            // first we find the points along a circle that lie along the plane
            // that we are travelling on that are STEP_MULTIPLIER * step_size from
            // the current position.
            // we find 4 points, and check whether the edge lies between them. we
            // assume that there is only one edge. We start at -135 deg so that we
            // dont accidentally go back the way that we came.
            var angles = [10]glf{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
            const step: glf = 360.0 / 10.0;
            for (angles) |*a, j| {
                const deg: glf = -180 + (step / 2) + (step * @intToFloat(glf, j));
                a.* = deg * std.math.pi / 180;
            }
            const forward = dir.normalized();
            const inside = helpers.sdf_gradient(pos, sdf_fn);
            const up = dir.crossed(inside);
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
                if (j == angles.len - 1) {
                    // TODO (04 May 2022 sam): Figure out why this could be the case.
                    std.debug.print("could not find angle pair\n", .{});
                    return;
                }
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
            if (helpers.sdf_closest(nudged_pos, sdf_fn)) |closest| new_pos = closest;
            length += new_pos.distance_to(pos);
            dir = new_pos.subtracted(pos).normalized();
            pos = new_pos;
            vine.points.append(.{ .position = pos, .direction = dir, .axis = inside }) catch unreachable;
        }
    }
};
