/*
 * Copyright 2016 Canonical Ltd.
 *
 * This file is part of morph-browser.
 *
 * morph-browser is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * morph-browser is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

/**
 * Returns the color which has the most contrast with a base color.
 *
 * The contrast is based on the contrast ration found definition found here:
 * https://www.w3.org/TR/WCAG20/#contrast-ratiodef
 *
 * @param baseColor a string with format <int>,<int>,<int> corresponding to the base color
 * @param darkenedBaseColor the darker version of the base color
 * @param lightenedBaseColor the lighter version of the base color
 * @return defaultLightenColor or defaultDarkenColor depending on better contrast
 *         color string for special cases ("white", "black")
 */

function getMostConstrastedColor(
        baseColor,
        darkenedBaseColor,
        lightenedBaseColor) {
    function toLuminanceFactor(cc) {
        return (cc <= 0.03928)
                ? (cc / 12.92)
                : Math.pow(((cc + 0.055) / 1.055), 2.4)
    }
    function getRelativeLuminance(c) {
        return 0.2126 * toLuminanceFactor(c.r)
                + 0.7152 * toLuminanceFactor(c.g)
                + 0.0722 * toLuminanceFactor(c.b)
    }
    function getContrastRatio(lighterColorLuminance, darkerColorLuminance) {
        return (lighterColorLuminance + 0.05) / (darkerColorLuminance + 0.05)
    }
    var components = baseColor.split(",")

    // special case for black
    if (components[0].trim() === "0"
            && components[1].trim() === "0"
            && components[2].trim() === "0") {
        return "white"
    }
    if (components[0].trim() === "255"
            && components[1].trim() === "255"
            && components[2].trim() === "255") {
        return "black"
    }

    var color = {
        r: parseInt(components[0])/255,
        g: parseInt(components[1])/255,
        b: parseInt(components[2])/255
    }
    var CONTRAST_LIGHT_ITEM_THRESHOLD = 3.0
    if (getContrastRatio(0.0, getRelativeLuminance(color)) >= CONTRAST_LIGHT_ITEM_THRESHOLD) {
        return darkenedBaseColor
    }
    return lightenedBaseColor
}
