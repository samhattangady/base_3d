// translated using translate-c
// stb_perlin.h - v0.5 - perlin noise
// public domain single-file C implementation by Sean Barrett
//
// LICENSE
//
//   See end of file.
//
//
// to create the implementation,
//     #define STB_PERLIN_IMPLEMENTATION
// in *one* C/CPP file that includes this file.
//
//
// Documentation:
//
// float  stb_perlin_noise3( float x,
//                           float y,
//                           float z,
//                           int   x_wrap=0,
//                           int   y_wrap=0,
//                           int   z_wrap=0)
//
// This function computes a random value at the coordinate (x,y,z).
// Adjacent random values are continuous but the noise fluctuates
// its randomness with period 1, i.e. takes on wholly unrelated values
// at integer points. Specifically, this implements Ken Perlin's
// revised noise function from 2002.
//
// The "wrap" parameters can be used to create wraparound noise that
// wraps at powers of two. The numbers MUST be powers of two. Specify
// 0 to mean "don't care". (The noise always wraps every 256 due
// details of the implementation, even if you ask for larger or no
// wrapping.)
//
// float  stb_perlin_noise3_seed( float x,
//                                float y,
//                                float z,
//                                int   x_wrap=0,
//                                int   y_wrap=0,
//                                int   z_wrap=0,
//                                int   seed)
//
// As above, but 'seed' selects from multiple different variations of the
// noise function. The current implementation only uses the bottom 8 bits
// of 'seed', but possibly in the future more bits will be used.
//
//
// Fractal Noise:
//
// Three common fractal noise functions are included, which produce
// a wide variety of nice effects depending on the parameters
// provided. Note that each function will call stb_perlin_noise3
// 'octaves' times, so this parameter will affect runtime.
//
// float stb_perlin_ridge_noise3(float x, float y, float z,
//                               float lacunarity, float gain, float offset, int octaves)
//
// float stb_perlin_fbm_noise3(float x, float y, float z,
//                             float lacunarity, float gain, int octaves)
//
// float stb_perlin_turbulence_noise3(float x, float y, float z,
//                                    float lacunarity, float gain, int octaves)
//
// Typical values to start playing with:
//     octaves    =   6     -- number of "octaves" of noise3() to sum
//     lacunarity = ~ 2.0   -- spacing between successive octaves (use exactly 2.0 for wrapping output)
//     gain       =   0.5   -- relative weighting applied to each successive octave
//     offset     =   1.0?  -- used to invert the ridges, may need to be larger, not sure
//
//
// Contributors:
//    Jack Mott - additional noise functions
//    Jordan Peck - seeded noise
//

