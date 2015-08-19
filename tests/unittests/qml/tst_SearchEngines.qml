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

import QtQuick 2.4
import QtTest 1.0
import "../../../src/app/webbrowser"
import webbrowsertest.private 0.1
import webbrowserapp.private 0.1

Item {
    id: root

    width: 200
    height: 200

    SearchEngines {
        id: searchEngines
        readonly property int count: engines.count
    }

    SearchEngine {
        id: testEngine
        searchPaths: searchEngines.searchPaths
    }

    TestCase {
        name: "SearchEngines"

        function checkEngine(index, filename, name, description, urlTemplate) {
            compare(searchEngines.engines.get(index).filename, filename)
            testEngine.filename = filename
            compare(testEngine.name, name)
            compare(testEngine.description, description)
            compare(testEngine.urlTemplate, urlTemplate)
            testEngine.filename = ""
        }

        function test_no_engines() {
            searchEngines.searchPaths = []
            tryCompare(searchEngines, "count", 0)
        }

        function test_find_engines() {
            verify(TestContext.writeSearchEngineDescription(
                TestContext.testDir1, "engine1", "engine1", "engine1 search",
                "https://example.org/search1?q={searchTerms}"))
            verify(TestContext.writeSearchEngineDescription(
                TestContext.testDir2, "engine2", "engine2", "engine2 search",
                "https://example.org/search2?q={searchTerms}"))
            searchEngines.searchPaths = [TestContext.testDir1, TestContext.testDir2]
            tryCompare(searchEngines, "count", 2)
            checkEngine(0, "engine1", "engine1", "engine1 search",
                "https://example.org/search1?q={searchTerms}")
            checkEngine(1, "engine2", "engine2", "engine2 search",
                "https://example.org/search2?q={searchTerms}")

            // override engine2 in dir2 with another description in dir1
            verify(TestContext.writeSearchEngineDescription(
                TestContext.testDir1, "engine2",
                "engine2-overridden", "engine2-overridden search",
                "https://example.org/search2-overridden?q={searchTerms}"))
            compare(searchEngines.count, 2)
            checkEngine(1, "engine2", "engine2-overridden",
                "engine2-overridden search",
                "https://example.org/search2-overridden?q={searchTerms}")

            // reverse the order of search paths to verify that the order
            // of precedence is updated
            searchEngines.searchPaths = [TestContext.testDir2, TestContext.testDir1]
            tryCompare(searchEngines, "count", 2)
            checkEngine(0, "engine1", "engine1", "engine1 search",
                "https://example.org/search1?q={searchTerms}")
            checkEngine(1, "engine2", "engine2", "engine2 search",
                "https://example.org/search2?q={searchTerms}")

            // override engine2 with an invalid description and verify
            // that it is removed from the list
            verify(TestContext.deleteSearchEngineDescription(
                TestContext.testDir2, "engine2"))
            verify(TestContext.writeInvalidSearchEngineDescription(
                TestContext.testDir2, "engine2"))
            tryCompare(searchEngines, "count", 1)
            checkEngine(0, "engine1", "engine1", "engine1 search",
                "https://example.org/search1?q={searchTerms}")

            // remove the invalid description and verify that the other
            // description re-appears
            verify(TestContext.deleteSearchEngineDescription(
                TestContext.testDir2, "engine2"))
            tryCompare(searchEngines, "count", 2)
            checkEngine(1, "engine2", "engine2-overridden",
                "engine2-overridden search",
                "https://example.org/search2-overridden?q={searchTerms}")

            // clean up
            verify(TestContext.deleteSearchEngineDescription(
                TestContext.testDir1, "engine2"))
            verify(TestContext.deleteSearchEngineDescription(
                TestContext.testDir1, "engine1"))
        }
    }
}
