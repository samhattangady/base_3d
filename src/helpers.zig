const std = @import("std");
const c = @import("c.zig");

const constants = @import("constants.zig");
pub const PI = std.math.pi;
pub const HALF_PI = PI / 2.0;
pub const TWO_PI = PI * 2.0;
const glf = c.GLfloat;

pub const Vector2 = struct {
    const Self = @This();
    x: f32 = 0.0,
    y: f32 = 0.0,

    pub fn lerp(v1: Vector2, v2: Vector2, t: f32) Vector2 {
        return Vector2{
            .x = lerpf(v1.x, v2.x, t),
            .y = lerpf(v1.y, v2.y, t),
        };
    }

    /// We assume that v lies along the line v1-v2 (can be outside the segment)
    /// So we don't check both x and y unlerp. We just return the first one that we find.
    pub fn unlerp(v1: Vector2, v2: Vector2, v: Vector2) f32 {
        if (v1.x != v2.x) {
            return unlerpf(v1.x, v2.x, v.x);
        } else if (v1.y != v2.y) {
            return unlerpf(v1.y, v2.y, v.y);
        } else {
            return 0;
        }
    }

    pub fn ease(v1: Vector2, v2: Vector2, t: f32) Vector2 {
        return Vector2{
            .x = easeinoutf(v1.x, v2.x, t),
            .y = easeinoutf(v1.y, v2.y, t),
        };
    }

    pub fn add(v1: Vector2, v2: Vector2) Vector2 {
        return Vector2{
            .x = v1.x + v2.x,
            .y = v1.y + v2.y,
        };
    }

    pub fn added(v1: *const Vector2, v2: Vector2) Vector2 {
        return Vector2.add(v1.*, v2);
    }

    pub fn add3(v1: Vector2, v2: Vector2, v3: Vector2) Vector2 {
        return Vector2{
            .x = v1.x + v2.x + v3.x,
            .y = v1.y + v2.y + v3.y,
        };
    }

    pub fn subtract(v1: Vector2, v2: Vector2) Vector2 {
        return Vector2{
            .x = v1.x - v2.x,
            .y = v1.y - v2.y,
        };
    }

    pub fn distance(v1: Vector2, v2: Vector2) f32 {
        return @sqrt(((v2.x - v1.x) * (v2.x - v1.x)) + ((v2.y - v1.y) * (v2.y - v1.y)));
    }

    pub fn distance_sqr(v1: Vector2, v2: Vector2) f32 {
        return ((v2.x - v1.x) * (v2.x - v1.x)) + ((v2.y - v1.y) * (v2.y - v1.y));
    }

    pub fn distance_to_sqr(v1: *const Vector2, v2: Vector2) f32 {
        return ((v2.x - v1.x) * (v2.x - v1.x)) + ((v2.y - v1.y) * (v2.y - v1.y));
    }

    pub fn length(v1: Vector2) f32 {
        return @sqrt((v1.x * v1.x) + (v1.y * v1.y));
    }

    pub fn length_sqr(v1: Vector2) f32 {
        return (v1.x * v1.x) + (v1.y * v1.y);
    }

    pub fn scale(v1: Vector2, t: f32) Vector2 {
        return Vector2{
            .x = v1.x * t,
            .y = v1.y * t,
        };
    }

    pub fn scaled(v1: *const Vector2, t: f32) Vector2 {
        return Vector2{
            .x = v1.x * t,
            .y = v1.y * t,
        };
    }

    pub fn scale_anchor(v1: *const Vector2, anchor: Vector2, f: f32) Vector2 {
        const translated = Vector2.subtract(v1.*, anchor);
        return Vector2.add(anchor, Vector2.scale(translated, f));
    }

    pub fn scale_vec(v1: Vector2, v2: Vector2) Vector2 {
        return Vector2{
            .x = v1.x * v2.x,
            .y = v1.y * v2.y,
        };
    }

    pub fn negated(v1: *const Vector2) Vector2 {
        return Vector2{
            .x = -v1.x,
            .y = -v1.y,
        };
    }

    pub fn subtract_half(v1: Vector2, v2: Vector2) Vector2 {
        return Vector2{
            .x = v1.x - (0.5 * v2.x),
            .y = v1.y - (0.5 * v2.y),
        };
    }

    pub fn normalize(v1: Vector2) Vector2 {
        const l = Vector2.length(v1);
        return Vector2{
            .x = v1.x / l,
            .y = v1.y / l,
        };
    }

    /// Gives the clockwise angle in radians from first vector to second vector
    /// Assumes vectors are normalized
    pub fn angle_cw(v1: Vector2, v2: Vector2) f32 {
        std.debug.assert(!v1.is_nan());
        std.debug.assert(!v2.is_nan());
        const dot_product = std.math.clamp(Vector2.dot(v1, v2), -1, 1);
        var a = std.math.acos(dot_product);
        std.debug.assert(!is_nanf(a));
        const winding = Vector2.cross_z(v1, v2);
        std.debug.assert(!is_nanf(winding));
        if (winding < 0) a = TWO_PI - a;
        return a;
    }

    pub fn dot(v1: Vector2, v2: Vector2) f32 {
        std.debug.assert(!is_nanf(v1.x));
        std.debug.assert(!is_nanf(v1.y));
        std.debug.assert(!is_nanf(v2.x));
        std.debug.assert(!is_nanf(v2.y));
        return v1.x * v2.x + v1.y * v2.y;
    }

    /// Returns the z element of the 3d cross product of the two vectors. Useful to find the
    /// winding of the points
    pub fn cross_z(v1: Vector2, v2: Vector2) f32 {
        return (v1.x * v2.y) - (v1.y * v2.x);
    }

    pub fn equals(v1: Vector2, v2: Vector2) bool {
        return v1.x == v2.x and v1.y == v2.y;
    }

    pub fn is_equal(v1: *const Vector2, v2: Vector2) bool {
        return v1.x == v2.x and v1.y == v2.y;
    }

    pub fn reflect(v1: Vector2, surface: Vector2) Vector2 {
        // Since we're reflecting off the surface, we first need to find the component
        // of v1 that is perpendicular to the surface. We then need to "reverse" that
        // component. Or we can just subtract double the negative of that from v1.
        // TODO (25 Apr 2021 sam): See if this can be done without normalizing. @@Performance
        const n_surf = Vector2.normalize(surface);
        const v1_par = Vector2.scale(n_surf, Vector2.dot(v1, n_surf));
        const v1_perp = Vector2.subtract(v1, v1_par);
        return Vector2.subtract(v1, Vector2.scale(v1_perp, 2.0));
    }

    pub fn from_int(x: i32, y: i32) Vector2 {
        return Vector2{ .x = @intToFloat(f32, x), .y = @intToFloat(f32, y) };
    }

    pub fn from_usize(x: usize, y: usize) Vector2 {
        return Vector2{ .x = @intToFloat(f32, x), .y = @intToFloat(f32, y) };
    }

    pub fn rotate(v: Vector2, a: f32) Vector2 {
        const cosa = @cos(a);
        const sina = @sin(a);
        return Vector2{
            .x = (cosa * v.x) - (sina * v.y),
            .y = (sina * v.x) + (cosa * v.y),
        };
    }

    pub fn rotate_deg(v: Vector2, d: f32) Vector2 {
        const a = d * std.math.pi / 180.0;
        const cosa = @cos(a);
        const sina = @sin(a);
        return Vector2{
            .x = (cosa * v.x) - (sina * v.y),
            .y = (sina * v.x) + (cosa * v.y),
        };
    }

    /// If we have a line v1-v2, where v1 is 0 and v2 is 1, this function
    /// returns what value the point p has. It is assumed that p lies along
    /// the line.
    pub fn get_fraction(v1: Vector2, v2: Vector2, p: Vector2) f32 {
        const len = Vector2.distance(v1, v2);
        const p_len = Vector2.distance(v1, p);
        return p_len / len;
    }

    pub fn rotate_about_point(v1: Vector2, anchor: Vector2, a: f32) Vector2 {
        const adjusted = Vector2.subtract(v1, anchor);
        const rotated = Vector2.rotate(adjusted, a);
        return Vector2.add(anchor, rotated);
    }

    pub fn rotate_about_point_deg(v1: Vector2, anchor: Vector2, a: f32) Vector2 {
        const adjusted = Vector2.subtract(v1, anchor);
        const rotated = Vector2.rotate_deg(adjusted, a);
        return Vector2.add(anchor, rotated);
    }

    pub fn is_zero(v1: *const Vector2) bool {
        return v1.x == 0 and v1.y == 0;
    }

    pub fn is_nan(v1: *const Vector2) bool {
        return is_nanf(v1.x) or is_nanf(v1.y);
    }

    pub fn get_perp(v1: Vector2, v2: Vector2) Vector2 {
        const line = Vector2.subtract(v2, v1);
        const perp = Vector2.normalize(Vector2{ .x = line.y, .y = -line.x });
        return perp;
    }
};

