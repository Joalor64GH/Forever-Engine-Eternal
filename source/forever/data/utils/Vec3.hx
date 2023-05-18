package forever.data.utils;

/**
 * @author Ne_Eo
 */
abstract Vec3(Array<Float>)
{
    public var x(get, set):Float;
    public var y(get, set):Float;
    public var z(get, set):Float;

    public var r(get, set):Float;
    public var g(get, set):Float;
    public var b(get, set):Float;

    inline public function new(x:Float = 0, y:Float = 0, z:Float = 0)
    {
        this = [x, y, z];
    }

    @:op(A * B)
    public function mul(val:Float):Vec3
    {
        var s:Vec3 = copy();
        s.x *= val;
        s.y *= val;
        s.z *= val;
        return s;
    }

    @:op(A - B)
    public function sub(val:Float):Vec3
    {
        var s:Vec3 = copy();
        s.x -= val;
        s.y -= val;
        s.z -= val;
        return s;
    }

    @:op(A + B)
    public function add(val:Float):Vec3
    {
        var s:Vec3 = copy();
        s.x += val;
        s.y += val;
        s.z += val;
        return s;
    }

    @:op(A / B)
    public function div(val:Float):Vec3
    {
        var s:Vec3 = copy();
        s.x /= val;
        s.y /= val;
        s.z /= val;
        return s;
    }

    @:op(A % B)
    public function mod(val:Float):Vec3
    {
        var s:Vec3 = copy();
        s.x %= val;
        s.y %= val;
        s.z %= val;
        return s;
    }

    public function copy():Vec3
        return cast new Vec3(x, y, z);

    @:noCompletion private inline function get_x():Float
        return this[0];

    @:noCompletion private inline function set_x(v:Float):Float
        return this[0] = v;

    @:noCompletion private inline function get_y():Float
        return this[1];

    @:noCompletion private inline function set_y(v:Float):Float
        return this[1] = v;

    @:noCompletion private inline function get_z():Float
        return this[2];

    @:noCompletion private inline function set_z(v:Float):Float
        return this[2] = v;

    @:noCompletion private inline function get_r():Float
        return this[0];

    @:noCompletion private inline function set_r(v:Float):Float
        return this[0] = v;

    @:noCompletion private inline function get_g():Float
        return this[1];

    @:noCompletion private inline function set_g(v:Float):Float
        return this[1] = v;

    @:noCompletion private inline function get_b():Float
        return this[2];

    @:noCompletion private inline function set_b(v:Float):Float
        return this[2] = v;
}