pub const __builtin_bswap16 = @import("std").zig.c_builtins.__builtin_bswap16;
pub const __builtin_bswap32 = @import("std").zig.c_builtins.__builtin_bswap32;
pub const __builtin_bswap64 = @import("std").zig.c_builtins.__builtin_bswap64;
pub const __builtin_signbit = @import("std").zig.c_builtins.__builtin_signbit;
pub const __builtin_signbitf = @import("std").zig.c_builtins.__builtin_signbitf;
pub const __builtin_popcount = @import("std").zig.c_builtins.__builtin_popcount;
pub const __builtin_ctz = @import("std").zig.c_builtins.__builtin_ctz;
pub const __builtin_clz = @import("std").zig.c_builtins.__builtin_clz;
pub const __builtin_sqrt = @import("std").zig.c_builtins.__builtin_sqrt;
pub const __builtin_sqrtf = @import("std").zig.c_builtins.__builtin_sqrtf;
pub const __builtin_sin = @import("std").zig.c_builtins.__builtin_sin;
pub const __builtin_sinf = @import("std").zig.c_builtins.__builtin_sinf;
pub const __builtin_cos = @import("std").zig.c_builtins.__builtin_cos;
pub const __builtin_cosf = @import("std").zig.c_builtins.__builtin_cosf;
pub const __builtin_exp = @import("std").zig.c_builtins.__builtin_exp;
pub const __builtin_expf = @import("std").zig.c_builtins.__builtin_expf;
pub const __builtin_exp2 = @import("std").zig.c_builtins.__builtin_exp2;
pub const __builtin_exp2f = @import("std").zig.c_builtins.__builtin_exp2f;
pub const __builtin_log = @import("std").zig.c_builtins.__builtin_log;
pub const __builtin_logf = @import("std").zig.c_builtins.__builtin_logf;
pub const __builtin_log2 = @import("std").zig.c_builtins.__builtin_log2;
pub const __builtin_log2f = @import("std").zig.c_builtins.__builtin_log2f;
pub const __builtin_log10 = @import("std").zig.c_builtins.__builtin_log10;
pub const __builtin_log10f = @import("std").zig.c_builtins.__builtin_log10f;
pub const __builtin_abs = @import("std").zig.c_builtins.__builtin_abs;
pub const __builtin_fabs = @import("std").zig.c_builtins.__builtin_fabs;
pub const __builtin_fabsf = @import("std").zig.c_builtins.__builtin_fabsf;
pub const __builtin_floor = @import("std").zig.c_builtins.__builtin_floor;
pub const __builtin_floorf = @import("std").zig.c_builtins.__builtin_floorf;
pub const __builtin_ceil = @import("std").zig.c_builtins.__builtin_ceil;
pub const __builtin_ceilf = @import("std").zig.c_builtins.__builtin_ceilf;
pub const __builtin_trunc = @import("std").zig.c_builtins.__builtin_trunc;
pub const __builtin_truncf = @import("std").zig.c_builtins.__builtin_truncf;
pub const __builtin_round = @import("std").zig.c_builtins.__builtin_round;
pub const __builtin_roundf = @import("std").zig.c_builtins.__builtin_roundf;
pub const __builtin_strlen = @import("std").zig.c_builtins.__builtin_strlen;
pub const __builtin_strcmp = @import("std").zig.c_builtins.__builtin_strcmp;
pub const __builtin_object_size = @import("std").zig.c_builtins.__builtin_object_size;
pub const __builtin___memset_chk = @import("std").zig.c_builtins.__builtin___memset_chk;
pub const __builtin_memset = @import("std").zig.c_builtins.__builtin_memset;
pub const __builtin___memcpy_chk = @import("std").zig.c_builtins.__builtin___memcpy_chk;
pub const __builtin_memcpy = @import("std").zig.c_builtins.__builtin_memcpy;
pub const __builtin_expect = @import("std").zig.c_builtins.__builtin_expect;
pub const __builtin_nanf = @import("std").zig.c_builtins.__builtin_nanf;
pub const __builtin_huge_valf = @import("std").zig.c_builtins.__builtin_huge_valf;
pub const __builtin_inff = @import("std").zig.c_builtins.__builtin_inff;
pub const __builtin_isnan = @import("std").zig.c_builtins.__builtin_isnan;
pub const __builtin_isinf = @import("std").zig.c_builtins.__builtin_isinf;
pub const __builtin_isinf_sign = @import("std").zig.c_builtins.__builtin_isinf_sign;
pub const __has_builtin = @import("std").zig.c_builtins.__has_builtin;
pub const __builtin_assume = @import("std").zig.c_builtins.__builtin_assume;
pub const __builtin_unreachable = @import("std").zig.c_builtins.__builtin_unreachable;
pub const __builtin_constant_p = @import("std").zig.c_builtins.__builtin_constant_p;
pub const __builtin_mul_overflow = @import("std").zig.c_builtins.__builtin_mul_overflow;
pub export fn stb_perlin_noise3(arg_x: f32, arg_y: f32, arg_z: f32, arg_x_wrap: c_int, arg_y_wrap: c_int, arg_z_wrap: c_int) f32 {
    var x = arg_x;
    var y = arg_y;
    var z = arg_z;
    var x_wrap = arg_x_wrap;
    var y_wrap = arg_y_wrap;
    var z_wrap = arg_z_wrap;
    return stb_perlin_noise3_internal(x, y, z, x_wrap, y_wrap, z_wrap, @bitCast(u8, @truncate(i8, @as(c_int, 0))));
}
pub export fn stb_perlin_noise3_seed(arg_x: f32, arg_y: f32, arg_z: f32, arg_x_wrap: c_int, arg_y_wrap: c_int, arg_z_wrap: c_int, arg_seed: c_int) f32 {
    var x = arg_x;
    var y = arg_y;
    var z = arg_z;
    var x_wrap = arg_x_wrap;
    var y_wrap = arg_y_wrap;
    var z_wrap = arg_z_wrap;
    var seed = arg_seed;
    return stb_perlin_noise3_internal(x, y, z, x_wrap, y_wrap, z_wrap, @bitCast(u8, @truncate(i8, seed)));
}
pub export fn stb_perlin_ridge_noise3(arg_x: f32, arg_y: f32, arg_z: f32, arg_lacunarity: f32, arg_gain: f32, arg_offset: f32, arg_octaves: c_int) f32 {
    var x = arg_x;
    var y = arg_y;
    var z = arg_z;
    var lacunarity = arg_lacunarity;
    var gain = arg_gain;
    var offset = arg_offset;
    var octaves = arg_octaves;
    var i: c_int = undefined;
    var frequency: f32 = 1.0;
    var prev: f32 = 1.0;
    var amplitude: f32 = 0.5;
    var sum: f32 = 0.0;
    {
        i = 0;
        while (i < octaves) : (i += 1) {
            var r: f32 = stb_perlin_noise3_internal(x * frequency, y * frequency, z * frequency, @as(c_int, 0), @as(c_int, 0), @as(c_int, 0), @bitCast(u8, @truncate(i8, i)));
            r = offset - @floatCast(f32, @fabs(@floatCast(f64, r)));
            r = r * r;
            sum += (r * amplitude) * prev;
            prev = r;
            frequency *= lacunarity;
            amplitude *= gain;
        }
    }
    return sum;
}
pub export fn stb_perlin_fbm_noise3(arg_x: f32, arg_y: f32, arg_z: f32, arg_lacunarity: f32, arg_gain: f32, arg_octaves: c_int) f32 {
    var x = arg_x;
    var y = arg_y;
    var z = arg_z;
    var lacunarity = arg_lacunarity;
    var gain = arg_gain;
    var octaves = arg_octaves;
    var i: c_int = undefined;
    var frequency: f32 = 1.0;
    var amplitude: f32 = 1.0;
    var sum: f32 = 0.0;
    {
        i = 0;
        while (i < octaves) : (i += 1) {
            sum += stb_perlin_noise3_internal(x * frequency, y * frequency, z * frequency, @as(c_int, 0), @as(c_int, 0), @as(c_int, 0), @bitCast(u8, @truncate(i8, i))) * amplitude;
            frequency *= lacunarity;
            amplitude *= gain;
        }
    }
    return sum;
}
pub export fn stb_perlin_turbulence_noise3(arg_x: f32, arg_y: f32, arg_z: f32, arg_lacunarity: f32, arg_gain: f32, arg_octaves: c_int) f32 {
    var x = arg_x;
    var y = arg_y;
    var z = arg_z;
    var lacunarity = arg_lacunarity;
    var gain = arg_gain;
    var octaves = arg_octaves;
    var i: c_int = undefined;
    var frequency: f32 = 1.0;
    var amplitude: f32 = 1.0;
    var sum: f32 = 0.0;
    {
        i = 0;
        while (i < octaves) : (i += 1) {
            var r: f32 = stb_perlin_noise3_internal(x * frequency, y * frequency, z * frequency, @as(c_int, 0), @as(c_int, 0), @as(c_int, 0), @bitCast(u8, @truncate(i8, i))) * amplitude;
            sum += @floatCast(f32, @fabs(@floatCast(f64, r)));
            frequency *= lacunarity;
            amplitude *= gain;
        }
    }
    return sum;
}
pub export fn stb_perlin_noise3_wrap_nonpow2(arg_x: f32, arg_y: f32, arg_z: f32, arg_x_wrap: c_int, arg_y_wrap: c_int, arg_z_wrap: c_int, arg_seed: u8) f32 {
    var x = arg_x;
    var y = arg_y;
    var z = arg_z;
    var x_wrap = arg_x_wrap;
    var y_wrap = arg_y_wrap;
    var z_wrap = arg_z_wrap;
    var seed = arg_seed;
    var u: f32 = undefined;
    var v: f32 = undefined;
    var w: f32 = undefined;
    var n000: f32 = undefined;
    var n001: f32 = undefined;
    var n010: f32 = undefined;
    var n011: f32 = undefined;
    var n100: f32 = undefined;
    var n101: f32 = undefined;
    var n110: f32 = undefined;
    var n111: f32 = undefined;
    var n00: f32 = undefined;
    var n01: f32 = undefined;
    var n10: f32 = undefined;
    var n11: f32 = undefined;
    var n0: f32 = undefined;
    var n1: f32 = undefined;
    var px: c_int = stb__perlin_fastfloor(x);
    var py: c_int = stb__perlin_fastfloor(y);
    var pz: c_int = stb__perlin_fastfloor(z);
    var x_wrap2: c_int = if (x_wrap != 0) x_wrap else @as(c_int, 256);
    var y_wrap2: c_int = if (y_wrap != 0) y_wrap else @as(c_int, 256);
    var z_wrap2: c_int = if (z_wrap != 0) z_wrap else @as(c_int, 256);
    var x0: c_int = @import("std").zig.c_translation.signedRemainder(px, x_wrap2);
    var x1: c_int = undefined;
    var y0: c_int = @import("std").zig.c_translation.signedRemainder(py, y_wrap2);
    var y1: c_int = undefined;
    var z0: c_int = @import("std").zig.c_translation.signedRemainder(pz, z_wrap2);
    var z1: c_int = undefined;
    var r0: c_int = undefined;
    var r1: c_int = undefined;
    var r00: c_int = undefined;
    var r01: c_int = undefined;
    var r10: c_int = undefined;
    var r11: c_int = undefined;
    if (x0 < @as(c_int, 0)) {
        x0 += x_wrap2;
    }
    if (y0 < @as(c_int, 0)) {
        y0 += y_wrap2;
    }
    if (z0 < @as(c_int, 0)) {
        z0 += z_wrap2;
    }
    x1 = @import("std").zig.c_translation.signedRemainder(x0 + @as(c_int, 1), x_wrap2);
    y1 = @import("std").zig.c_translation.signedRemainder(y0 + @as(c_int, 1), y_wrap2);
    z1 = @import("std").zig.c_translation.signedRemainder(z0 + @as(c_int, 1), z_wrap2);
    x -= @intToFloat(f32, px);
    u = ((((((x * @intToFloat(f32, @as(c_int, 6))) - @intToFloat(f32, @as(c_int, 15))) * x) + @intToFloat(f32, @as(c_int, 10))) * x) * x) * x;
    y -= @intToFloat(f32, py);
    v = ((((((y * @intToFloat(f32, @as(c_int, 6))) - @intToFloat(f32, @as(c_int, 15))) * y) + @intToFloat(f32, @as(c_int, 10))) * y) * y) * y;
    z -= @intToFloat(f32, pz);
    w = ((((((z * @intToFloat(f32, @as(c_int, 6))) - @intToFloat(f32, @as(c_int, 15))) * z) + @intToFloat(f32, @as(c_int, 10))) * z) * z) * z;
    r0 = @bitCast(c_int, @as(c_uint, stb__perlin_randtab[@intCast(c_uint, x0)]));
    r0 = @bitCast(c_int, @as(c_uint, stb__perlin_randtab[@intCast(c_uint, r0 + @bitCast(c_int, @as(c_uint, seed)))]));
    r1 = @bitCast(c_int, @as(c_uint, stb__perlin_randtab[@intCast(c_uint, x1)]));
    r1 = @bitCast(c_int, @as(c_uint, stb__perlin_randtab[@intCast(c_uint, r1 + @bitCast(c_int, @as(c_uint, seed)))]));
    r00 = @bitCast(c_int, @as(c_uint, stb__perlin_randtab[@intCast(c_uint, r0 + y0)]));
    r01 = @bitCast(c_int, @as(c_uint, stb__perlin_randtab[@intCast(c_uint, r0 + y1)]));
    r10 = @bitCast(c_int, @as(c_uint, stb__perlin_randtab[@intCast(c_uint, r1 + y0)]));
    r11 = @bitCast(c_int, @as(c_uint, stb__perlin_randtab[@intCast(c_uint, r1 + y1)]));
    n000 = stb__perlin_grad(@bitCast(c_int, @as(c_uint, stb__perlin_randtab_grad_idx[@intCast(c_uint, r00 + z0)])), x, y, z);
    n001 = stb__perlin_grad(@bitCast(c_int, @as(c_uint, stb__perlin_randtab_grad_idx[@intCast(c_uint, r00 + z1)])), x, y, z - @intToFloat(f32, @as(c_int, 1)));
    n010 = stb__perlin_grad(@bitCast(c_int, @as(c_uint, stb__perlin_randtab_grad_idx[@intCast(c_uint, r01 + z0)])), x, y - @intToFloat(f32, @as(c_int, 1)), z);
    n011 = stb__perlin_grad(@bitCast(c_int, @as(c_uint, stb__perlin_randtab_grad_idx[@intCast(c_uint, r01 + z1)])), x, y - @intToFloat(f32, @as(c_int, 1)), z - @intToFloat(f32, @as(c_int, 1)));
    n100 = stb__perlin_grad(@bitCast(c_int, @as(c_uint, stb__perlin_randtab_grad_idx[@intCast(c_uint, r10 + z0)])), x - @intToFloat(f32, @as(c_int, 1)), y, z);
    n101 = stb__perlin_grad(@bitCast(c_int, @as(c_uint, stb__perlin_randtab_grad_idx[@intCast(c_uint, r10 + z1)])), x - @intToFloat(f32, @as(c_int, 1)), y, z - @intToFloat(f32, @as(c_int, 1)));
    n110 = stb__perlin_grad(@bitCast(c_int, @as(c_uint, stb__perlin_randtab_grad_idx[@intCast(c_uint, r11 + z0)])), x - @intToFloat(f32, @as(c_int, 1)), y - @intToFloat(f32, @as(c_int, 1)), z);
    n111 = stb__perlin_grad(@bitCast(c_int, @as(c_uint, stb__perlin_randtab_grad_idx[@intCast(c_uint, r11 + z1)])), x - @intToFloat(f32, @as(c_int, 1)), y - @intToFloat(f32, @as(c_int, 1)), z - @intToFloat(f32, @as(c_int, 1)));
    n00 = stb__perlin_lerp(n000, n001, w);
    n01 = stb__perlin_lerp(n010, n011, w);
    n10 = stb__perlin_lerp(n100, n101, w);
    n11 = stb__perlin_lerp(n110, n111, w);
    n0 = stb__perlin_lerp(n00, n01, v);
    n1 = stb__perlin_lerp(n10, n11, v);
    return stb__perlin_lerp(n0, n1, u);
}
pub var stb__perlin_randtab: [512]u8 = [512]u8{
    23,
    125,
    161,
    52,
    103,
    117,
    70,
    37,
    247,
    101,
    203,
    169,
    124,
    126,
    44,
    123,
    152,
    238,
    145,
    45,
    171,
    114,
    253,
    10,
    192,
    136,
    4,
    157,
    249,
    30,
    35,
    72,
    175,
    63,
    77,
    90,
    181,
    16,
    96,
    111,
    133,
    104,
    75,
    162,
    93,
    56,
    66,
    240,
    8,
    50,
    84,
    229,
    49,
    210,
    173,
    239,
    141,
    1,
    87,
    18,
    2,
    198,
    143,
    57,
    225,
    160,
    58,
    217,
    168,
    206,
    245,
    204,
    199,
    6,
    73,
    60,
    20,
    230,
    211,
    233,
    94,
    200,
    88,
    9,
    74,
    155,
    33,
    15,
    219,
    130,
    226,
    202,
    83,
    236,
    42,
    172,
    165,
    218,
    55,
    222,
    46,
    107,
    98,
    154,
    109,
    67,
    196,
    178,
    127,
    158,
    13,
    243,
    65,
    79,
    166,
    248,
    25,
    224,
    115,
    80,
    68,
    51,
    184,
    128,
    232,
    208,
    151,
    122,
    26,
    212,
    105,
    43,
    179,
    213,
    235,
    148,
    146,
    89,
    14,
    195,
    28,
    78,
    112,
    76,
    250,
    47,
    24,
    251,
    140,
    108,
    186,
    190,
    228,
    170,
    183,
    139,
    39,
    188,
    244,
    246,
    132,
    48,
    119,
    144,
    180,
    138,
    134,
    193,
    82,
    182,
    120,
    121,
    86,
    220,
    209,
    3,
    91,
    241,
    149,
    85,
    205,
    150,
    113,
    216,
    31,
    100,
    41,
    164,
    177,
    214,
    153,
    231,
    38,
    71,
    185,
    174,
    97,
    201,
    29,
    95,
    7,
    92,
    54,
    254,
    191,
    118,
    34,
    221,
    131,
    11,
    163,
    99,
    234,
    81,
    227,
    147,
    156,
    176,
    17,
    142,
    69,
    12,
    110,
    62,
    27,
    255,
    0,
    194,
    59,
    116,
    242,
    252,
    19,
    21,
    187,
    53,
    207,
    129,
    64,
    135,
    61,
    40,
    167,
    237,
    102,
    223,
    106,
    159,
    197,
    189,
    215,
    137,
    36,
    32,
    22,
    5,
    23,
    125,
    161,
    52,
    103,
    117,
    70,
    37,
    247,
    101,
    203,
    169,
    124,
    126,
    44,
    123,
    152,
    238,
    145,
    45,
    171,
    114,
    253,
    10,
    192,
    136,
    4,
    157,
    249,
    30,
    35,
    72,
    175,
    63,
    77,
    90,
    181,
    16,
    96,
    111,
    133,
    104,
    75,
    162,
    93,
    56,
    66,
    240,
    8,
    50,
    84,
    229,
    49,
    210,
    173,
    239,
    141,
    1,
    87,
    18,
    2,
    198,
    143,
    57,
    225,
    160,
    58,
    217,
    168,
    206,
    245,
    204,
    199,
    6,
    73,
    60,
    20,
    230,
    211,
    233,
    94,
    200,
    88,
    9,
    74,
    155,
    33,
    15,
    219,
    130,
    226,
    202,
    83,
    236,
    42,
    172,
    165,
    218,
    55,
    222,
    46,
    107,
    98,
    154,
    109,
    67,
    196,
    178,
    127,
    158,
    13,
    243,
    65,
    79,
    166,
    248,
    25,
    224,
    115,
    80,
    68,
    51,
    184,
    128,
    232,
    208,
    151,
    122,
    26,
    212,
    105,
    43,
    179,
    213,
    235,
    148,
    146,
    89,
    14,
    195,
    28,
    78,
    112,
    76,
    250,
    47,
    24,
    251,
    140,
    108,
    186,
    190,
    228,
    170,
    183,
    139,
    39,
    188,
    244,
    246,
    132,
    48,
    119,
    144,
    180,
    138,
    134,
    193,
    82,
    182,
    120,
    121,
    86,
    220,
    209,
    3,
    91,
    241,
    149,
    85,
    205,
    150,
    113,
    216,
    31,
    100,
    41,
    164,
    177,
    214,
    153,
    231,
    38,
    71,
    185,
    174,
    97,
    201,
    29,
    95,
    7,
    92,
    54,
    254,
    191,
    118,
    34,
    221,
    131,
    11,
    163,
    99,
    234,
    81,
    227,
    147,
    156,
    176,
    17,
    142,
    69,
    12,
    110,
    62,
    27,
    255,
    0,
    194,
    59,
    116,
    242,
    252,
    19,
    21,
    187,
    53,
    207,
    129,
    64,
    135,
    61,
    40,
    167,
    237,
    102,
    223,
    106,
    159,
    197,
    189,
    215,
    137,
    36,
    32,
    22,
    5,
};
pub var stb__perlin_randtab_grad_idx: [512]u8 = [512]u8{
    7,
    9,
    5,
    0,
    11,
    1,
    6,
    9,
    3,
    9,
    11,
    1,
    8,
    10,
    4,
    7,
    8,
    6,
    1,
    5,
    3,
    10,
    9,
    10,
    0,
    8,
    4,
    1,
    5,
    2,
    7,
    8,
    7,
    11,
    9,
    10,
    1,
    0,
    4,
    7,
    5,
    0,
    11,
    6,
    1,
    4,
    2,
    8,
    8,
    10,
    4,
    9,
    9,
    2,
    5,
    7,
    9,
    1,
    7,
    2,
    2,
    6,
    11,
    5,
    5,
    4,
    6,
    9,
    0,
    1,
    1,
    0,
    7,
    6,
    9,
    8,
    4,
    10,
    3,
    1,
    2,
    8,
    8,
    9,
    10,
    11,
    5,
    11,
    11,
    2,
    6,
    10,
    3,
    4,
    2,
    4,
    9,
    10,
    3,
    2,
    6,
    3,
    6,
    10,
    5,
    3,
    4,
    10,
    11,
    2,
    9,
    11,
    1,
    11,
    10,
    4,
    9,
    4,
    11,
    0,
    4,
    11,
    4,
    0,
    0,
    0,
    7,
    6,
    10,
    4,
    1,
    3,
    11,
    5,
    3,
    4,
    2,
    9,
    1,
    3,
    0,
    1,
    8,
    0,
    6,
    7,
    8,
    7,
    0,
    4,
    6,
    10,
    8,
    2,
    3,
    11,
    11,
    8,
    0,
    2,
    4,
    8,
    3,
    0,
    0,
    10,
    6,
    1,
    2,
    2,
    4,
    5,
    6,
    0,
    1,
    3,
    11,
    9,
    5,
    5,
    9,
    6,
    9,
    8,
    3,
    8,
    1,
    8,
    9,
    6,
    9,
    11,
    10,
    7,
    5,
    6,
    5,
    9,
    1,
    3,
    7,
    0,
    2,
    10,
    11,
    2,
    6,
    1,
    3,
    11,
    7,
    7,
    2,
    1,
    7,
    3,
    0,
    8,
    1,
    1,
    5,
    0,
    6,
    10,
    11,
    11,
    0,
    2,
    7,
    0,
    10,
    8,
    3,
    5,
    7,
    1,
    11,
    1,
    0,
    7,
    9,
    0,
    11,
    5,
    10,
    3,
    2,
    3,
    5,
    9,
    7,
    9,
    8,
    4,
    6,
    5,
    7,
    9,
    5,
    0,
    11,
    1,
    6,
    9,
    3,
    9,
    11,
    1,
    8,
    10,
    4,
    7,
    8,
    6,
    1,
    5,
    3,
    10,
    9,
    10,
    0,
    8,
    4,
    1,
    5,
    2,
    7,
    8,
    7,
    11,
    9,
    10,
    1,
    0,
    4,
    7,
    5,
    0,
    11,
    6,
    1,
    4,
    2,
    8,
    8,
    10,
    4,
    9,
    9,
    2,
    5,
    7,
    9,
    1,
    7,
    2,
    2,
    6,
    11,
    5,
    5,
    4,
    6,
    9,
    0,
    1,
    1,
    0,
    7,
    6,
    9,
    8,
    4,
    10,
    3,
    1,
    2,
    8,
    8,
    9,
    10,
    11,
    5,
    11,
    11,
    2,
    6,
    10,
    3,
    4,
    2,
    4,
    9,
    10,
    3,
    2,
    6,
    3,
    6,
    10,
    5,
    3,
    4,
    10,
    11,
    2,
    9,
    11,
    1,
    11,
    10,
    4,
    9,
    4,
    11,
    0,
    4,
    11,
    4,
    0,
    0,
    0,
    7,
    6,
    10,
    4,
    1,
    3,
    11,
    5,
    3,
    4,
    2,
    9,
    1,
    3,
    0,
    1,
    8,
    0,
    6,
    7,
    8,
    7,
    0,
    4,
    6,
    10,
    8,
    2,
    3,
    11,
    11,
    8,
    0,
    2,
    4,
    8,
    3,
    0,
    0,
    10,
    6,
    1,
    2,
    2,
    4,
    5,
    6,
    0,
    1,
    3,
    11,
    9,
    5,
    5,
    9,
    6,
    9,
    8,
    3,
    8,
    1,
    8,
    9,
    6,
    9,
    11,
    10,
    7,
    5,
    6,
    5,
    9,
    1,
    3,
    7,
    0,
    2,
    10,
    11,
    2,
    6,
    1,
    3,
    11,
    7,
    7,
    2,
    1,
    7,
    3,
    0,
    8,
    1,
    1,
    5,
    0,
    6,
    10,
    11,
    11,
    0,
    2,
    7,
    0,
    10,
    8,
    3,
    5,
    7,
    1,
    11,
    1,
    0,
    7,
    9,
    0,
    11,
    5,
    10,
    3,
    2,
    3,
    5,
    9,
    7,
    9,
    8,
    4,
    6,
    5,
};
pub fn stb__perlin_lerp(arg_a: f32, arg_b: f32, arg_t: f32) callconv(.C) f32 {
    var a = arg_a;
    var b = arg_b;
    var t = arg_t;
    return a + ((b - a) * t);
}
pub fn stb__perlin_fastfloor(arg_a: f32) callconv(.C) c_int {
    var a = arg_a;
    var ai: c_int = @floatToInt(c_int, a);
    return if (a < @intToFloat(f32, ai)) ai - @as(c_int, 1) else ai;
}
pub fn stb__perlin_grad(arg_grad_idx: c_int, arg_x: f32, arg_y: f32, arg_z: f32) callconv(.C) f32 {
    var grad_idx = arg_grad_idx;
    var x = arg_x;
    var y = arg_y;
    var z = arg_z;
    const basis = struct {
        var static: [12][4]f32 = [12][4]f32{
            [3]f32{
                1,
                1,
                0,
            } ++ [1]f32{0} ** 1,
            [3]f32{
                @intToFloat(f32, -@as(c_int, 1)),
                1,
                0,
            } ++ [1]f32{0} ** 1,
            [3]f32{
                1,
                @intToFloat(f32, -@as(c_int, 1)),
                0,
            } ++ [1]f32{0} ** 1,
            [3]f32{
                @intToFloat(f32, -@as(c_int, 1)),
                @intToFloat(f32, -@as(c_int, 1)),
                0,
            } ++ [1]f32{0} ** 1,
            [3]f32{
                1,
                0,
                1,
            } ++ [1]f32{0} ** 1,
            [3]f32{
                @intToFloat(f32, -@as(c_int, 1)),
                0,
                1,
            } ++ [1]f32{0} ** 1,
            [3]f32{
                1,
                0,
                @intToFloat(f32, -@as(c_int, 1)),
            } ++ [1]f32{0} ** 1,
            [3]f32{
                @intToFloat(f32, -@as(c_int, 1)),
                0,
                @intToFloat(f32, -@as(c_int, 1)),
            } ++ [1]f32{0} ** 1,
            [3]f32{
                0,
                1,
                1,
            } ++ [1]f32{0} ** 1,
            [3]f32{
                0,
                @intToFloat(f32, -@as(c_int, 1)),
                1,
            } ++ [1]f32{0} ** 1,
            [3]f32{
                0,
                1,
                @intToFloat(f32, -@as(c_int, 1)),
            } ++ [1]f32{0} ** 1,
            [3]f32{
                0,
                @intToFloat(f32, -@as(c_int, 1)),
                @intToFloat(f32, -@as(c_int, 1)),
            } ++ [1]f32{0} ** 1,
        };
    };
    var grad: [*c]f32 = @ptrCast([*c]f32, @alignCast(@import("std").meta.alignment(f32), &basis.static[@intCast(c_uint, grad_idx)]));
    return ((grad[@intCast(c_uint, @as(c_int, 0))] * x) + (grad[@intCast(c_uint, @as(c_int, 1))] * y)) + (grad[@intCast(c_uint, @as(c_int, 2))] * z);
}
pub export fn stb_perlin_noise3_internal(arg_x: f32, arg_y: f32, arg_z: f32, arg_x_wrap: c_int, arg_y_wrap: c_int, arg_z_wrap: c_int, arg_seed: u8) f32 {
    var x = arg_x;
    var y = arg_y;
    var z = arg_z;
    var x_wrap = arg_x_wrap;
    var y_wrap = arg_y_wrap;
    var z_wrap = arg_z_wrap;
    var seed = arg_seed;
    var u: f32 = undefined;
    var v: f32 = undefined;
    var w: f32 = undefined;
    var n000: f32 = undefined;
    var n001: f32 = undefined;
    var n010: f32 = undefined;
    var n011: f32 = undefined;
    var n100: f32 = undefined;
    var n101: f32 = undefined;
    var n110: f32 = undefined;
    var n111: f32 = undefined;
    var n00: f32 = undefined;
    var n01: f32 = undefined;
    var n10: f32 = undefined;
    var n11: f32 = undefined;
    var n0: f32 = undefined;
    var n1: f32 = undefined;
    var x_mask: c_uint = @bitCast(c_uint, (x_wrap - @as(c_int, 1)) & @as(c_int, 255));
    var y_mask: c_uint = @bitCast(c_uint, (y_wrap - @as(c_int, 1)) & @as(c_int, 255));
    var z_mask: c_uint = @bitCast(c_uint, (z_wrap - @as(c_int, 1)) & @as(c_int, 255));
    var px: c_int = stb__perlin_fastfloor(x);
    var py: c_int = stb__perlin_fastfloor(y);
    var pz: c_int = stb__perlin_fastfloor(z);
    var x0: c_int = @bitCast(c_int, @bitCast(c_uint, px) & x_mask);
    var x1: c_int = @bitCast(c_int, @bitCast(c_uint, px + @as(c_int, 1)) & x_mask);
    var y0: c_int = @bitCast(c_int, @bitCast(c_uint, py) & y_mask);
    var y1: c_int = @bitCast(c_int, @bitCast(c_uint, py + @as(c_int, 1)) & y_mask);
    var z0: c_int = @bitCast(c_int, @bitCast(c_uint, pz) & z_mask);
    var z1: c_int = @bitCast(c_int, @bitCast(c_uint, pz + @as(c_int, 1)) & z_mask);
    var r0: c_int = undefined;
    var r1: c_int = undefined;
    var r00: c_int = undefined;
    var r01: c_int = undefined;
    var r10: c_int = undefined;
    var r11: c_int = undefined;
    x -= @intToFloat(f32, px);
    u = ((((((x * @intToFloat(f32, @as(c_int, 6))) - @intToFloat(f32, @as(c_int, 15))) * x) + @intToFloat(f32, @as(c_int, 10))) * x) * x) * x;
    y -= @intToFloat(f32, py);
    v = ((((((y * @intToFloat(f32, @as(c_int, 6))) - @intToFloat(f32, @as(c_int, 15))) * y) + @intToFloat(f32, @as(c_int, 10))) * y) * y) * y;
    z -= @intToFloat(f32, pz);
    w = ((((((z * @intToFloat(f32, @as(c_int, 6))) - @intToFloat(f32, @as(c_int, 15))) * z) + @intToFloat(f32, @as(c_int, 10))) * z) * z) * z;
    r0 = @bitCast(c_int, @as(c_uint, stb__perlin_randtab[@intCast(c_uint, x0 + @bitCast(c_int, @as(c_uint, seed)))]));
    r1 = @bitCast(c_int, @as(c_uint, stb__perlin_randtab[@intCast(c_uint, x1 + @bitCast(c_int, @as(c_uint, seed)))]));
    r00 = @bitCast(c_int, @as(c_uint, stb__perlin_randtab[@intCast(c_uint, r0 + y0)]));
    r01 = @bitCast(c_int, @as(c_uint, stb__perlin_randtab[@intCast(c_uint, r0 + y1)]));
    r10 = @bitCast(c_int, @as(c_uint, stb__perlin_randtab[@intCast(c_uint, r1 + y0)]));
    r11 = @bitCast(c_int, @as(c_uint, stb__perlin_randtab[@intCast(c_uint, r1 + y1)]));
    n000 = stb__perlin_grad(@bitCast(c_int, @as(c_uint, stb__perlin_randtab_grad_idx[@intCast(c_uint, r00 + z0)])), x, y, z);
    n001 = stb__perlin_grad(@bitCast(c_int, @as(c_uint, stb__perlin_randtab_grad_idx[@intCast(c_uint, r00 + z1)])), x, y, z - @intToFloat(f32, @as(c_int, 1)));
    n010 = stb__perlin_grad(@bitCast(c_int, @as(c_uint, stb__perlin_randtab_grad_idx[@intCast(c_uint, r01 + z0)])), x, y - @intToFloat(f32, @as(c_int, 1)), z);
    n011 = stb__perlin_grad(@bitCast(c_int, @as(c_uint, stb__perlin_randtab_grad_idx[@intCast(c_uint, r01 + z1)])), x, y - @intToFloat(f32, @as(c_int, 1)), z - @intToFloat(f32, @as(c_int, 1)));
    n100 = stb__perlin_grad(@bitCast(c_int, @as(c_uint, stb__perlin_randtab_grad_idx[@intCast(c_uint, r10 + z0)])), x - @intToFloat(f32, @as(c_int, 1)), y, z);
    n101 = stb__perlin_grad(@bitCast(c_int, @as(c_uint, stb__perlin_randtab_grad_idx[@intCast(c_uint, r10 + z1)])), x - @intToFloat(f32, @as(c_int, 1)), y, z - @intToFloat(f32, @as(c_int, 1)));
    n110 = stb__perlin_grad(@bitCast(c_int, @as(c_uint, stb__perlin_randtab_grad_idx[@intCast(c_uint, r11 + z0)])), x - @intToFloat(f32, @as(c_int, 1)), y - @intToFloat(f32, @as(c_int, 1)), z);
    n111 = stb__perlin_grad(@bitCast(c_int, @as(c_uint, stb__perlin_randtab_grad_idx[@intCast(c_uint, r11 + z1)])), x - @intToFloat(f32, @as(c_int, 1)), y - @intToFloat(f32, @as(c_int, 1)), z - @intToFloat(f32, @as(c_int, 1)));
    n00 = stb__perlin_lerp(n000, n001, w);
    n01 = stb__perlin_lerp(n010, n011, w);
    n10 = stb__perlin_lerp(n100, n101, w);
    n11 = stb__perlin_lerp(n110, n111, w);
    n0 = stb__perlin_lerp(n00, n01, v);
    n1 = stb__perlin_lerp(n10, n11, v);
    return stb__perlin_lerp(n0, n1, u);
}
pub const __INTMAX_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `LL`"); // (no file):66:9
pub const __UINTMAX_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `ULL`"); // (no file):72:9
pub const __INT64_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `LL`"); // (no file):164:9
pub const __UINT32_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `U`"); // (no file):186:9
pub const __UINT64_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `ULL`"); // (no file):194:9
pub const __seg_gs = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // (no file):314:9
pub const __seg_fs = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // (no file):315:9
pub const __declspec = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // (no file):380:9
pub const _cdecl = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // (no file):381:9
pub const __cdecl = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // (no file):382:9
pub const _stdcall = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // (no file):383:9
pub const __stdcall = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // (no file):384:9
pub const _fastcall = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // (no file):385:9
pub const __fastcall = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // (no file):386:9
pub const _thiscall = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // (no file):387:9
pub const __thiscall = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // (no file):388:9
pub const _pascal = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // (no file):389:9
pub const __pascal = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // (no file):390:9
pub const __llvm__ = @as(c_int, 1);
pub const __clang__ = @as(c_int, 1);
pub const __clang_major__ = @as(c_int, 13);
pub const __clang_minor__ = @as(c_int, 0);
pub const __clang_patchlevel__ = @as(c_int, 1);
pub const __clang_version__ = "13.0.1 (git@github.com:ziglang/zig-bootstrap.git 81f0e6c5b902ead84753490db4f0007d08df964a)";
pub const __GNUC__ = @as(c_int, 4);
pub const __GNUC_MINOR__ = @as(c_int, 2);
pub const __GNUC_PATCHLEVEL__ = @as(c_int, 1);
pub const __GXX_ABI_VERSION = @as(c_int, 1002);
pub const __ATOMIC_RELAXED = @as(c_int, 0);
pub const __ATOMIC_CONSUME = @as(c_int, 1);
pub const __ATOMIC_ACQUIRE = @as(c_int, 2);
pub const __ATOMIC_RELEASE = @as(c_int, 3);
pub const __ATOMIC_ACQ_REL = @as(c_int, 4);
pub const __ATOMIC_SEQ_CST = @as(c_int, 5);
pub const __OPENCL_MEMORY_SCOPE_WORK_ITEM = @as(c_int, 0);
pub const __OPENCL_MEMORY_SCOPE_WORK_GROUP = @as(c_int, 1);
pub const __OPENCL_MEMORY_SCOPE_DEVICE = @as(c_int, 2);
pub const __OPENCL_MEMORY_SCOPE_ALL_SVM_DEVICES = @as(c_int, 3);
pub const __OPENCL_MEMORY_SCOPE_SUB_GROUP = @as(c_int, 4);
pub const __PRAGMA_REDEFINE_EXTNAME = @as(c_int, 1);
pub const __VERSION__ = "Clang 13.0.1 (git@github.com:ziglang/zig-bootstrap.git 81f0e6c5b902ead84753490db4f0007d08df964a)";
pub const __OBJC_BOOL_IS_BOOL = @as(c_int, 0);
pub const __CONSTANT_CFSTRINGS__ = @as(c_int, 1);
pub const __SEH__ = @as(c_int, 1);
pub const __clang_literal_encoding__ = "UTF-8";
pub const __clang_wide_literal_encoding__ = "UTF-16";
pub const __OPTIMIZE__ = @as(c_int, 1);
pub const __ORDER_LITTLE_ENDIAN__ = @as(c_int, 1234);
pub const __ORDER_BIG_ENDIAN__ = @as(c_int, 4321);
pub const __ORDER_PDP_ENDIAN__ = @as(c_int, 3412);
pub const __BYTE_ORDER__ = __ORDER_LITTLE_ENDIAN__;
pub const __LITTLE_ENDIAN__ = @as(c_int, 1);
pub const __CHAR_BIT__ = @as(c_int, 8);
pub const __SCHAR_MAX__ = @as(c_int, 127);
pub const __SHRT_MAX__ = @as(c_int, 32767);
pub const __INT_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __LONG_MAX__ = @as(c_long, 2147483647);
pub const __LONG_LONG_MAX__ = @as(c_longlong, 9223372036854775807);
pub const __WCHAR_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 65535, .decimal);
pub const __WINT_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 65535, .decimal);
pub const __INTMAX_MAX__ = @as(c_longlong, 9223372036854775807);
pub const __SIZE_MAX__ = @as(c_ulonglong, 18446744073709551615);
pub const __UINTMAX_MAX__ = @as(c_ulonglong, 18446744073709551615);
pub const __PTRDIFF_MAX__ = @as(c_longlong, 9223372036854775807);
pub const __INTPTR_MAX__ = @as(c_longlong, 9223372036854775807);
pub const __UINTPTR_MAX__ = @as(c_ulonglong, 18446744073709551615);
pub const __SIZEOF_DOUBLE__ = @as(c_int, 8);
pub const __SIZEOF_FLOAT__ = @as(c_int, 4);
pub const __SIZEOF_INT__ = @as(c_int, 4);
pub const __SIZEOF_LONG__ = @as(c_int, 4);
pub const __SIZEOF_LONG_DOUBLE__ = @as(c_int, 16);
pub const __SIZEOF_LONG_LONG__ = @as(c_int, 8);
pub const __SIZEOF_POINTER__ = @as(c_int, 8);
pub const __SIZEOF_SHORT__ = @as(c_int, 2);
pub const __SIZEOF_PTRDIFF_T__ = @as(c_int, 8);
pub const __SIZEOF_SIZE_T__ = @as(c_int, 8);
pub const __SIZEOF_WCHAR_T__ = @as(c_int, 2);
pub const __SIZEOF_WINT_T__ = @as(c_int, 2);
pub const __SIZEOF_INT128__ = @as(c_int, 16);
pub const __INTMAX_TYPE__ = c_longlong;
pub const __INTMAX_FMTd__ = "lld";
pub const __INTMAX_FMTi__ = "lli";
pub const __UINTMAX_TYPE__ = c_ulonglong;
pub const __UINTMAX_FMTo__ = "llo";
pub const __UINTMAX_FMTu__ = "llu";
pub const __UINTMAX_FMTx__ = "llx";
pub const __UINTMAX_FMTX__ = "llX";
pub const __INTMAX_WIDTH__ = @as(c_int, 64);
pub const __PTRDIFF_TYPE__ = c_longlong;
pub const __PTRDIFF_FMTd__ = "lld";
pub const __PTRDIFF_FMTi__ = "lli";
pub const __PTRDIFF_WIDTH__ = @as(c_int, 64);
pub const __INTPTR_TYPE__ = c_longlong;
pub const __INTPTR_FMTd__ = "lld";
pub const __INTPTR_FMTi__ = "lli";
pub const __INTPTR_WIDTH__ = @as(c_int, 64);
pub const __SIZE_TYPE__ = c_ulonglong;
pub const __SIZE_FMTo__ = "llo";
pub const __SIZE_FMTu__ = "llu";
pub const __SIZE_FMTx__ = "llx";
pub const __SIZE_FMTX__ = "llX";
pub const __SIZE_WIDTH__ = @as(c_int, 64);
pub const __WCHAR_TYPE__ = c_ushort;
pub const __WCHAR_WIDTH__ = @as(c_int, 16);
pub const __WINT_TYPE__ = c_ushort;
pub const __WINT_WIDTH__ = @as(c_int, 16);
pub const __SIG_ATOMIC_WIDTH__ = @as(c_int, 32);
pub const __SIG_ATOMIC_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __CHAR16_TYPE__ = c_ushort;
pub const __CHAR32_TYPE__ = c_uint;
pub const __UINTMAX_WIDTH__ = @as(c_int, 64);
pub const __UINTPTR_TYPE__ = c_ulonglong;
pub const __UINTPTR_FMTo__ = "llo";
pub const __UINTPTR_FMTu__ = "llu";
pub const __UINTPTR_FMTx__ = "llx";
pub const __UINTPTR_FMTX__ = "llX";
pub const __UINTPTR_WIDTH__ = @as(c_int, 64);
pub const __FLT_DENORM_MIN__ = @as(f32, 1.40129846e-45);
pub const __FLT_HAS_DENORM__ = @as(c_int, 1);
pub const __FLT_DIG__ = @as(c_int, 6);
pub const __FLT_DECIMAL_DIG__ = @as(c_int, 9);
pub const __FLT_EPSILON__ = @as(f32, 1.19209290e-7);
pub const __FLT_HAS_INFINITY__ = @as(c_int, 1);
pub const __FLT_HAS_QUIET_NAN__ = @as(c_int, 1);
pub const __FLT_MANT_DIG__ = @as(c_int, 24);
pub const __FLT_MAX_10_EXP__ = @as(c_int, 38);
pub const __FLT_MAX_EXP__ = @as(c_int, 128);
pub const __FLT_MAX__ = @as(f32, 3.40282347e+38);
pub const __FLT_MIN_10_EXP__ = -@as(c_int, 37);
pub const __FLT_MIN_EXP__ = -@as(c_int, 125);
pub const __FLT_MIN__ = @as(f32, 1.17549435e-38);
pub const __DBL_DENORM_MIN__ = 4.9406564584124654e-324;
pub const __DBL_HAS_DENORM__ = @as(c_int, 1);
pub const __DBL_DIG__ = @as(c_int, 15);
pub const __DBL_DECIMAL_DIG__ = @as(c_int, 17);
pub const __DBL_EPSILON__ = 2.2204460492503131e-16;
pub const __DBL_HAS_INFINITY__ = @as(c_int, 1);
pub const __DBL_HAS_QUIET_NAN__ = @as(c_int, 1);
pub const __DBL_MANT_DIG__ = @as(c_int, 53);
pub const __DBL_MAX_10_EXP__ = @as(c_int, 308);
pub const __DBL_MAX_EXP__ = @as(c_int, 1024);
pub const __DBL_MAX__ = 1.7976931348623157e+308;
pub const __DBL_MIN_10_EXP__ = -@as(c_int, 307);
pub const __DBL_MIN_EXP__ = -@as(c_int, 1021);
pub const __DBL_MIN__ = 2.2250738585072014e-308;
pub const __LDBL_DENORM_MIN__ = @as(c_longdouble, 3.64519953188247460253e-4951);
pub const __LDBL_HAS_DENORM__ = @as(c_int, 1);
pub const __LDBL_DIG__ = @as(c_int, 18);
pub const __LDBL_DECIMAL_DIG__ = @as(c_int, 21);
pub const __LDBL_EPSILON__ = @as(c_longdouble, 1.08420217248550443401e-19);
pub const __LDBL_HAS_INFINITY__ = @as(c_int, 1);
pub const __LDBL_HAS_QUIET_NAN__ = @as(c_int, 1);
pub const __LDBL_MANT_DIG__ = @as(c_int, 64);
pub const __LDBL_MAX_10_EXP__ = @as(c_int, 4932);
pub const __LDBL_MAX_EXP__ = @as(c_int, 16384);
pub const __LDBL_MAX__ = @as(c_longdouble, 1.18973149535723176502e+4932);
pub const __LDBL_MIN_10_EXP__ = -@as(c_int, 4931);
pub const __LDBL_MIN_EXP__ = -@as(c_int, 16381);
pub const __LDBL_MIN__ = @as(c_longdouble, 3.36210314311209350626e-4932);
pub const __POINTER_WIDTH__ = @as(c_int, 64);
pub const __BIGGEST_ALIGNMENT__ = @as(c_int, 16);
pub const __WCHAR_UNSIGNED__ = @as(c_int, 1);
pub const __WINT_UNSIGNED__ = @as(c_int, 1);
pub const __INT8_TYPE__ = i8;
pub const __INT8_FMTd__ = "hhd";
pub const __INT8_FMTi__ = "hhi";
pub const __INT8_C_SUFFIX__ = "";
pub const __INT16_TYPE__ = c_short;
pub const __INT16_FMTd__ = "hd";
pub const __INT16_FMTi__ = "hi";
pub const __INT16_C_SUFFIX__ = "";
pub const __INT32_TYPE__ = c_int;
pub const __INT32_FMTd__ = "d";
pub const __INT32_FMTi__ = "i";
pub const __INT32_C_SUFFIX__ = "";
pub const __INT64_TYPE__ = c_longlong;
pub const __INT64_FMTd__ = "lld";
pub const __INT64_FMTi__ = "lli";
pub const __UINT8_TYPE__ = u8;
pub const __UINT8_FMTo__ = "hho";
pub const __UINT8_FMTu__ = "hhu";
pub const __UINT8_FMTx__ = "hhx";
pub const __UINT8_FMTX__ = "hhX";
pub const __UINT8_C_SUFFIX__ = "";
pub const __UINT8_MAX__ = @as(c_int, 255);
pub const __INT8_MAX__ = @as(c_int, 127);
pub const __UINT16_TYPE__ = c_ushort;
pub const __UINT16_FMTo__ = "ho";
pub const __UINT16_FMTu__ = "hu";
pub const __UINT16_FMTx__ = "hx";
pub const __UINT16_FMTX__ = "hX";
pub const __UINT16_C_SUFFIX__ = "";
pub const __UINT16_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 65535, .decimal);
pub const __INT16_MAX__ = @as(c_int, 32767);
pub const __UINT32_TYPE__ = c_uint;
pub const __UINT32_FMTo__ = "o";
pub const __UINT32_FMTu__ = "u";
pub const __UINT32_FMTx__ = "x";
pub const __UINT32_FMTX__ = "X";
pub const __UINT32_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_uint, 4294967295, .decimal);
pub const __INT32_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __UINT64_TYPE__ = c_ulonglong;
pub const __UINT64_FMTo__ = "llo";
pub const __UINT64_FMTu__ = "llu";
pub const __UINT64_FMTx__ = "llx";
pub const __UINT64_FMTX__ = "llX";
pub const __UINT64_MAX__ = @as(c_ulonglong, 18446744073709551615);
pub const __INT64_MAX__ = @as(c_longlong, 9223372036854775807);
pub const __INT_LEAST8_TYPE__ = i8;
pub const __INT_LEAST8_MAX__ = @as(c_int, 127);
pub const __INT_LEAST8_FMTd__ = "hhd";
pub const __INT_LEAST8_FMTi__ = "hhi";
pub const __UINT_LEAST8_TYPE__ = u8;
pub const __UINT_LEAST8_MAX__ = @as(c_int, 255);
pub const __UINT_LEAST8_FMTo__ = "hho";
pub const __UINT_LEAST8_FMTu__ = "hhu";
pub const __UINT_LEAST8_FMTx__ = "hhx";
pub const __UINT_LEAST8_FMTX__ = "hhX";
pub const __INT_LEAST16_TYPE__ = c_short;
pub const __INT_LEAST16_MAX__ = @as(c_int, 32767);
pub const __INT_LEAST16_FMTd__ = "hd";
pub const __INT_LEAST16_FMTi__ = "hi";
pub const __UINT_LEAST16_TYPE__ = c_ushort;
pub const __UINT_LEAST16_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 65535, .decimal);
pub const __UINT_LEAST16_FMTo__ = "ho";
pub const __UINT_LEAST16_FMTu__ = "hu";
pub const __UINT_LEAST16_FMTx__ = "hx";
pub const __UINT_LEAST16_FMTX__ = "hX";
pub const __INT_LEAST32_TYPE__ = c_int;
pub const __INT_LEAST32_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __INT_LEAST32_FMTd__ = "d";
pub const __INT_LEAST32_FMTi__ = "i";
pub const __UINT_LEAST32_TYPE__ = c_uint;
pub const __UINT_LEAST32_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_uint, 4294967295, .decimal);
pub const __UINT_LEAST32_FMTo__ = "o";
pub const __UINT_LEAST32_FMTu__ = "u";
pub const __UINT_LEAST32_FMTx__ = "x";
pub const __UINT_LEAST32_FMTX__ = "X";
pub const __INT_LEAST64_TYPE__ = c_longlong;
pub const __INT_LEAST64_MAX__ = @as(c_longlong, 9223372036854775807);
pub const __INT_LEAST64_FMTd__ = "lld";
pub const __INT_LEAST64_FMTi__ = "lli";
pub const __UINT_LEAST64_TYPE__ = c_ulonglong;
pub const __UINT_LEAST64_MAX__ = @as(c_ulonglong, 18446744073709551615);
pub const __UINT_LEAST64_FMTo__ = "llo";
pub const __UINT_LEAST64_FMTu__ = "llu";
pub const __UINT_LEAST64_FMTx__ = "llx";
pub const __UINT_LEAST64_FMTX__ = "llX";
pub const __INT_FAST8_TYPE__ = i8;
pub const __INT_FAST8_MAX__ = @as(c_int, 127);
pub const __INT_FAST8_FMTd__ = "hhd";
pub const __INT_FAST8_FMTi__ = "hhi";
pub const __UINT_FAST8_TYPE__ = u8;
pub const __UINT_FAST8_MAX__ = @as(c_int, 255);
pub const __UINT_FAST8_FMTo__ = "hho";
pub const __UINT_FAST8_FMTu__ = "hhu";
pub const __UINT_FAST8_FMTx__ = "hhx";
pub const __UINT_FAST8_FMTX__ = "hhX";
pub const __INT_FAST16_TYPE__ = c_short;
pub const __INT_FAST16_MAX__ = @as(c_int, 32767);
pub const __INT_FAST16_FMTd__ = "hd";
pub const __INT_FAST16_FMTi__ = "hi";
pub const __UINT_FAST16_TYPE__ = c_ushort;
pub const __UINT_FAST16_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 65535, .decimal);
pub const __UINT_FAST16_FMTo__ = "ho";
pub const __UINT_FAST16_FMTu__ = "hu";
pub const __UINT_FAST16_FMTx__ = "hx";
pub const __UINT_FAST16_FMTX__ = "hX";
pub const __INT_FAST32_TYPE__ = c_int;
pub const __INT_FAST32_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __INT_FAST32_FMTd__ = "d";
pub const __INT_FAST32_FMTi__ = "i";
pub const __UINT_FAST32_TYPE__ = c_uint;
pub const __UINT_FAST32_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_uint, 4294967295, .decimal);
pub const __UINT_FAST32_FMTo__ = "o";
pub const __UINT_FAST32_FMTu__ = "u";
pub const __UINT_FAST32_FMTx__ = "x";
pub const __UINT_FAST32_FMTX__ = "X";
pub const __INT_FAST64_TYPE__ = c_longlong;
pub const __INT_FAST64_MAX__ = @as(c_longlong, 9223372036854775807);
pub const __INT_FAST64_FMTd__ = "lld";
pub const __INT_FAST64_FMTi__ = "lli";
pub const __UINT_FAST64_TYPE__ = c_ulonglong;
pub const __UINT_FAST64_MAX__ = @as(c_ulonglong, 18446744073709551615);
pub const __UINT_FAST64_FMTo__ = "llo";
pub const __UINT_FAST64_FMTu__ = "llu";
pub const __UINT_FAST64_FMTx__ = "llx";
pub const __UINT_FAST64_FMTX__ = "llX";
pub const __USER_LABEL_PREFIX__ = "";
pub const __FINITE_MATH_ONLY__ = @as(c_int, 0);
pub const __GNUC_STDC_INLINE__ = @as(c_int, 1);
pub const __GCC_ATOMIC_TEST_AND_SET_TRUEVAL = @as(c_int, 1);
pub const __CLANG_ATOMIC_BOOL_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_CHAR_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_CHAR16_T_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_CHAR32_T_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_WCHAR_T_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_SHORT_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_INT_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_LONG_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_LLONG_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_POINTER_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_BOOL_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_CHAR_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_CHAR16_T_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_CHAR32_T_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_WCHAR_T_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_SHORT_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_INT_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_LONG_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_LLONG_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_POINTER_LOCK_FREE = @as(c_int, 2);
pub const __PIC__ = @as(c_int, 2);
pub const __pic__ = @as(c_int, 2);
pub const __FLT_EVAL_METHOD__ = @as(c_int, 0);
pub const __FLT_RADIX__ = @as(c_int, 2);
pub const __DECIMAL_DIG__ = __LDBL_DECIMAL_DIG__;
pub const __GCC_ASM_FLAG_OUTPUTS__ = @as(c_int, 1);
pub const __code_model_small__ = @as(c_int, 1);
pub const __amd64__ = @as(c_int, 1);
pub const __amd64 = @as(c_int, 1);
pub const __x86_64 = @as(c_int, 1);
pub const __x86_64__ = @as(c_int, 1);
pub const __SEG_GS = @as(c_int, 1);
pub const __SEG_FS = @as(c_int, 1);
pub const __znver2 = @as(c_int, 1);
pub const __znver2__ = @as(c_int, 1);
pub const __tune_znver2__ = @as(c_int, 1);
pub const __REGISTER_PREFIX__ = "";
pub const __NO_MATH_INLINES = @as(c_int, 1);
pub const __AES__ = @as(c_int, 1);
pub const __PCLMUL__ = @as(c_int, 1);
pub const __LAHF_SAHF__ = @as(c_int, 1);
pub const __LZCNT__ = @as(c_int, 1);
pub const __RDRND__ = @as(c_int, 1);
pub const __FSGSBASE__ = @as(c_int, 1);
pub const __BMI__ = @as(c_int, 1);
pub const __BMI2__ = @as(c_int, 1);
pub const __POPCNT__ = @as(c_int, 1);
pub const __PRFCHW__ = @as(c_int, 1);
pub const __RDSEED__ = @as(c_int, 1);
pub const __ADX__ = @as(c_int, 1);
pub const __MWAITX__ = @as(c_int, 1);
pub const __MOVBE__ = @as(c_int, 1);
pub const __SSE4A__ = @as(c_int, 1);
pub const __FMA__ = @as(c_int, 1);
pub const __F16C__ = @as(c_int, 1);
pub const __SHA__ = @as(c_int, 1);
pub const __FXSR__ = @as(c_int, 1);
pub const __XSAVE__ = @as(c_int, 1);
pub const __XSAVEOPT__ = @as(c_int, 1);
pub const __XSAVEC__ = @as(c_int, 1);
pub const __XSAVES__ = @as(c_int, 1);
pub const __CLFLUSHOPT__ = @as(c_int, 1);
pub const __CLWB__ = @as(c_int, 1);
pub const __WBNOINVD__ = @as(c_int, 1);
pub const __CLZERO__ = @as(c_int, 1);
pub const __RDPID__ = @as(c_int, 1);
pub const __AVX2__ = @as(c_int, 1);
pub const __AVX__ = @as(c_int, 1);
pub const __SSE4_2__ = @as(c_int, 1);
pub const __SSE4_1__ = @as(c_int, 1);
pub const __SSSE3__ = @as(c_int, 1);
pub const __SSE3__ = @as(c_int, 1);
pub const __SSE2__ = @as(c_int, 1);
pub const __SSE2_MATH__ = @as(c_int, 1);
pub const __SSE__ = @as(c_int, 1);
pub const __SSE_MATH__ = @as(c_int, 1);
pub const __MMX__ = @as(c_int, 1);
pub const __GCC_HAVE_SYNC_COMPARE_AND_SWAP_1 = @as(c_int, 1);
pub const __GCC_HAVE_SYNC_COMPARE_AND_SWAP_2 = @as(c_int, 1);
pub const __GCC_HAVE_SYNC_COMPARE_AND_SWAP_4 = @as(c_int, 1);
pub const __GCC_HAVE_SYNC_COMPARE_AND_SWAP_8 = @as(c_int, 1);
pub const __GCC_HAVE_SYNC_COMPARE_AND_SWAP_16 = @as(c_int, 1);
pub const __SIZEOF_FLOAT128__ = @as(c_int, 16);
pub const _WIN32 = @as(c_int, 1);
pub const _WIN64 = @as(c_int, 1);
pub const WIN32 = @as(c_int, 1);
pub const __WIN32 = @as(c_int, 1);
pub const __WIN32__ = @as(c_int, 1);
pub const WINNT = @as(c_int, 1);
pub const __WINNT = @as(c_int, 1);
pub const __WINNT__ = @as(c_int, 1);
pub const WIN64 = @as(c_int, 1);
pub const __WIN64 = @as(c_int, 1);
pub const __WIN64__ = @as(c_int, 1);
pub const __MINGW64__ = @as(c_int, 1);
pub const __MSVCRT__ = @as(c_int, 1);
pub const __MINGW32__ = @as(c_int, 1);
pub const __STDC__ = @as(c_int, 1);
pub const __STDC_HOSTED__ = @as(c_int, 1);
pub const __STDC_VERSION__ = @as(c_long, 201710);
pub const __STDC_UTF_16__ = @as(c_int, 1);
pub const __STDC_UTF_32__ = @as(c_int, 1);
pub const _DEBUG = @as(c_int, 1);
pub inline fn stb__perlin_ease(a: anytype) @TypeOf(((((((a * @as(c_int, 6)) - @as(c_int, 15)) * a) + @as(c_int, 10)) * a) * a) * a) {
    return ((((((a * @as(c_int, 6)) - @as(c_int, 15)) * a) + @as(c_int, 10)) * a) * a) * a;
}

// ------------------------------------------------------------------------------
// This software is available under 2 licenses -- choose whichever you prefer.
// ------------------------------------------------------------------------------
// ALTERNATIVE A - MIT License
// Copyright (c) 2017 Sean Barrett
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is furnished to do
// so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
// ------------------------------------------------------------------------------
// ALTERNATIVE B - Public Domain (www.unlicense.org)
// This is free and unencumbered software released into the public domain.
// Anyone is free to copy, modify, publish, use, compile, sell, or distribute this
// software, either in source code form or as a compiled binary, for any purpose,
// commercial or non-commercial, and by any means.
// In jurisdictions that recognize copyright laws, the author or authors of this
// software dedicate any and all copyright interest in the software to the public
// domain. We make this dedication for the benefit of the public at large and to
// the detriment of our heirs and successors. We intend this dedication to be an
// overt act of relinquishment in perpetuity of all present and future rights to
// this software under copyright law.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
// ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
// WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
// ------------------------------------------------------------------------------
