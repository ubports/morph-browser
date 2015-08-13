/*
 * Copyright 2014-2015 Canonical Ltd.
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
import Ubuntu.Components 1.3
import com.canonical.Oxide 1.0 as Oxide

Rectangle {
    property var certificateError

    signal allowed()
    signal denied()

    Connections {
        target: certificateError ? certificateError : null
        onCancelled: denied()
    }

    Flickable {
        anchors.fill: parent
        anchors.margins: units.gu(4)
        contentHeight: errorCol.height

        Column {
            id: errorCol
            anchors.centerIn: parent
            width: parent.width

            spacing: units.gu(3)

            Icon {
                anchors.horizontalCenter: parent.horizontalCenter
                name: "security-alert"
                width: units.gu(4)
                height: width
            }

            Label {
                width: parent.width
                text: certificateError ? i18n.tr("This site security certificate is not trusted.\n") + textForError(certificateError.certError) : ""
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
                fontSize: "x-small"
            }

            Label {
                width: parent.width
                text: i18n.tr("Learn more")
                font.underline: true
                fontSize: "x-small"
                horizontalAlignment: Text.AlignHCenter
                visible: !moreInfo.visible
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        moreInfo.visible = true
                    }
                }
            }

            Column {
                id: moreInfo
                width: parent.width 
                visible: false
                spacing: units.gu(1)

                Label {
                    fontSize: "x-small"
                    width: parent.width
                    wrapMode: Text.Wrap
                    // TRANSLATORS: %1 refers to the SSL certificate's serial number
                    text: i18n.tr("Serial number:\n%1").arg(certificateError ? certificateError.certificate.serialNumber : "")
                }
                Label {
                    fontSize: "x-small"
                    width: parent.width
                    wrapMode: Text.Wrap
                    // TRANSLATORS: %1 refers to the SSL certificate's subject display name
                    text: i18n.tr("Subject:\n%1").arg(certificateError ? certificateError.certificate.subjectDisplayName : "")
                }
                Label {
                    id: subjectAddress
                    fontSize: "x-small"
                    width: parent.width
                    wrapMode: Text.Wrap
                    // TRANSLATORS: %1 refers to the SSL certificate's subject's address
                    text: i18n.tr("Subject address:\n%1").arg(certificateError ?
                            (certificateError.certificate.getSubjectInfo(Oxide.SslCertificate.PrincipalAttrOrganizationName).join(", ") + "\n" +
                            certificateError.certificate.getSubjectInfo(Oxide.SslCertificate.PrincipalAttrLocalityName).join(", ") + "\n" +
                            certificateError.certificate.getSubjectInfo(Oxide.SslCertificate.PrincipalAttrStateOrProvinceName).join(", ") + "\n" + 
                            certificateError.certificate.getSubjectInfo(Oxide.SslCertificate.PrincipalAttrCountryName).join(", ")).replace(/\n+/g, "\n") : "")
                }
                Label {
                    fontSize: "x-small"
                    width: parent.width
                    wrapMode: Text.Wrap
                    // TRANSLATORS: %1 refers to the SSL certificate's issuer display name
                    text: i18n.tr("Issuer:\n%1").arg(certificateError ? certificateError.certificate.issuerDisplayName : "")
                }
                Label {
                    id: issuerAddress
                    fontSize: "x-small"
                    width: parent.width
                    wrapMode: Text.Wrap
                    // TRANSLATORS: %1 refers to the SSL certificate's issuer's address
                    text: i18n.tr("Issuer address:\n%1").arg(certificateError ?
                            (certificateError.certificate.getIssuerInfo(Oxide.SslCertificate.PrincipalAttrOrganizationName).join(", ") + "\n" +
                            certificateError.certificate.getIssuerInfo(Oxide.SslCertificate.PrincipalAttrLocalityName).join(", ") + "\n" +
                            certificateError.certificate.getIssuerInfo(Oxide.SslCertificate.PrincipalAttrStateOrProvinceName).join(", ") + "\n" +
                            certificateError.certificate.getIssuerInfo(Oxide.SslCertificate.PrincipalAttrCountryName).join(", ")).replace(/\n+/g, "\n") : "")
                }
                Label {
                    fontSize: "x-small"
                    width: parent.width
                    wrapMode: Text.Wrap
                    // TRANSLATORS: %1 refers to the SSL certificate's start date
                    text: i18n.tr("Valid from:\n%1").arg(certificateError ? certificateError.certificate.effectiveDate.toLocaleString() : "")
                }
                Label {
                    fontSize: "x-small"
                    width: parent.width
                    wrapMode: Text.Wrap
                    // TRANSLATORS: %1 refers to the SSL certificate's expiry date
                    text: i18n.tr("Valid until:\n%1").arg(certificateError ? certificateError.certificate.expiryDate.toLocaleString() : "")
                }
                Label {
                    fontSize: "x-small"
                    width: parent.width
                    wrapMode: Text.Wrap
                    // TRANSLATORS: %1 refers to the SSL certificate's SHA1 fingerprint
                    text: i18n.tr("Fingerprint (SHA1):\n%1").arg(certificateError ? certificateError.certificate.fingerprintSHA1 : "")
                }
            }

            Label {
                width: parent.width
                visible: certificateError ? certificateError.overridable : false
                text: i18n.tr("You should not proceed, especially if you have never seen this warning before for this site.")
                wrapMode: Text.Wrap
                fontSize: "x-small"
                horizontalAlignment: Text.AlignHCenter
            }

            Button {
                text: i18n.tr("Proceed anyway")
                anchors.horizontalCenter: parent.horizontalCenter
                visible: certificateError ? certificateError.overridable : false
                onClicked: {
                    certificateError.allow()
                    allowed()
                }
            }

            Button {
                id: backButton
                anchors.horizontalCenter: parent.horizontalCenter
                visible: certificateError ? certificateError.overridable : false
                text: i18n.tr("Back to safety")
                onClicked: {
                    certificateError.deny()
                    denied()
                }
                color: UbuntuColors.orange
            }
        }
    }

    function textForError(error) {
        switch(error) {
            case Oxide.CertificateError.ErrorBadIdentity:
                // TRANSLATORS: %1 refers to the domain name of the SSL certificate
                return i18n.tr("You attempted to reach %1 but the server presented a security certificate which does not match the identity of the site.").arg(certificateError ? certificateError.url : "")
            case Oxide.CertificateError.ErrorExpired:
                // TRANSLATORS: %1 refers to the domain name of the SSL certificate
                return i18n.tr("You attempted to reach %1 but the server presented a security certificate which has expired.").arg(certificateError ? certificateError.url : "")
            case Oxide.CertificateError.ErrorDateInvalid:
                // TRANSLATORS: %1 refers to the domain name of the SSL certificate
                return i18n.tr("You attempted to reach %1 but the server presented a security certificate which contains invalid dates.").arg(certificateError ? certificateError.url : "")
            case Oxide.CertificateError.ErrorAuthorityInvalid:
                // TRANSLATORS: %1 refers to the domain name of the SSL certificate
                return i18n.tr("You attempted to reach %1 but the server presented a security certificate issued by an entity that is not trusted.").arg(certificateError ? certificateError.url : "")
            case Oxide.CertificateError.ErrorRevoked:
                // TRANSLATORS: %1 refers to the domain name of the SSL certificate
                return i18n.tr("You attempted to reach %1 but the server presented a security certificate that has been revoked.").arg(certificateError ? certificateError.url : "")
            case Oxide.CertificateError.ErrorInvalid:
                // TRANSLATORS: %1 refers to the domain name of the SSL certificate
                return i18n.tr("You attempted to reach %1 but the server presented an invalid security certificate.").arg(certificateError ? certificateError.url : "")
            case Oxide.CertificateError.ErrorInsecure:
                // TRANSLATORS: %1 refers to the domain name of the SSL certificate
                return i18n.tr("You attempted to reach %1 but the server presented an insecure security certificate.").arg(certificateError ? certificateError.url : "")
            default:
                // TRANSLATORS: %1 refers to the domain name of the SSL certificate
                return i18n.tr("This site security certificate is not trusted\nYou attempted to reach %1 but the server presented a security certificate which failed our security checks for an unknown reason.").arg(certificateError ? certificateError.url : "")
        }
    }

    onVisibleChanged: {
        if (!visible) {
            moreInfo.visible = false
        }
    }
}