pub const Vector2_gl = extern struct {
    const Self = @This();
    x: c.GLfloat = 0.0,
    y: c.GLfloat = 0.0,

    pub fn add(v1: Self, v2: Self) Self {
        return Self{
            .x = v1.x + v2.x,
            .y = v1.y + v2.y,
        };
    }

    pub fn added(v1: *const Self, v2: Self) Self {
        return Self.add(v1.*, v2);
    }

    pub fn subtract(v1: Self, v2: Self) Self {
        return Self{
            .x = v1.x - v2.x,
            .y = v1.y - v2.y,
        };
    }

    pub fn distance(v1: Self, v2: Self) glf {
        return @sqrt(((v2.x - v1.x) * (v2.x - v1.x)) + ((v2.y - v1.y) * (v2.y - v1.y)));
    }

    pub fn distance_sqr(v1: Self, v2: Self) glf {
        return ((v2.x - v1.x) * (v2.x - v1.x)) + ((v2.y - v1.y) * (v2.y - v1.y));
    }

    pub fn distance_to_sqr(v1: *const Self, v2: Self) glf {
        return ((v2.x - v1.x) * (v2.x - v1.x)) + ((v2.y - v1.y) * (v2.y - v1.y));
    }

    pub fn length(v1: Self) glf {
        return @sqrt((v1.x * v1.x) + (v1.y * v1.y));
    }

    pub fn length_sqr(v1: Self) glf {
        return (v1.x * v1.x) + (v1.y * v1.y);
    }

    pub fn scale(v1: Self, t: glf) Self {
        return Self{
            .x = v1.x * t,
            .y = v1.y * t,
        };
    }

    pub fn scaled(v1: *const Self, t: glf) Self {
        return Self{
            .x = v1.x * t,
            .y = v1.y * t,
        };
    }

    pub fn dot(v1: Self, v2: Self) glf {
        std.debug.assert(!is_nanf(v1.x));
        std.debug.assert(!is_nanf(v1.y));
        std.debug.assert(!is_nanf(v2.x));
        std.debug.assert(!is_nanf(v2.y));
        return v1.x * v2.x + v1.y * v2.y;
    }

    /// Returns the z element of the 3d cross product of the two vectors. Useful to find the
    /// winding of the points
    pub fn cross_z(v1: Self, v2: Self) glf {
        return (v1.x * v2.y) - (v1.y * v2.x);
    }

    pub fn equals(v1: Self, v2: Self) bool {
        return v1.x == v2.x and v1.y == v2.y;
    }

    pub fn normalize(v1: Vector2_gl) Vector2_gl {
        const l = Vector2_gl.length(v1);
        return Vector2_gl{
            .x = v1.x / l,
            .y = v1.y / l,
        };
    }

    pub fn normalized(v1: *const Self) Self {
        return Self.normalize(v1.*);
    }
};

