/// Improved Perlin Noise from
/// https://cs.nyu.edu/~perlin/noise/
/// http://mrl.nyu.edu/~perlin/paper445.pdf
pub fn improvedPerlin(x: f64, y: f64, z: f64) f64 {
    const fx = @floor(x);
    const fy = @floor(y);
    const fz = @floor(z);

    const dx = x - fx;
    const dy = y - fy;
    const dz = z - fz;

    const permutation_mask = @intCast(u32, noise_permutation_size - 1);
    const ix = @intCast(u32, @floatToInt(i32, fx) & permutation_mask);
    const iy = @intCast(u32, @floatToInt(i32, fy) & permutation_mask);
    const iz = @intCast(u32, @floatToInt(i32, fz) & permutation_mask);

    const wx = fade(dx);
    const wy = fade(dy);
    const wz = fade(dz);

    // zig fmt: off
    const w000 = grad(ix,   iy,   iz,   dx,   dy,   dz);
    const w100 = grad(ix+1, iy,   iz,   dx-1, dy,   dz);
    const w010 = grad(ix,   iy+1, iz,   dx,   dy-1, dz);
    const w110 = grad(ix+1, iy+1, iz,   dx-1, dy-1, dz);
    const w001 = grad(ix,   iy,   iz+1, dx,   dy,   dz-1);
    const w101 = grad(ix+1, iy,   iz+1, dx-1, dy,   dz-1);
    const w011 = grad(ix,   iy+1, iz+1, dx,   dy-1, dz-1);
    const w111 = grad(ix+1, iy+1, iz+1, dx-1, dy-1, dz-1);
    // zig fmt: on

    const w00 = lerp(wx, w000, w100);
    const w10 = lerp(wx, w010, w110);
    const w01 = lerp(wx, w001, w101);
    const w11 = lerp(wx, w011, w111);

    const w0 = lerp(wy, w00, w10);
    const w1 = lerp(wy, w01, w11);

    return lerp(wz, w0, w1);
}

fn fade(v: f64) f64 {
    return v * v * v * (v * (v * 6.0 - 15.0) + 10.0);
}

fn lerp(amount: f64, v0: f64, v1: f64) f64 {
    return v0 + amount * (v1 - v0);
}

fn grad(ix: u32, iy: u32, iz: u32, x: f64, y: f64, z: f64) f64 {
    const hash = noise_permutation[noise_permutation[noise_permutation[ix] + iy] + iz];
    // zig fmt: off
    switch (hash & 15) {
        0 => return   x + y,
        1 => return  -x + y,
        2 => return   x - y,
        3 => return  -x - y,
        4 => return   x + z,
        5 => return  -x + z,
        6 => return   x - z,
        7 => return  -x - z,
        8 => return   y + z,
        9 => return  -y + z,
        10 => return  y - z,
        11 => return -y - z,
        12 => return  x + y,
        13 => return -x + y,
        14 => return -y + z,
        15 => return -y - z,
        else => unreachable,
    }
    // zig fmt: on
    unreachable;
}

// zig fmt: off
const noise_permutation = [_]u32{
    151, 160, 137, 91, 90, 15, 131, 13, 201, 95, 96, 53, 194, 233, 7, 225, 140,
    36, 103, 30, 69, 142, 8, 99, 37, 240, 21, 10, 23, 190, 6, 148, 247, 120, 234,
    75, 0, 26, 197, 62, 94, 252, 219, 203, 117, 35, 11, 32, 57, 177, 33, 88, 237,
    149, 56, 87, 174, 20, 125, 136, 171, 168, 68, 175, 74, 165, 71, 134, 139,
    48, 27, 166, 77, 146, 158, 231, 83, 111, 229, 122, 60, 211, 133, 230, 220,
    105, 92, 41, 55, 46, 245, 40, 244, 102, 143, 54, 65, 25, 63, 161, 1, 216, 80,
    73, 209, 76, 132, 187, 208, 89, 18, 169, 200, 196, 135, 130, 116, 188, 159,
    86, 164, 100, 109, 198, 173, 186, 3, 64, 52, 217, 226, 250, 124, 123, 5,
    202, 38, 147, 118, 126, 255, 82, 85, 212, 207, 206, 59, 227, 47, 16, 58, 17,
    182, 189, 28, 42, 223, 183, 170, 213, 119, 248, 152, 2, 44, 154, 163, 70,
    221, 153, 101, 155, 167, 43, 172, 9, 129, 22, 39, 253, 19, 98, 108, 110, 79,
    113, 224, 232, 178, 185, 112, 104, 218, 246, 97, 228, 251, 34, 242, 193,
    238, 210, 144, 12, 191, 179, 162, 241, 81, 51, 145, 235, 249, 14, 239, 107,
    49, 192, 214, 31, 181, 199, 106, 157, 184, 84, 204, 176, 115, 121, 50, 45,
    127, 4, 150, 254, 138, 236, 205, 93, 222, 114, 67, 29, 24, 72, 243, 141,
    128, 195, 78, 66, 215, 61, 156, 180
}**2;
// zig fmt: on
const noise_permutation_size = noise_permutation.len / 2;
