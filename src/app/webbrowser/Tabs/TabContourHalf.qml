/*
 * Copyright (C) 2016 Canonical Ltd
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 3 as
 * published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authored-by: Florian Boucault <florian.boucault@canonical.com>
 */
import QtQuick 2.4
import Ubuntu.Components 1.3

ShaderEffect {
    id: tabContour

    property Image source: Image {
        width: tabContour.width
        height: tabContour.height
        source: "tab_contour.png"
        fillMode: Image.Pad
        horizontalAlignment: Image.AlignLeft
        verticalAlignment: Image.AlignTop
        visible: false
        cache: true
        asynchronous: true
    }

    property color backgroundColor
    property color contourColor
    property real sourceWidth: source.paintedWidth / tabContour.width
    property real sourceHeight: source.paintedHeight / tabContour.height

    fragmentShader: "
        varying highp vec2 qt_TexCoord0;
        uniform sampler2D source;
        uniform highp vec4 backgroundColor;
        uniform highp vec4 contourColor;
        uniform lowp float qt_Opacity;
        uniform lowp float sourceWidth;
        uniform lowp float sourceHeight;
        void main() {
            lowp vec4 sourceColor = texture2D(source, vec2(qt_TexCoord0.x / sourceWidth, qt_TexCoord0.y / sourceHeight));
            lowp vec4 backgroundMix = backgroundColor * sourceColor.r;
            lowp vec4 contourMix = contourColor * sourceColor.g;
            gl_FragColor = (contourMix + backgroundMix * (1.0 - contourMix.a)) * qt_Opacity;
        }"
}