pub const Camera2D = struct {
    const Self = @This();
    size_updated: bool = true,
    origin: Vector2 = .{},
    window_size: Vector2 = .{ .x = constants.DEFAULT_WINDOW_WIDTH * constants.DEFAULT_USER_WINDOW_SCALE, .y = constants.DEFAULT_WINDOW_HEIGHT * constants.DEFAULT_USER_WINDOW_SCALE },
    zoom_factor: f32 = 1.0,
    window_scale: f32 = constants.DEFAULT_USER_WINDOW_SCALE,
    // This is used to store the window scale in case the user goes full screen and wants
    // to come back to windowed.
    user_window_scale: f32 = constants.DEFAULT_USER_WINDOW_SCALE,

    pub fn world_pos_to_screen(self: *const Self, pos: Vector2) Vector2 {
        const tmp1 = Vector2.subtract(pos, self.origin);
        // TODO (20 Oct 2021 sam): Why is this zoom_factor? and not combined
        return Vector2.scale(tmp1, self.zoom_factor);
    }

    pub fn screen_pos_to_world(self: *const Self, pos: Vector2) Vector2 {
        // TODO (10 Jun 2021 sam): I wish I knew why this were the case. But I have no clue. Jiggle and
        // test method got me here for the most part.
        // pos goes from (0,0) to (x,y) where x and y are the actual screen
        // sizes. (pixel size on screen as per OS)
        // we need to map this to a rect where the 0,0 maps to origin
        // and x,y maps to origin + w/zoom*scale
        const scaled = Vector2.scale(pos, 1.0 / (self.zoom_factor * self.combined_zoom()));
        return Vector2.add(scaled, self.origin);
    }

    pub fn render_size(self: *const Self) Vector2 {
        // TODO (27 Apr 2021 sam): See whether this causes any performance issues? Is it better to store
        // as a member variable, or is it okay to calculate as a method everytime? @@Performance
        return Vector2.scale(self.window_size, 1.0 / self.combined_zoom());
    }

    pub fn combined_zoom(self: *const Self) f32 {
        return self.zoom_factor * self.window_scale;
    }

    pub fn world_size_to_screen(self: *const Self, size: Vector2) Vector2 {
        return Vector2.scale(size, self.zoom_factor);
    }

    pub fn screen_size_to_world(self: *const Self, size: Vector2) Vector2 {
        return Vector2.scale(size, 1.0 / (self.zoom_factor * self.zoom_factor));
    }

    // TODO (10 May 2021 sam): There is some confusion here when we move from screen to world. In some
    // cases, we want to maintain the positions for rendering, in which case we need the zoom_factor
    // squared. In other cases, we don't need that. This is a little confusing to me, so we need to
    // sort it all out properly.
    // (02 Jun 2021 sam): I think it has something to do with window_scale and combined_zoom as well.
    // In some cases, we want to use zoom factor, in other cases, combined_zoom, and that needs to be
    // properly understood as well.
    pub fn screen_vec_to_world(self: *const Self, size: Vector2) Vector2 {
        return Vector2.scale(size, 1.0 / self.zoom_factor);
    }

    pub fn ui_pos_to_world(self: *const Self, pos: Vector2) Vector2 {
        const scaled = Vector2.scale(pos, 1.0 / (self.zoom_factor * self.zoom_factor));
        return Vector2.add(scaled, self.origin);
    }

    pub fn world_units_to_screen(self: *const Self, unit: f32) f32 {
        return unit * self.zoom_factor;
    }

    pub fn screen_units_to_world(self: *const Self, unit: f32) f32 {
        return unit / self.zoom_factor;
    }
};

