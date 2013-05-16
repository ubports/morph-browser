/*
 * Copyright 2013 Canonical Ltd.
 *
 * This file is part of webbrowser-app.
 *
 * webbrowser-app is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * webbrowser-app is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.0

ShaderEffect {
    property real minimumValue
    property real maximumValue
    property real value

    property alias source: __source.sourceItem

    property color bgColor
    property color fgColor

    anchors.fill: source

    cullMode: ShaderEffect.BackFaceCulling

    property var _source: ShaderEffectSource {
        id: __source
        hideSource: true
    }
    property real _progress: value / (maximumValue - minimumValue)

    fragmentShader: "
        varying highp vec2 qt_TexCoord0;
        uniform sampler2D _source;
        uniform highp vec4 bgColor;
        uniform highp vec4 fgColor;
        uniform lowp float qt_Opacity;
        uniform lowp float _progress;
        void main() {
            highp vec4 color = texture2D(_source, qt_TexCoord0);
            if (qt_TexCoord0.x <= _progress) {
                highp float luminance = dot(vec3(0.2126, 0.7152, 0.0722), color.rgb);
                gl_FragColor = mix(fgColor, bgColor, luminance) * color.a * qt_Opacity;
            } else {
                gl_FragColor = color * qt_Opacity;
            }
        }
    "
}
