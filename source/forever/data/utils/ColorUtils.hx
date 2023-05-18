package forever.data.utils;

import flixel.math.FlxMath;

/**
 * @author Ne_Eo
 */
class ColorUtils {
    
    public static function modvf(vec:Vec3, mf:Float)
    {
        var s:Vec3 = vec.copy();
        s.x = s.x % mf;
        s.y = s.y % mf;
        s.z = s.z % mf;
        return s;
    }

    public static function modff(v1:Float, v2:Float)
        return v1 % v2;

    public static function absv(s:Vec3)
    {
        var s:Vec3 = s.copy();
        s.x = Math.abs(s.x);
        s.y = Math.abs(s.y);
        s.z = Math.abs(s.z);
        return s;
    }

    public static function clampvff(vec:Vec3, min:Float, max:Float)
    {
        var s:Vec3 = vec.copy();
        s.x = FlxMath.bound(s.x, min, max);
        s.y = FlxMath.bound(s.y, min, max);
        s.z = FlxMath.bound(s.z, min, max);
        return s;
    }

	// hsv.x = hue, hsv.y = saturation, hsv.z = value
    public static function hsvToRgb(hsv:Vec3)
    {
        var col = new Vec3(hsv.x, hsv.x + 2.0 / 3.0, hsv.x + 4.0 / 3.0); // inputs for r, g, and b
        col = clampvff(absv(modvf(col * 2.0, 2.0) - 1.0) * 3.0 - 1.0, 0.0, 1.0) * hsv.z * hsv.y + hsv.z - hsv.z * hsv.y; // hue function (graph it on desmos)
        return col;
    }

	public static function rgbToHsv(rgb:Vec3) {
		var hsv = new Vec3();
		var maxC = Math.max(Math.max(rgb.r,rgb.g),rgb.b);
		var minC = Math.min(Math.min(rgb.r,rgb.g),rgb.b);
		var delta = maxC - minC;
		if (maxC == rgb.r) hsv.x = modff((rgb.g - rgb.b)/delta, 6.0)/6.0;
		if (maxC == rgb.g) hsv.x = (rgb.b - rgb.r)/(delta*6.0) + 1.0/3.0;
		if (maxC == rgb.b) hsv.x = (rgb.r - rgb.g)/(delta*6.0) + 2.0/3.0;
		hsv.y = delta/maxC;
		hsv.z = maxC;
		return hsv;
	}

    public static function getRGBFromHSVVector(rgb:Vec3)
    {
        return flixel.util.FlxColor.fromRGBFloat(rgb.r, rgb.g, rgb.b);
    }
}