pub const Vector3_gl = extern struct {
    const Self = @This();
    x: c.GLfloat = 0.0,
    y: c.GLfloat = 0.0,
    z: c.GLfloat = 0.0,

    pub fn add(v1: Vector3_gl, v2: Vector3_gl) Self {
        return .{
            .x = v1.x + v2.x,
            .y = v1.y + v2.y,
            .z = v1.z + v2.z,
        };
    }

    pub fn subtract(v1: Vector3_gl, v2: Vector3_gl) Self {
        return .{
            .x = v1.x - v2.x,
            .y = v1.y - v2.y,
            .z = v1.z - v2.z,
        };
    }

    pub fn added(v1: *const Self, v2: Self) Self {
        return Vector3_gl.add(v1.*, v2);
    }

    pub fn subtracted(v1: *const Self, v2: Self) Self {
        return Vector3_gl.subtract(v1.*, v2);
    }

    pub fn negated(v: *const Self) Self {
        return .{ .x = -v.x, .y = -v.y, .z = -v.z };
    }

    pub fn absed(v: *const Self) Self {
        // TODO (22 Apr 2022 sam): Is this the correct interpretation of abs?
        return .{
            .x = @fabs(v.x),
            .y = @fabs(v.y),
            .z = @fabs(v.z),
        };
    }

    pub fn maxed(v: *const Self, val: c.GLfloat) Self {
        return .{
            .x = std.math.max(v.x, val),
            .y = std.math.max(v.y, val),
            .z = std.math.max(v.z, val),
        };
    }

    pub fn scaled(v: *const Self, a: c.GLfloat) Self {
        return .{ .x = v.x * a, .y = v.y * a, .z = v.z * a };
    }

    pub fn scaled_anchor(v: *const Self, a: c.GLfloat, point: Self) Self {
        // TODO (21 Apr 2022 sam): Check that these operations happen in correct order
        return v.subtracted(point).scaled(a).added(point);
    }

    pub fn scaled_vec(v: *const Self, a: Vector3_gl) Self {
        return .{ .x = v.x * a.x, .y = v.y * a.y, .z = v.z * a.z };
    }

    pub fn scaled_vec_anchor(v: *const Self, a: Vector3_gl, point: Self) Self {
        // TODO (21 Apr 2022 sam): Check that these operations happen in correct order
        return v.subtracted(point).scaled_vec(a).added(point);
    }

    pub fn divved_vec(v: *const Self, a: Vector3_gl) Self {
        return .{ .x = v.x / a.x, .y = v.y / a.y, .z = v.z / a.z };
    }

    pub fn lerp(v1: Vector3_gl, v2: Vector3_gl, t: f32) Vector3_gl {
        return Vector3_gl{
            .x = lerpf(v1.x, v2.x, t),
            .y = lerpf(v1.y, v2.y, t),
            .z = lerpf(v1.z, v2.z, t),
        };
    }

    pub fn lerped(v1: *const Vector3_gl, v2: Vector3_gl, t: f32) Vector3_gl {
        return Vector3_gl.lerp(v1.*, v2, t);
    }

    pub fn cross(v1: Vector3_gl, v2: Vector3_gl) Self {
        return .{
            .x = v1.y * v2.z - v1.z * v2.y,
            .y = v1.z * v2.x - v1.x * v2.z,
            .z = v1.x * v2.y - v1.y * v2.x,
        };
    }

    pub fn crossed(v1: *const Self, v2: Self) Self {
        return Vector3_gl.cross(v1.*, v2);
    }

    pub fn dot(v1: Vector3_gl, v2: Vector3_gl) c.GLfloat {
        return v1.x * v2.x + v1.y * v2.y + v1.z * v2.z;
    }

    pub fn dotted(v1: *const Self, v2: Self) glf {
        return Vector3_gl.dot(v1.*, v2);
    }

    pub fn normalize(v: Vector3_gl) Self {
        // TODO (21 Jan 2021 sam): See if we can use fast inverse square method here.
        const magnitude = Vector3_gl.length(v);
        return .{
            .x = v.x / magnitude,
            .y = v.y / magnitude,
            .z = v.z / magnitude,
        };
    }

    pub fn normalized(v: *const Self) Self {
        return Vector3_gl.normalize(v.*);
    }

    pub fn length(v: Vector3_gl) c.GLfloat {
        return @sqrt(Vector3_gl.length_sqr(v));
    }

    pub fn length_sqr(v: Self) c.GLfloat {
        return v.x * v.x + v.y * v.y + v.z * v.z;
    }

    pub fn is_zero(v: *const Self) bool {
        return v.x == 0 and v.y == 0 and v.z == 0;
    }

    pub fn is_one(v: *const Self) bool {
        return v.x == 1 and v.y == 1 and v.z == 1;
    }

    pub fn distance_sqr(v1: Self, v2: Self) glf {
        return Self.length_sqr(v1.subtracted(v2));
    }

    pub fn distance(v1: Self, v2: Self) glf {
        return @sqrt(Self.length_sqr(v1.subtracted(v2)));
    }

    pub fn mat3_multiply(v: Self, mat: Matrix3_gl) Self {
        return Matrix3_gl.vec3_multiply(mat, v);
    }

    /// a is in radians.
    /// axis has to be normalized.
    pub fn rotate_about_point_axis(v: Self, center: Self, axis: Self, a: c.GLfloat) Self {
        // https://en.wikipedia.org/wiki/Rotation_matrix#Rotation_matrix_from_axis_and_angle
        const cosa = @cos(a);
        const omc = 1.0 - cosa;
        const sina = @sin(a);
        const matrix = Matrix3_gl.build(cosa + (axis.x * axis.x * omc), (axis.x * axis.y * omc) - (axis.z * sina), (axis.x * axis.z * omc) + (axis.y * sina), (axis.x * axis.y * omc) + (axis.z * sina), cosa + (axis.y * axis.y * omc), (axis.y * axis.z * omc) - (axis.x * sina), (axis.x * axis.z * omc) - (axis.y * sina), (axis.z * axis.y * omc) + (axis.x * sina), cosa + (axis.z * axis.z * omc));
        const translated = v.subtracted(center);
        const rotated = Self.mat3_multiply(translated, matrix);
        return rotated.add(center);
    }

    /// a is in radians.
    /// axis has to be normalized.
    pub fn rotated_about_point_axis(v: *const Self, center: Self, axis: Self, a: c.GLfloat) Self {
        return Vector3_gl.rotate_about_point_axis(v.*, center, axis, a);
    }
};

