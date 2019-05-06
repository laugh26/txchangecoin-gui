// Copyright (c) 2014-2019, The Monero Project
// 
// All rights reserved.
// 
// Redistribution and use in source and binary forms, with or without modification, are
// permitted provided that the following conditions are met:
// 
// 1. Redistributions of source code must retain the above copyright notice, this list of
//    conditions and the following disclaimer.
// 
// 2. Redistributions in binary form must reproduce the above copyright notice, this list
//    of conditions and the following disclaimer in the documentation and/or other
//    materials provided with the distribution.
// 
// 3. Neither the name of the copyright holder nor the names of its contributors may be
//    used to endorse or promote products derived from this software without specific
//    prior written permission.
// 
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
// EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
// MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL
// THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
// PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
// STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
// THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import QtQuick 2.9
import moneroComponents.Clipboard 1.0
import moneroComponents.AddressBookModel 1.0

import "../components" as MoneroComponents
import "../js/TxUtils.js" as TxUtils

ListView {
    id: listView
    clip: true
    boundsBehavior: ListView.StopAtBounds
    property var previousItem
    property int rowSpacing: 12
    property var addressBookModel: null

    function buildTxDetailsString(tx_id, paymentId, tx_key,tx_note, destinations, rings, address, address_label) {
        var trStart = '<tr><td width="85" style="padding-top:5px"><b>',
            trMiddle = '</b></td><td style="padding-left:10px;padding-top:5px;">',
            trEnd = "</td></tr>";

        return '<table border="0">'
            + (tx_id ? trStart + qsTr("Tx ID:") + trMiddle + tx_id + trEnd : "")
            + (address_label ? trStart + qsTr("Address label:") + trMiddle + address_label + trEnd : "")
            + (address ? trStart + qsTr("Address:") + trMiddle + address + trEnd : "")
            + (paymentId ? trStart + qsTr("Payment ID:") + trMiddle + paymentId + trEnd : "")
            + (tx_key ? trStart + qsTr("Tx key:") + trMiddle + tx_key + trEnd : "")
            + (tx_note ? trStart + qsTr("Tx note:") + trMiddle + tx_note + trEnd : "")
            + (destinations ? trStart + qsTr("Destinations:") + trMiddle + destinations + trEnd : "")
            + (rings ? trStart + qsTr("Rings:") + trMiddle + rings + trEnd : "")
            + "</table>"
            + translationManager.emptyString;
    }

    function lookupPaymentID(paymentId) {
        if (!addressBookModel)
            return ""
        var idx = addressBookModel.lookupPaymentID(paymentId)
        if (idx < 0)
            return ""
        idx = addressBookModel.index(idx, 0)
        return addressBookModel.data(idx, AddressBookModel.AddressBookDescriptionRole)
    }

    footer: Rectangle {
        height: 127
        width: listView.width
        color: "transparent"

        MoneroComponents.TextPlain {
            anchors.centerIn: parent
            font.family: "Arial"
            font.pixelSize: 14
            color: "#545454"
            text: qsTr("No more results") + translationManager.emptyString
        }
    }

    delegate: Rectangle {
        id: delegate
        property bool collapsed: index ? false : true
        height: collapsed ? 180 : 70
        width: listView.width
        color: "transparent"

        function collapse(){
            delegate.height = 180;
        }

        // borders
        Rectangle{
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 1
            color: "#404040"
        }

        Rectangle{
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: collapsed ? 2 : 1
            color: collapsed ? "#BBBBBB" : "#404040"
        }

        Rectangle{
            anchors.right: parent.right
            anchors.bottom: parent.top
            anchors.left: parent.left
            height: 1
            color: "#404040"
        }

        Rectangle{
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            height: 1
            color: "#404040"
        }

        Rectangle {
            id: row1
            anchors.left: parent.left
            anchors.leftMargin: 20
            anchors.right: parent.right
            anchors.rightMargin: 20
            anchors.top: parent.top
            anchors.topMargin: 15
            height: 40
            color: "transparent"

            Image {
                id: arrowImage
                source: isOut ? "qrc:///images/downArrow.png" : confirmationsRequired === 60  ? "qrc:///images/miningxmr.png" : "qrc:///images/upArrow-green.png"
                height: 18
                width: (confirmationsRequired === 60  ? 18 : 12)
                anchors.top: parent.top
                anchors.topMargin: 12
            }

            MoneroComponents.TextPlain {
                id: txrxLabel
                anchors.left: arrowImage.right
                anchors.leftMargin: 18
                font.family: MoneroComponents.Style.fontLight.name
                font.pixelSize: 14
                text: isOut ? qsTr("Sent") + translationManager.emptyString : qsTr("Received") + translationManager.emptyString
                color: "#808080"
            }

            MoneroComponents.TextPlain {
                id: amountLabel
                anchors.left: arrowImage.right
                anchors.leftMargin: 18
                anchors.top: txrxLabel.bottom
                anchors.topMargin: 0
                font.family: MoneroComponents.Style.fontBold.name
                font.pixelSize: 18
                font.bold: true
                text: {
                    var _amount = amount;
                    if(_amount === 0){
                        // *sometimes* amount is 0, while the 'destinations string' 
                        // has the correct amount, so we try to fetch it from that instead.
                        _amount = TxUtils.destinationsToAmount(destinations);
                        _amount = (_amount *1);
                    }

                    return _amount + " TXX";
                }
                color: isOut ? MoneroComponents.Style.white : MoneroComponents.Style.green

                MouseArea {
                        hoverEnabled: true
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onEntered: {
                            parent.color = MoneroComponents.Style.orange
                        }
                        onExited: {
                            parent.color = isOut ? MoneroComponents.Style.white : MoneroComponents.Style.green                        }
                        onClicked: {
                                console.log("Copied to clipboard");
                                clipboard.setText(parent.text.split(" ")[0]);
                                appWindow.showStatusMessage(qsTr("Copied to clipboard"),3)
                        }
                    }
            }

            Rectangle {
                anchors.right: parent.right
                width: 300
                height: parent.height
                color: "transparent"

                MoneroComponents.TextPlain {
                    id: dateLabel
                    anchors.left: parent.left
                    font.family: MoneroComponents.Style.fontRegular.name
                    font.pixelSize: 14
                    text: date
                    color: "#808080"
                }

                MoneroComponents.TextPlain {
                    id: timeLabel
                    anchors.left: dateLabel.right
                    anchors.leftMargin: 7
                    anchors.top: parent.top
                    anchors.topMargin: 1
                    font.pixelSize: 12
                    text: time
                    color: "#808080"
                }

                MoneroComponents.TextPlain {
                    id: toLabel
                    property string address: ""
                    color: "#BBBBBB"
                    anchors.left: parent.left
                    anchors.top: dateLabel.bottom
                    anchors.topMargin: 0
                    font.family: MoneroComponents.Style.fontRegular.name
                    font.pixelSize: 16
                    text: {
                        if(isOut){
                            address = TxUtils.destinationsToAddress(destinations);
                            if(address){
                                var truncated = TxUtils.addressTruncate(address);
                                return qsTr("To ") + translationManager.emptyString + truncated;
                            } else {
                                return "Unknown recipient";
                            }
                        }
                        return "";
                    }

                    MouseArea{
                        visible: parent.address !== undefined
                        hoverEnabled: true
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onEntered: {
                            toLabel.color = "white";
                        }
                        onExited: {
                            toLabel.color = "#BBBBBB";
                        }
                        onClicked: {
                            if(parent.address){
                                console.log("Address copied to clipboard");
                                clipboard.setText(parent.address);
                                appWindow.showStatusMessage(qsTr("Address copied to clipboard"),3)
                            }
                        }
                    }
                }

                Rectangle {
                    height: 24
                    width: 24
                    color: "transparent"
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter

                    Image {
                        id: dropdownImage
                        height: 8
                        width: 12
                        source: "qrc:///images/whiteDropIndicator.png"
                        rotation: delegate.collapsed ? 180 : 0
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    MouseArea{
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            delegate.collapsed = !delegate.collapsed;
                        }
                    }
                }
            }
        }

        Rectangle {
            id: row2
            anchors.left: parent.left
            anchors.leftMargin: 20
            anchors.right: parent.right
            anchors.rightMargin: 20
            anchors.top: row1.bottom
            anchors.topMargin: 15
            height: 40
            color: "transparent"
            visible: delegate.collapsed

            // left column
            MoneroComponents.HistoryTableInnerColumn{
                anchors.left: parent.left
                anchors.leftMargin: 30

                labelHeader: qsTr("Transaction ID") + translationManager.emptyString
                labelValue: hash.substring(0, 18) + "..."
                copyValue: hash
            }

            // right column
            MoneroComponents.HistoryTableInnerColumn{
                anchors.right: parent.right
                anchors.rightMargin: 100
                width: 200
                height: parent.height
                color: "transparent"

                labelHeader: qsTr("Fee")
                labelValue: {
                    if(!isOut && !fee){
                        return "-";
                    } else if(isOut && fee){
                        return fee + " TXX";
                    } else {
                        return "Unknown"
                    }
                }
                copyValue: {
                    if(isOut && fee){ return fee }
                    else { return "" }
                }
            }

        }

        Rectangle {
            id: row3
            anchors.left: parent.left
            anchors.leftMargin: 20
            anchors.right: parent.right
            anchors.rightMargin: 20
            anchors.top: row2.bottom
            anchors.topMargin: 15
            height: 40
            color: "transparent"
            visible: delegate.collapsed

            // left column
            MoneroComponents.HistoryTableInnerColumn{
                anchors.left: parent.left
                anchors.leftMargin: 30
                labelHeader: qsTr("Blockheight")
                labelValue: {
                    if (!isPending)
                        if(confirmations < confirmationsRequired)
                            return blockHeight + " " + qsTr("(%1/%2 confirmations)").arg(confirmations).arg(confirmationsRequired);
                        else
                            return blockHeight;
                    if (!isOut)
                        return qsTr("UNCONFIRMED") + translationManager.emptyString
                    if (isFailed)
                        return qsTr("FAILED") + translationManager.emptyString
                    return qsTr("PENDING") + translationManager.emptyString
                }
                copyValue: labelValue.indexOf(" ") > 0 ? labelValue.slice(0, labelValue.indexOf(" ")) : labelValue
            }

            // right column
            MoneroComponents.HistoryTableInnerColumn {
                anchors.right: parent.right
                anchors.rightMargin: 80
                width: 220
                height: parent.height
                color: "transparent"
                hashValue: hash
                labelHeader: qsTr("Description") + translationManager.emptyString
                labelHeaderIconImageSource: "qrc:///images/editIcon.png"

                labelValue: {
                    var note = currentWallet.getUserNote(hash);
                    if(note){
                        if(note.length > 28) {
                            return note.substring(0, 28) + "...";
                        } else {
                            return note;
                        }
                    } else {
                        return qsTr("None") + translationManager.emptyString;
                    }
                }

                copyValue: {
                    return currentWallet.getUserNote(hash);
                }
            }

            Rectangle {
                id: proofButton
                visible: isOut
                color: "#404040"
                height: 24
                width: 24
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 36
                radius: 20

                MouseArea {
                    id: proofButtonMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        var address = TxUtils.destinationsToAddress(destinations);
                        if(address === undefined){
                            console.log('getProof: Error fetching address')
                            return;
                        }

                        var checked = (TxUtils.checkTxID(hash) && TxUtils.checkAddress(address, appWindow.persistentSettings.nettype));
                        if(!checked){
                            console.log('getProof: Error checking TxId and/or address');
                        }

                        console.log("getProof: Generate clicked: txid " + hash + ", address " + address);
                        root.getProofClicked(hash, address, '');
                    }

                    onEntered: {
                        proofButton.color = "#656565";
                    }

                    onExited: {
                        proofButton.color = "#404040";
                    }
                }

                MoneroComponents.TextPlain {
                    color: MoneroComponents.Style.defaultFontColor
                    text: "P"
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    font.pixelSize: 14
                }
            }

            Rectangle {
                id: detailsButton
                color: "#404040"
                height: 24
                width: 24
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 6
                radius: 20

                MouseArea {
                    id: detailsButtonMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        var tx_key = currentWallet.getTxKey(hash)
                        var tx_note = currentWallet.getUserNote(hash)
                        var rings = currentWallet.getRings(hash)
                        var address_label = subaddrIndex == 0 ? qsTr("Primary address") : currentWallet.getSubaddressLabel(subaddrAccount, subaddrIndex)
                        var address = currentWallet.address(subaddrAccount, subaddrIndex)
                        if (rings)
                            rings = rings.replace(/\|/g, '\n')
                        informationPopup.title = "Transaction details";
                        informationPopup.content = buildTxDetailsString(hash,paymentId,tx_key,tx_note,destinations, rings, address, address_label);
                        informationPopup.onCloseCallback = null
                        informationPopup.open();
                    }

                    onEntered: {
                        detailsButton.color = "#656565";
                    }

                    onExited: {
                        detailsButton.color = "#404040";
                    }
                }

                MoneroComponents.TextPlain {
                    color: MoneroComponents.Style.defaultFontColor
                    text: "?"
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    font.pixelSize: 14
                }
            }
        }
    }

    Clipboard { id: clipboard }
}
