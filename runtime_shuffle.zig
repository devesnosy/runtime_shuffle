const std = @import("std");
const expect = std.testing.expect;

fn shuffle_return_type(E: type, at: type, bt: type, mt: type) type {
    const ati = @typeInfo(at);
    const bti = @typeInfo(bt);
    const mti = @typeInfo(mt);
    if (mti != .vector) @compileError("Mask must be vector");
    if (mti.vector.child != i32) @compileError("Mask child type must be i32");

    if (!(ati == .vector or bti == .vector)) @compileError("a and b must be either vector or undefined");
    if (ati == .undefined and bti == .undefined) return @Vector(mti.vector.len, E);

    const child_type = if (ati == .undefined) bti.vector.child else ati.vector.child;
    if (child_type != E) @compileError("Vector child type must equal to type passed to shuffle");
    if (ati == .vector and bti == .vector) if (ati.vector.child != bti.vector.child) @compileError("a and be must have same child type");
    return @Vector(mti.vector.len, E);
}

pub fn shuffle(comptime E: type, a: anytype, b: anytype, mask: anytype) shuffle_return_type(E, @TypeOf(a), @TypeOf(b), @TypeOf(mask)) {
    const UT = @TypeOf(undefined);
    const at = @TypeOf(a);
    const bt = @TypeOf(b);
    const mt = @TypeOf(mask);
    const rt = shuffle_return_type(E, at, bt, mt);

    if (at == UT and bt == UT) return @splat(undefined);

    const at_ = if (at == UT) bt else at;
    const bt_ = if (bt == UT) at else bt;
    const a_: at_ = if (at == UT) @splat(undefined) else a;
    const b_: bt_ = if (bt == UT) @splat(undefined) else b;

    var res: rt = undefined;
    for (0..@typeInfo(rt).vector.len) |i| {
        const index = mask[i];
        if (index < 0) {
            res[i] = b_[@intCast(~index)];
        } else {
            res[i] = a_[@intCast(index)];
        }
    }
    return res;
}

test "runtime shuffle" {
    const a = @Vector(7, u8){ 'o', 'l', 'h', 'e', 'r', 'z', 'w' };
    const b = @Vector(4, u8){ 'w', 'd', '!', 'x' };

    // To shuffle within a single vector, pass undefined as the second argument.
    // Notice that we can re-order, duplicate, or omit elements of the input vector
    const mask1 = @Vector(5, i32){ 2, 3, 1, 1, 0 };
    const res1: @Vector(5, u8) = shuffle(u8, a, undefined, mask1);
    try expect(std.mem.eql(u8, &@as([5]u8, res1), "hello"));

    // Combining two vectors
    const mask2 = @Vector(6, i32){ -1, 0, 4, 1, -2, -3 };
    const res2: @Vector(6, u8) = shuffle(u8, a, b, mask2);
    try expect(std.mem.eql(u8, &@as([6]u8, res2), "world!"));
}