pub const Vector4_gl = extern struct {
    const Self = @This();
    x: c.GLfloat = 0.0,
    y: c.GLfloat = 0.0,
    z: c.GLfloat = 0.0,
    w: c.GLfloat = 0.0,

    pub fn lerp(v1: Vector4_gl, v2: Vector4_gl, t: f32) Vector4_gl {
        return Vector4_gl{
            .x = lerpf(v1.x, v2.x, t),
            .y = lerpf(v1.y, v2.y, t),
            .z = lerpf(v1.z, v2.z, t),
            .w = lerpf(v1.w, v2.w, t),
        };
    }

    pub fn equals(v1: Vector4_gl, v2: Vector4_gl) bool {
        return v1.x == v2.x and v1.y == v2.y and v1.z == v2.z and v1.w == v2.w;
    }

    /// Returns black and white version of the color
    pub fn bw(v1: *const Vector4_gl) Vector4_gl {
        const col = (v1.x + v1.y + v1.z) / 3.0;
        return Vector4_gl{
            .x = col,
            .y = col,
            .z = col,
            .w = v1.w,
        };
    }

    pub fn with_alpha(v1: *const Vector4_gl, a: f32) Vector4_gl {
        return Vector4_gl{ .x = v1.x, .y = v1.y, .z = v1.z, .w = a };
    }

    pub fn is_equal_to(v1: *const Vector4_gl, v2: Vector4_gl) bool {
        return Vector4_gl.equals(v1.*, v2);
    }
};

pub const Matrix3_gl = extern struct {
    const Self = @This();
    r0: Vector3_gl = .{},
    r1: Vector3_gl = .{},
    r2: Vector3_gl = .{},

    pub fn build(r00: c.GLfloat, r01: c.GLfloat, r02: c.GLfloat, r10: c.GLfloat, r11: c.GLfloat, r12: c.GLfloat, r20: c.GLfloat, r21: c.GLfloat, r22: c.GLfloat) Self {
        return .{
            .r0 = .{ .x = r00, .y = r01, .z = r02 },
            .r1 = .{ .x = r10, .y = r11, .z = r12 },
            .r2 = .{ .x = r20, .y = r21, .z = r22 },
        };
    }

    pub fn vec3_multiply(mat: Self, v: Vector3_gl) Vector3_gl {
        return .{
            .x = v.x * mat.r0.x + v.y * mat.r1.x + v.z * mat.r2.x,
            .y = v.x * mat.r0.y + v.y * mat.r1.y + v.z * mat.r2.y,
            .z = v.x * mat.r0.z + v.y * mat.r1.z + v.z * mat.r2.z,
        };
    }

    pub fn mat3_multiply(mat1: Self, mat2: Self) Self {
        return Self.build(
            mat1.r0.x * mat2.r0.x + mat1.r0.y * mat2.r1.x + mat1.r0.z * mat2.r2.x,
            mat1.r0.x * mat2.r0.y + mat1.r0.y * mat2.r1.y + mat1.r0.z * mat2.r2.y,
            mat1.r0.x * mat2.r0.z + mat1.r0.y * mat2.r1.z + mat1.r0.z * mat2.r2.z,
            mat1.r1.x * mat2.r0.x + mat1.r1.y * mat2.r1.x + mat1.r1.z * mat2.r2.x,
            mat1.r1.x * mat2.r0.y + mat1.r1.y * mat2.r1.y + mat1.r1.z * mat2.r2.y,
            mat1.r1.x * mat2.r0.z + mat1.r1.y * mat2.r1.z + mat1.r1.z * mat2.r2.z,
            mat1.r2.x * mat2.r0.x + mat1.r2.y * mat2.r1.x + mat1.r2.z * mat2.r2.x,
            mat1.r2.x * mat2.r0.y + mat1.r2.y * mat2.r1.y + mat1.r2.z * mat2.r2.y,
            mat1.r2.x * mat2.r0.z + mat1.r2.y * mat2.r1.z + mat1.r2.z * mat2.r2.z,
        );
    }

    pub fn f_multiply(mat: Self, f: glf) Self {
        return Self.build(
            mat.r0.x * f,
            mat.r0.y * f,
            mat.r0.z * f,
            mat.r1.x * f,
            mat.r1.y * f,
            mat.r1.z * f,
            mat.r2.x * f,
            mat.r2.y * f,
            mat.r2.z * f,
        );
    }

    pub fn add(mat1: Self, mat2: Self) Self {
        return Self.build(
            mat1.r0.x + mat2.r0.x,
            mat1.r0.y + mat2.r0.y,
            mat1.r0.z + mat2.r0.z,
            mat1.r1.x + mat2.r1.x,
            mat1.r1.y + mat2.r1.y,
            mat1.r1.z + mat2.r1.z,
            mat1.r2.x + mat2.r2.x,
            mat1.r2.y + mat2.r2.y,
            mat1.r2.z + mat2.r2.z,
        );
    }

    pub fn added(mat1: *const Self, mat2: Self) Self {
        return Self.add(mat1.*, mat2);
    }

    pub fn identity() Self {
        return Matrix3_gl.build(
            1,
            0,
            0,
            0,
            1,
            0,
            0,
            0,
            1,
        );
    }
};

