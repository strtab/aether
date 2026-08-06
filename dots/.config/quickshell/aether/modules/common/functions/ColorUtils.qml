pragma Singleton
import Quickshell

Singleton {
    id: root

    /**
     * Returns a color with the hue of color2 and the saturation, value, and alpha of color1.
     *
     * @param {string} color1 - The base color (any Qt.color-compatible string).
     * @param {string} color2 - The color to take hue from.
     * @returns {Qt.rgba} The resulting color.
     */
    function colorWithHueOf(color1, color2) {
        var c1 = Qt.color(color1);
        var c2 = Qt.color(color2);

        // Qt.color hsvHue/hsvSaturation/hsvValue/alpha return 0-1
        var hue = c2.hsvHue;
        var sat = c1.hsvSaturation;
        var val = c1.hsvValue;
        var alpha = c1.a;

        return Qt.hsva(hue, sat, val, alpha);
    }

    /**
     * Returns a color with the saturation of color2 and the hue/value/alpha of color1.
     *
     * @param {string} color1 - The base color (any Qt.color-compatible string).
     * @param {string} color2 - The color to take saturation from.
     * @returns {Qt.rgba} The resulting color.
     */
    function colorWithSaturationOf(color1, color2) {
        var c1 = Qt.color(color1);
        var c2 = Qt.color(color2);

        var hue = c1.hsvHue;
        var sat = c2.hsvSaturation;
        var val = c1.hsvValue;
        var alpha = c1.a;

        return Qt.hsva(hue, sat, val, alpha);
    }

    /**
     * Returns a color with the given lightness and the hue, saturation, and alpha of the input color (using HSL).
     *
     * @param {string} color - The base color (any Qt.color-compatible string).
     * @param {number} lightness - The lightness value to use (0-1).
     * @returns {Qt.rgba} The resulting color.
     */
    function colorWithLightness(color, lightness) {
        var c = Qt.color(color);
        return Qt.hsla(c.hslHue, c.hslSaturation, lightness, c.a);
    }

    /**
     * Returns a color with the lightness of color2 and the hue, saturation, and alpha of color1 (using HSL).
     *
     * @param {string} color1 - The base color (any Qt.color-compatible string).
     * @param {string} color2 - The color to take lightness from.
     * @returns {Qt.rgba} The resulting color.
     */
    function colorWithLightnessOf(color1, color2) {
        var c2 = Qt.color(color2);
        return colorWithLightness(color1, c2.hslLightness);
    }

    /**
     * Adapts color1 to the accent (hue and saturation) of color2 using HSL, keeping lightness and alpha from color1.
     *
     * @param {string} color1 - The base color (any Qt.color-compatible string).
     * @param {string} color2 - The accent color.
     * @returns {Qt.rgba} The resulting color.
     */
    function adaptToAccent(color1, color2) {
        var c1 = Qt.color(color1);
        var c2 = Qt.color(color2);

        var hue = c2.hslHue;
        var sat = c2.hslSaturation;
        var light = c1.hslLightness;
        var alpha = c1.a;

        return Qt.hsla(hue, sat, light, alpha);
    }

    /**
     * Mixes two colors by a given percentage.
     *
     * @param {string} color1 - The first color (any Qt.color-compatible string).
     * @param {string} color2 - The second color.
     * @param {number} percentage - The mix ratio (0-1). 1 = all color1, 0 = all color2.
     * @returns {Qt.rgba} The resulting mixed color.
     */
    function mix(color1, color2, percentage = 0.5) {
        var c1 = Qt.color(color1);
        var c2 = Qt.color(color2);
        return Qt.rgba(percentage * c1.r + (1 - percentage) * c2.r, percentage * c1.g + (1 - percentage) * c2.g, percentage * c1.b + (1 - percentage) * c2.b, percentage * c1.a + (1 - percentage) * c2.a);
    }

    /**
     * Transparentizes a color by a given percentage.
     *
     * @param {string} color - The color (any Qt.color-compatible string).
     * @param {number} percentage - The amount to transparentize (0-1).
     * @returns {Qt.rgba} The resulting color.
     */
    function transparentize(color, percentage = 1) {
        var c = Qt.color(color);
        return Qt.rgba(c.r, c.g, c.b, c.a * (1 - percentage));
    }

    /**
     * Sets the alpha channel of a color.
     *
     * @param {string} color - The base color (any Qt.color-compatible string).
     * @param {number} alpha - The desired alpha (0-1).
     * @returns {Qt.rgba} The resulting color with applied alpha.
     */
    function applyAlpha(color, alpha) {
        var c = Qt.color(color);
        var a = Math.max(0, Math.min(1, alpha));
        return Qt.rgba(c.r, c.g, c.b, a);
    }

    /**
     * Returns true if the color is considered "dark" (hslLightness < 0.5).
     *
     * @param {string} color - The color to check (any Qt.color-compatible string).
     * @returns {boolean} True if dark, false otherwise.
     */
    function isDark(color) {
        var c = Qt.color(color);
        return c.hslLightness < 0.5;
    }

    /**
     * Returns a contrasting black-or-white color for the given input, based on HSV value (brightness).
     * Unlike HSL lightness, HSV value ignores hue entirely (it's just max(r,g,b)), so a fully
     * saturated color like pure red reads as "bright" (value = 1) the same way white does,
     * while a dark, desaturated color like navy reads as "dark" (low value).
     * This matches how the eye actually judges whether a color needs a dark or light foreground:
     * bright red -> black, dark blue -> white.
     *
     * @param {string} color - The background color to contrast against (any Qt.color-compatible string).
     * @param {string} darkColor - Color returned when the input is bright (default "black").
     * @param {string} lightColor - Color returned when the input is dark (default "white").
     * @returns {Qt.rgba} darkColor or lightColor, whichever contrasts with the input.
     */
    function adaptColor(color, darkColor = "black", lightColor = "white") {
        var c = Qt.color(color);
        // var hsp = Math.sqrt(0.299 * (c.red * c.red) + 0.587 * (c.green * c.green) + 0.114 * (c.blue * c.blue))
        return c.hsvValue > 0.5 ? Qt.color(darkColor) : Qt.color(lightColor);
    }

    /**
     * Clamps a value to the inclusive range [0, 1].
     *
     * @param {number} x - The value to clamp.
     * @returns {number} The clamped value in the range [0, 1].
     */
    function clamp01(x) {
        return Math.min(1, Math.max(0, x));
    }

    /**
     * Solves for the solid overlay color that, when composited over a base color
     * with a given opacity, yields the target color.
     *
     * The compositing equation is:
     *   result = overlay * overlayOpacity + base * (1 - overlayOpacity)
     *
     * This function algebraically inverts that equation per channel.
     *
     * @param {Qt.rgba} baseColor - The base (background) color.
     * @param {Qt.rgba} targetColor - The resulting color after compositing.
     * @param {number} overlayOpacity - The overlay opacity (0-1).
     * @returns {Qt.rgba} The solved overlay color
     */
    function solveOverlayColor(baseColor, targetColor, overlayOpacity) {
        const bc = Qt.color(baseColor);
        const tc = Qt.color(targetColor);
        let invA = 1.0 - overlayOpacity;

        let r = (tc.r - bc.r * invA) / overlayOpacity;
        let g = (tc.g - bc.g * invA) / overlayOpacity;
        let b = (tc.b - bc.b * invA) / overlayOpacity;

        return Qt.rgba(clamp01(r), clamp01(g), clamp01(b), overlayOpacity);
    }
}
