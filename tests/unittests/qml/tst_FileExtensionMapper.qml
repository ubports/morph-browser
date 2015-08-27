/*
 * Copyright 2015 Canonical Ltd.
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

import QtTest 1.0
import "../../../src/app/FileExtensionMapper.js" as FileExtensionMapper

TestCase {
    name: "FileExtensionMapper"

    function test_getExtension_data() {
        return [
            {in: "", ext: ""},
            {in: "pdf", ext: ""},
            {in: ".vimrc", ext: ""},
            {in: "example.pdf", ext: "pdf"},
            {in: "http://example.org/path/example.pdf", ext: "pdf"},
            {in: "EXAMPLE.PDF", ext: "pdf"}
        ]
    }

    function test_getExtension(data) {
        compare(FileExtensionMapper.getExtension(data.in), data.ext)
    }
}