pub const Matrix4_gl = extern struct {
    const Self = @This();
    r0: Vector4_gl = .{},
    r1: Vector4_gl = .{},
    r2: Vector4_gl = .{},
    r3: Vector4_gl = .{},

    pub fn build(r00: c.GLfloat, r01: c.GLfloat, r02: c.GLfloat, r03: c.GLfloat, r10: c.GLfloat, r11: c.GLfloat, r12: c.GLfloat, r13: c.GLfloat, r20: c.GLfloat, r21: c.GLfloat, r22: c.GLfloat, r23: c.GLfloat, r30: c.GLfloat, r31: c.GLfloat, r32: c.GLfloat, r33: c.GLfloat) Self {
        return .{
            .r0 = .{ .x = r00, .y = r01, .z = r02, .w = r03 },
            .r1 = .{ .x = r10, .y = r11, .z = r12, .w = r13 },
            .r2 = .{ .x = r20, .y = r21, .z = r22, .w = r23 },
            .r3 = .{ .x = r30, .y = r31, .z = r32, .w = r33 },
        };
    }

    /// Returns a pointer to the first element as required by c code
    pub fn pointer(self: *const Self) *const c.GLfloat {
        return &self.r0.x;
    }

    pub fn identity() Self {
        return .{
            .r0 = .{ .x = 1.0 },
            .r1 = .{ .y = 1.0 },
            .r2 = .{ .z = 1.0 },
            .r3 = .{ .w = 1.0 },
        };
    }

    pub fn perspective_projection(angle: c.GLfloat, aspect_ratio: c.GLfloat, near: c.GLfloat, far: c.GLfloat) Self {
        // https://www.scratchapixel.com/lessons/3d-basic-rendering/perspective-and-orthographic-projection-matrix/opengl-perspective-projection-matrix
        // TODO (20 Apr 2022 sam): See if there is a zig version of tan...
        const r = @floatCast(c.GLfloat, c.SDL_tan(angle / 2.0) * near);
        const t = r / aspect_ratio;
        const n = near;
        const f = far;
        return Matrix4_gl.build(
            -n / r, // xpos is to right
            0.0,
            0.0,
            0.0,
            0.0,
            -n / t, // ypos is down
            0.0,
            0.0,
            0.0,
            0.0,
            -((f + n) / (f - n)), // zpos is to inside
            -1.0,
            0.0,
            0.0,
            -((2.0 * f * n) / (f - n)),
            0.0,
        );
    }

    pub fn look_at(eye: Vector3_gl, target: Vector3_gl, up: Vector3_gl) Self {
        const zaxis = Vector3_gl.normalize(Vector3_gl.subtract(eye, target));
        const xaxis = Vector3_gl.normalize(Vector3_gl.cross(up, zaxis));
        const yaxis = Vector3_gl.normalize(Vector3_gl.cross(zaxis, xaxis));
        const result = Matrix4_gl.build(xaxis.x, yaxis.x, zaxis.x, 0.0, xaxis.y, yaxis.y, zaxis.y, 0.0, xaxis.z, yaxis.z, zaxis.z, 0.0, -Vector3_gl.dot(xaxis, eye), -Vector3_gl.dot(yaxis, eye), -Vector3_gl.dot(zaxis, eye), 1.0);
        return result;
    }
};

pub fn lerpf(start: f32, end: f32, t: f32) f32 {
    return (start * (1.0 - t)) + (end * t);
}

pub fn unlerpf(start: f32, end: f32, t: f32) f32 {
    // TODO (09 Jun 2021 sam): This should work even if start > end
    if (end == t) return 1.0;
    return (t - start) / (end - start);
}

pub fn is_nanf(f: f32) bool {
    return f != f;
}

pub fn easeinoutf(start: f32, end: f32, t: f32) f32 {
    // Bezier Blend as per StackOverflow : https://stackoverflow.com/a/25730573/5453127
    // t goes between 0 and 1.
    const x = t * t * (3.0 - (2.0 * t));
    return start + ((end - start) * x);
}

pub const SingleInput = struct {
    is_down: bool = false,
    is_clicked: bool = false, // For one frame when key is pressed
    is_released: bool = false, // For one frame when key is released
    down_from: u32 = 0,

    pub fn reset(self: *SingleInput) void {
        self.is_clicked = false;
        self.is_released = false;
    }

    pub fn set_down(self: *SingleInput, ticks: u32) void {
        self.is_down = true;
        self.is_clicked = true;
        self.down_from = ticks;
    }

    pub fn set_release(self: *SingleInput) void {
        self.is_down = false;
        self.is_released = true;
    }
};

pub const MouseState = struct {
    const Self = @This();
    current_pos: Vector2 = .{},
    previous_pos: Vector2 = .{},
    l_down_pos: Vector2 = .{},
    r_down_pos: Vector2 = .{},
    m_down_pos: Vector2 = .{},
    l_button: SingleInput = .{},
    r_button: SingleInput = .{},
    m_button: SingleInput = .{},
    wheel_y: i32 = 0,

    pub fn reset_mouse(self: *Self) void {
        self.previous_pos = self.current_pos;
        self.l_button.reset();
        self.r_button.reset();
        self.m_button.reset();
        self.wheel_y = 0;
    }

    pub fn l_single_pos_click(self: *Self) bool {
        if (self.l_button.is_released == false) return false;
        if (self.l_down_pos.distance_to_sqr(self.current_pos) == 0) return true;
        return false;
    }

    pub fn l_moved(self: *Self) bool {
        return (self.l_down_pos.distance_to_sqr(self.current_pos) > 0);
    }

    pub fn movement(self: *Self) ?Vector2 {
        const moved = Vector2.subtract(self.previous_pos, self.current_pos);
        if (moved.x == 0 and moved.y == 0) {
            return null;
        } else {
            return moved;
        }
    }

    pub fn handle_input(self: *Self, event: c.SDL_Event, ticks: u32, camera: *Camera2D) void {
        switch (event.@"type") {
            c.SDL_MOUSEBUTTONDOWN, c.SDL_MOUSEBUTTONUP => {
                const button = switch (event.button.button) {
                    c.SDL_BUTTON_LEFT => &self.l_button,
                    c.SDL_BUTTON_RIGHT => &self.r_button,
                    c.SDL_BUTTON_MIDDLE => &self.m_button,
                    else => &self.l_button,
                };
                const pos = switch (event.button.button) {
                    c.SDL_BUTTON_LEFT => &self.l_down_pos,
                    c.SDL_BUTTON_RIGHT => &self.r_down_pos,
                    c.SDL_BUTTON_MIDDLE => &self.m_down_pos,
                    else => &self.l_down_pos,
                };
                if (event.@"type" == c.SDL_MOUSEBUTTONDOWN) {
                    // This specific line just feels a bit off. I don't intuitively get it yet.
                    pos.* = self.current_pos;
                    self.l_down_pos = self.current_pos;
                    button.is_down = true;
                    button.is_clicked = true;
                    button.down_from = ticks;
                }
                if (event.@"type" == c.SDL_MOUSEBUTTONUP) {
                    button.is_down = false;
                    button.is_released = true;
                }
            },
            c.SDL_MOUSEWHEEL => {
                self.wheel_y = event.wheel.y;
            },
            c.SDL_MOUSEMOTION => {
                self.current_pos = camera.screen_pos_to_world(Vector2.from_int(event.motion.x, event.motion.y));
            },
            else => {},
        }
    }
};

