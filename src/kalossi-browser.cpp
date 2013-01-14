/*
 * Copyright 2013 Canonical Ltd.
 *
 * This file is part of kalossi-browser.
 *
 * kalossi-browser is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * kalossi-browser is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include <QtCore/QFileInfo>
#include <QtCore/QTextStream>
#include <QtWidgets/QApplication>
#include <QtQuick/QQuickItem>
#include <QtQuick/QQuickView>

#include <cstdio>

static void printUsage()
{
    QTextStream out(stdout);
    QString command = QFileInfo(QApplication::applicationFilePath()).fileName();
    out << "Usage: " << command << " [-h|--help] [--chromeless] [--fullscreen] [URL]" << endl;
    out << "Options:" << endl;
    out << "  -h, --help     display this help message and exit" << endl;
    out << "  --chromeless   do not display any chrome (web application mode)" << endl;
    out << "  --fullscreen   display full screen" << endl;
}

int main(int argc, char** argv)
{
    QApplication application(argc, argv);
    QQuickView view;
    view.setResizeMode(QQuickView::SizeRootObjectToView);
    view.resize(800, 600);
    view.setWindowTitle("Kalossi web browser");

    QStringList arguments = application.arguments();
    arguments.removeFirst();
    if (arguments.contains("--help") || arguments.contains("-h")) {
        printUsage();
        return 0;
    }
    bool chromeless = arguments.contains("--chromeless");
    bool fullscreen = arguments.contains("--fullscreen");
    QUrl url("http://www.ubuntu.com");
    Q_FOREACH(QString argument, arguments) {
        if (!argument.startsWith("--")) {
            url = argument;
            break;
        }
    }

    view.setSource(QUrl::fromLocalFile("src/Browser.qml"));
    QQuickItem* browser = view.rootObject();
    browser->setProperty("chromeless", chromeless);
    browser->setProperty("url", url);

    if (fullscreen) {
        view.showFullScreen();
    } else {
        view.show();
    }
    return application.exec();
}
