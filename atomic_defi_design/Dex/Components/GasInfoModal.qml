import QtQuick 2.15
import QtQuick.Layouts 1.15

import "../Constants"
import App 1.0

MultipageModal {
    id: root

    MultipageModalContent {
        titleText: qsTr("Gas Fees")

        DexLabel {
            Layout.preferredHeight: 160
            Layout.fillWidth: true

            text: qsTr("Custom gas fees can make transactions significantly more expensive or fail entirely. Use custom fees only if you understand the network fee implications.")
        }

        footer: [
            CancelButton {
                Layout.fillWidth: true
                text: qsTr("Close")
                onClicked: root.close()
            }
        ]
    }
}