pub const EditableText = struct {
    const Self = @This();
    text: std.ArrayList(u8),
    is_active: bool = false,
    position: Vector2 = .{},
    size: Vector2 = .{ .x = 300 },
    cursor_index: usize = 0,

    pub fn init(allocator: std.mem.Allocator) Self {
        return Self{
            .text = std.ArrayList(u8).init(allocator),
        };
    }

    pub fn set_text(self: *Self, str: []const u8) void {
        self.text.shrinkRetainingCapacity(0);
        self.text.appendSlice(str) catch unreachable;
        self.cursor_index = str.len;
    }

    pub fn deinit(self: *Self) void {
        self.text.deinit();
    }

    pub fn handle_inputs(self: *Self, keys: []u8) void {
        for (keys) |k| {
            switch (k) {
                8 => {
                    if (self.cursor_index > 0) {
                        _ = self.text.orderedRemove(self.cursor_index - 1);
                        self.cursor_index -= 1;
                    }
                },
                127 => {
                    if (self.cursor_index < self.text.items.len) {
                        _ = self.text.orderedRemove(self.cursor_index);
                    }
                },
                128 => {
                    if (self.cursor_index > 0) {
                        self.cursor_index -= 1;
                    }
                },
                129 => {
                    if (self.cursor_index < self.text.items.len) {
                        self.cursor_index += 1;
                    }
                },
                else => {
                    self.text.insert(self.cursor_index, k) catch unreachable;
                    self.cursor_index += 1;
                },
            }
        }
    }
};

// We load multiple fonts into the same texture, but the API doesn't process that perfectly,
// and treats it as a smaller / narrower texture instead. So we have to wrangle the t0 and t1
// values a little bit.
pub fn tex_remap(y_in: f32, y_height: usize, y_padding: usize) f32 {
    const pixel = @floatToInt(usize, y_in * @intToFloat(f32, y_height));
    const total_height = y_height + y_padding;
    return @intToFloat(f32, pixel + y_padding) / @intToFloat(f32, total_height);
}

pub const Camera3D = struct {
    const Self = @This();
    position: Vector3_gl,
    target: Vector3_gl = .{},
    up: Vector3_gl = .{ .y = 1.0 },
    view: Matrix4_gl,
    projection: Matrix4_gl,
    near_plane: glf = 1.0,
    far_plane: glf = 5000.0,
    fov: glf = std.math.pi / 4.0,
    aspect_ratio: glf = (16.0 / 9.0),

    pub fn new() Self {
        const pos = Vector3_gl{ .z = -5.0, .x = 1.0, .y = -0.7 };
        return .{
            .position = pos,
            .view = Matrix4_gl.look_at(pos, .{}, .{ .y = 1.0 }),
            .projection = Matrix4_gl.perspective_projection(std.math.pi / 4.0, (16.0 / 9.0), 1.0, 5000),
        };
    }

    pub fn update_view(self: *Self) void {
        self.view = Matrix4_gl.look_at(self.position, self.target, .{ .y = 1.0 });
    }
};

pub const MeshVertex = struct {
    position: Vector3_gl,
    normal: Vector3_gl,
};

pub const Mesh = struct {
    const Self = @This();
    vertices: std.ArrayList(MeshVertex),
    // position and scale are internal parameters, and should not be set externally.
    // for translation and scaling, use set_position and set_scale. The final vertex
    // position data is stored directly in vertices.
    position: Vector3_gl,
    scale: Vector3_gl,
    // TODO (20 Apr 2022 sam): Technically, we can calculate model from position and scale...
    model: Matrix4_gl,
    // view: Matrix4_gl,
    // projection: Matrix4_gl,

    pub fn new(allocator: std.mem.Allocator) Self {
        var self = Self{
            .vertices = std.ArrayList(MeshVertex).init(allocator),
            .position = .{},
            .scale = .{ .x = 1.0, .y = 1.0, .z = 1.0 },
            .model = Matrix4_gl.identity(),
        };
        return self;
    }

    pub fn deinit(self: *Self) void {
        self.vertices.deinit();
    }

    pub fn set_position(self: *Self, position: Vector3_gl) void {
        const offset = position.subtracted(self.position);
        if (offset.is_zero()) return;
        self.position = position;
        for (self.vertices.items) |*vertex| {
            vertex.position = vertex.position.added(offset);
        }
    }

    pub fn set_scalef(self: *Self, scale: glf) void {
        const scale_vec = Vector3_gl{ .x = scale, .y = scale, .z = scale };
        self.set_scale(scale_vec);
    }

    pub fn set_scale(self: *Self, scale: Vector3_gl) void {
        const scale_change = scale.divved_vec(self.scale);
        if (scale_change.is_one()) return;
        self.scale = scale;
        for (self.vertices.items) |*vertex| {
            vertex.position = vertex.position.scaled_vec_anchor(scale_change, self.position);
        }
    }

    pub fn append_mesh(self: *Self, mesh: *const Mesh) void {
        self.vertices.appendSlice(mesh.vertices.items) catch unreachable;
    }

    /// returns the mesh of a cube of side 1 with center at origin.
    pub fn unit_cube(allocator: std.mem.Allocator) Self {
        var self = Mesh.new(allocator);
        const p0 = Vector3_gl{ .x = 0.5, .y = 0.5, .z = -0.5 };
        const p1 = Vector3_gl{ .x = 0.5, .y = -0.5, .z = -0.5 };
        const p2 = Vector3_gl{ .x = -0.5, .y = -0.5, .z = -0.5 };
        const p3 = Vector3_gl{ .x = -0.5, .y = 0.5, .z = -0.5 };
        const p4 = Vector3_gl{ .x = 0.5, .y = 0.5, .z = 0.5 };
        const p5 = Vector3_gl{ .x = 0.5, .y = -0.5, .z = 0.5 };
        const p6 = Vector3_gl{ .x = -0.5, .y = -0.5, .z = 0.5 };
        const p7 = Vector3_gl{ .x = -0.5, .y = 0.5, .z = 0.5 };
        const px = Vector3_gl{ .x = 1.0 };
        const py = Vector3_gl{ .y = 1.0 };
        const pz = Vector3_gl{ .z = 1.0 };
        const nx = Vector3_gl{ .x = -1.0 };
        const ny = Vector3_gl{ .y = -1.0 };
        const nz = Vector3_gl{ .z = -1.0 };
        // 0123 nz
        self.vertices.append(MeshVertex{ .position = p0, .normal = nz }) catch unreachable;
        self.vertices.append(MeshVertex{ .position = p1, .normal = nz }) catch unreachable;
        self.vertices.append(MeshVertex{ .position = p2, .normal = nz }) catch unreachable;
        self.vertices.append(MeshVertex{ .position = p0, .normal = nz }) catch unreachable;
        self.vertices.append(MeshVertex{ .position = p2, .normal = nz }) catch unreachable;
        self.vertices.append(MeshVertex{ .position = p3, .normal = nz }) catch unreachable;
        // 4765 pz
        self.vertices.append(MeshVertex{ .position = p4, .normal = pz }) catch unreachable;
        self.vertices.append(MeshVertex{ .position = p7, .normal = pz }) catch unreachable;
        self.vertices.append(MeshVertex{ .position = p6, .normal = pz }) catch unreachable;
        self.vertices.append(MeshVertex{ .position = p4, .normal = pz }) catch unreachable;
        self.vertices.append(MeshVertex{ .position = p6, .normal = pz }) catch unreachable;
        self.vertices.append(MeshVertex{ .position = p5, .normal = pz }) catch unreachable;
        // 0451 px
        self.vertices.append(MeshVertex{ .position = p0, .normal = px }) catch unreachable;
        self.vertices.append(MeshVertex{ .position = p4, .normal = px }) catch unreachable;
        self.vertices.append(MeshVertex{ .position = p5, .normal = px }) catch unreachable;
        self.vertices.append(MeshVertex{ .position = p0, .normal = px }) catch unreachable;
        self.vertices.append(MeshVertex{ .position = p5, .normal = px }) catch unreachable;
        self.vertices.append(MeshVertex{ .position = p1, .normal = px }) catch unreachable;
        // 7326 nx
        self.vertices.append(MeshVertex{ .position = p7, .normal = nx }) catch unreachable;
        self.vertices.append(MeshVertex{ .position = p3, .normal = nx }) catch unreachable;
        self.vertices.append(MeshVertex{ .position = p2, .normal = nx }) catch unreachable;
        self.vertices.append(MeshVertex{ .position = p7, .normal = nx }) catch unreachable;
        self.vertices.append(MeshVertex{ .position = p2, .normal = nx }) catch unreachable;
        self.vertices.append(MeshVertex{ .position = p6, .normal = nx }) catch unreachable;
        // 2156 ny
        self.vertices.append(MeshVertex{ .position = p2, .normal = ny }) catch unreachable;
        self.vertices.append(MeshVertex{ .position = p1, .normal = ny }) catch unreachable;
        self.vertices.append(MeshVertex{ .position = p5, .normal = ny }) catch unreachable;
        self.vertices.append(MeshVertex{ .position = p2, .normal = ny }) catch unreachable;
        self.vertices.append(MeshVertex{ .position = p5, .normal = ny }) catch unreachable;
        self.vertices.append(MeshVertex{ .position = p6, .normal = ny }) catch unreachable;
        // 7403 py
        self.vertices.append(MeshVertex{ .position = p7, .normal = py }) catch unreachable;
        self.vertices.append(MeshVertex{ .position = p4, .normal = py }) catch unreachable;
        self.vertices.append(MeshVertex{ .position = p0, .normal = py }) catch unreachable;
        self.vertices.append(MeshVertex{ .position = p7, .normal = py }) catch unreachable;
        self.vertices.append(MeshVertex{ .position = p0, .normal = py }) catch unreachable;
        self.vertices.append(MeshVertex{ .position = p3, .normal = py }) catch unreachable;
        return self;
    }
};

// checks if a value is very close to 0
pub fn sdf_check(val: glf) bool {
    return (val >= -0.01 and val <= 0.01);
}
