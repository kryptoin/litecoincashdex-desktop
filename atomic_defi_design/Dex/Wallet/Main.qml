// Qt Imports
import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import QtCharts 2.3
import QtWebEngine 1.10
import QtGraphicalEffects 1.0

import Qaterial 1.0 as Qaterial

// Project Imports
import "../Components"
import "../Constants"
import App 1.0
import "../Exchange/Trade"
import Dex.Themes 1.0 as Dex

// Right side, main
Item
{
    id: root
    property alias send_modal: send_modal

    readonly property int       layout_margin: 20
    readonly property string    headerTitleColor: Style.colorText2
    readonly property string    headerTitleFont: Style.textSizeMid1
    readonly property string    headerTextColor: Dex.CurrentTheme.foregroundColor
    readonly property string    headerTextFont: Style.textSize
    readonly property string    headerSmallTitleFont: Style.textSizeSmall4
    readonly property string    headerSmallFont: Style.textSizeSmall2
    readonly property string    explorerURL: General.getExplorerURL(api_wallet_page.ticker)
    property int activation_pct: General.zhtlcActivationProgress(API.app.get_zhtlc_status(api_wallet_page.ticker), api_wallet_page.ticker)
    Connections
    {
        target: API.app.settings_pg
        function onZhtlcStatusChanged() {
            activation_pct = General.zhtlcActivationProgress(API.app.get_zhtlc_status(api_wallet_page.ticker), api_wallet_page.ticker)
        }
    }

    property bool tx_fetch_timeout_reached: false

    Timer
    {
        id: tx_fetch_timeout_timer
        interval: 30000
        repeat: false
        onTriggered: {
            root.tx_fetch_timeout_reached = true
        }
    }

    Connections
    {
        target: api_wallet_page
        onTxFetchingStatusChanged: {
            if (api_wallet_page.tx_fetching_busy)
            {
                root.tx_fetch_timeout_reached = false
                tx_fetch_timeout_timer.start()
            }
            else
            {
                tx_fetch_timeout_timer.stop()
                root.tx_fetch_timeout_reached = false
            }
        }
    }

    function loadingPercentage(remaining)
    {
        return General.formatPercent((100 * (1 - parseFloat(remaining)/parseFloat(current_ticker_infos.current_block))).toFixed(3), false)
    }

    readonly property var transactions_mdl: api_wallet_page.transactions_mdl

    Layout.fillHeight: true
    Layout.fillWidth: true

    // TODO: Move this section for the coin summary bar at the top to its own component
    ColumnLayout
    {
        id: wallet_layout

        width: parent.width
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: layout_margin
        anchors.bottom: parent.bottom

        spacing: 20

        // Balance box
        InnerBackground
        {
            id: balance_box

            Layout.fillWidth: true
            Layout.preferredHeight: 100
            Layout.leftMargin: layout_margin
            Layout.rightMargin: layout_margin

            RowLayout
            {
                anchors.fill: parent

                RowLayout
                {
                    Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.topMargin: 10
                    Layout.bottomMargin: Layout.topMargin
                    Layout.leftMargin: 20
                    Layout.rightMargin: Layout.leftMargin
                    spacing: 5

                    // Icon & Full name
                    ColumnLayout
                    {
                        DefaultImage
                        {
                            id: icon_img
                            Layout.bottomMargin: 0
                            source: General.coinIcon(api_wallet_page.ticker)
                            Layout.preferredHeight: 60
                            Layout.preferredWidth: Layout.preferredHeight
                            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter


                            DexRectangle
                            {
                                anchors.centerIn: parent
                                anchors.fill: parent
                                radius: 30
                                enabled: activation_pct != 100
                                visible: enabled
                                opacity: .9
                                color: DexTheme.backgroundColor
                            }

                            DexLabel
                            {
                                anchors.centerIn: parent
                                anchors.fill: parent
                                enabled: activation_pct != 100
                                visible: enabled
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                text: activation_pct + "%"
                                font: DexTypo.head8
                                color: DexTheme.okColor
                            }
                        }

                        DexLabel
                        {
                            id: ticker_name
                            Layout.topMargin: 0
                            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                            text_value: api_wallet_page.ticker // current_ticker_infos.name
                            font.pixelSize: headerTextFont
                            color: headerTextColor
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Ticker and crypto / fiat amount
                    ColumnLayout
                    {
                        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                        spacing: 2

                        DexLabel
                        {
                            id: balance_title
                            Layout.alignment: Qt.AlignHCenter
                            text_value: current_ticker_infos.name + " Balance" // "Wallet Balance"
                            font.pixelSize: headerTitleFont
                            color: headerTitleColor
                        }

                        DexLabel
                        {
                            id: name_value
                            Layout.alignment: Qt.AlignHCenter
                            text_value: General.formatCrypto("", current_ticker_infos.balance, "", current_ticker_infos.fiat_amount, API.app.settings_pg.current_currency)
                            font.pixelSize: headerTextFont
                            color: headerTextColor
                            privacy: true
                        }
                    }

                    Item { Layout.fillWidth: true }

                    VerticalLine
                    {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.rightMargin: 0
                        Layout.preferredHeight: parent.height * 0.6
                    }

                    Item { Layout.fillWidth: true }

                    // Price
                    ColumnLayout
                    {
                        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                        Layout.leftMargin: 10
                        Layout.rightMargin: 10

                        spacing: 5
                        DexLabel
                        {
                            id: price
                            text_value: qsTr("Price")
                            Layout.alignment: Qt.AlignHCenter
                            color: headerTitleColor
                            font.pixelSize: headerTitleFont
                        }

                        DexLabel
                        {
                            text_value:
                            {
                                if (parseFloat(current_ticker_infos.current_currency_ticker_price) > 0)
                                {
                                    return General.formatFiatSmart('', current_ticker_infos.current_currency_ticker_price, API.app.settings_pg.current_currency)
                                }
                                return 'N/A'
                            }
                            Layout.alignment: Qt.AlignHCenter
                            font.pixelSize: headerTextFont
                            color: headerTextColor
                        }
                    }

                    // 24hr change
                    ColumnLayout
                    {
                        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                        Layout.leftMargin: 10
                        Layout.rightMargin: 10

                        spacing: 5
                        DexLabel
                        {
                            id: change_24hr
                            text_value: qsTr("Change 24hr")
                            Layout.alignment: Qt.AlignHCenter
                            color: headerTitleColor
                            font.pixelSize: headerTitleFont
                        }

                        DexLabel
                        {
                            id: change_24hr_value
                            Layout.alignment: Qt.AlignHCenter
                            text_value:
                            {
                                const v = parseFloat(current_ticker_infos.change_24h)
                                return v === 0 ? 'N/A' : General.formatPercent(v)
                            }
                            font.pixelSize: headerTextFont
                            color: change_24hr_value.text_value == "N/A" ? headerTextColor : DexTheme.getValueColor(current_ticker_infos.change_24h)
                        }
                    }

                    // Porfolio %
                    ColumnLayout
                    {
                        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                        Layout.leftMargin: 10
                        Layout.rightMargin: 10

                        spacing: 5
                        DexLabel
                        {
                            id: portfolio_title
                            text_value: qsTr("Portfolio")
                            Layout.alignment: Qt.AlignHCenter
                            color: headerTitleColor
                            font.pixelSize: headerTitleFont
                        }

                        DexLabel
                        {
                            Layout.alignment: Qt.AlignHCenter
                            text_value:
                            {
                                const fiat_amount = parseFloat(current_ticker_infos.fiat_amount)
                                const portfolio_balance = parseFloat(API.app.portfolio_pg.balance_fiat_all)
                                const balance = parseFloat(current_ticker_infos.balance)
                                if (portfolio_balance <= 0) return "N/A"
                                // A coin with a balance but no price feed contributes 0 to the
                                // portfolio value, so show 0% instead of "N/A".
                                if (fiat_amount <= 0)
                                    return balance > 0 ? General.formatPercent("0.00", false) : "N/A"
                                return General.formatPercent((100 * fiat_amount/portfolio_balance).toFixed(2), false)
                            }
                            font.pixelSize: headerTextFont
                            color: headerTextColor
                        }
                    }

                    Item { Layout.fillWidth: true }

                    VerticalLine
                    {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.rightMargin: 0
                        Layout.preferredHeight: parent.height * 0.6
                        visible: General.coinContractAddress(api_wallet_page.ticker) !== ""
                    }

                    Item {
                        Layout.fillWidth: true
                        visible: General.coinContractAddress(api_wallet_page.ticker) !== ""
                    }

                    // Contract address
                    ColumnLayout
                    {
                        visible: General.coinContractAddress(api_wallet_page.ticker) !== ""

                        RowLayout
                        {
                            Layout.alignment: Qt.AlignLeft
                            id: contract_title_row_layout

                            DefaultImage
                            {
                                id: protocol_img
                                source: General.platformIcon(General.coinPlatform(api_wallet_page.ticker))
                                Layout.preferredHeight: 18
                                Layout.preferredWidth: Layout.preferredHeight
                            }

                            DexLabel
                            {
                                id: contract_address_title
                                text_value: General.coinPlatform(api_wallet_page.ticker) + qsTr(" Contract Address")
                                font.pixelSize: headerSmallTitleFont
                                color: headerTitleColor
                            }
                        }

                        RowLayout
                        {
                            Layout.topMargin: 0
                            Layout.bottomMargin: 0
                            Layout.alignment: Qt.AlignLeft
                            Layout.preferredHeight: General.coinContractAddress(api_wallet_page.ticker) ? headerSmallFont : 0
                            visible: General.coinContractAddress(api_wallet_page.ticker) !== ""

                            DexLabel
                            {
                                id: contract_address
                                text_value: General.coinContractAddress(api_wallet_page.ticker)
                                Layout.preferredWidth: contract_title_row_layout.width - headerTextFont
                                font: DexTypo.monoSpace
                                color: headerTextColor
                                elide: Text.ElideMiddle
                                wrapMode: Text.NoWrap
                            }

                            Qaterial.Icon {
                                size: headerTextFont
                                icon: Qaterial.Icons.linkVariant
                                color: contract_linkArea.containsMouse ? headerTextColor : headerTitleColor
                                visible: General.contractURL(api_wallet_page.ticker) != ""

                                DefaultMouseArea {
                                    id: contract_linkArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: {
                                        Qt.openUrlExternally(General.contractURL(api_wallet_page.ticker))
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Buttons
        RowLayout
        {
            Layout.leftMargin: layout_margin
            Layout.rightMargin: layout_margin
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            // spacing: 20

            Item
            {
                Layout.preferredWidth: 165
                Layout.preferredHeight: 40

                // Send Button
                DefaultButton
                {
                    enabled: General.canSend(api_wallet_page.ticker, activation_pct)
                    anchors.fill: parent
                    radius: 18
                    label.text: qsTr("Send")
                    label.font.pixelSize: 16
                    content.anchors.left: content.parent.left
                    content.anchors.leftMargin: enabled ? 23 : 48
                    content.anchors.rightMargin: 23

                    onClicked:
                    {
                        if (API.app.wallet_pg.current_ticker_fees_coin_enabled) send_modal.open()
                        else enable_fees_coin_modal.open()
                    }

                    Row
                    {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        anchors.rightMargin: 23

                        Qaterial.Icon
                        {
                            icon: Qaterial.Icons.arrowTopRight
                            size: 24
                            anchors.verticalCenter: parent.verticalCenter
                            color: Dex.CurrentTheme.warningColor
                        }
                    }
                }

                // Send button error icon
                DefaultAlertIcon
                {
                    visible: activation_pct != 100 || api_wallet_page.send_availability_state !== ""
                    tooltipText: General.isZhtlc(api_wallet_page.ticker) && activation_pct != 100
                                            ? api_wallet_page.ticker + qsTr(" Activation: " + activation_pct + "%")
                                            : api_wallet_page.send_availability_state
                }
            }

            ModalLoader
            {
                id: send_modal
                sourceComponent: SendModal {}
            }

            Component
            {
                id: enable_fees_coin_comp

                MultipageModal
                {
                    id: root
                    width: 300

                    MultipageModalContent
                    {
                        titleText: qsTr("Enable %1 ?").arg(coin_to_enable_ticker)
                        RowLayout
                        {
                            Layout.fillWidth: true
                            DefaultButton
                            {
                                Layout.fillWidth: true
                                text: qsTr("Yes")
                                
                                onClicked:
                                {
                                    if (API.app.enable_coin(coin_to_enable_ticker) === false)
                                    {
                                        enable_fees_coin_failed_modal.open()
                                    }
                                    close()
                                }
                            }

                            DefaultButton
                            {
                                Layout.fillWidth: true
                                text: qsTr("No")
                                onClicked: close()
                            }
                        }
                    }
                }
            }

            ModalLoader
            {
                property string coin_to_enable_ticker: API.app.wallet_pg.ticker_infos.fee_ticker
                id: enable_fees_coin_modal
                sourceComponent: enable_fees_coin_comp
            }

            ModalLoader
            {
                id: enable_fees_coin_failed_modal
                sourceComponent: CannotEnableCoinModal { coin_to_enable_ticker: API.app.wallet_pg.ticker_infos.fee_ticker }
            }

            Item
            {
                Layout.preferredWidth: 165
                Layout.preferredHeight: 40

                // Receive Button
                DefaultButton
                {
                    // Address wont display until activated
                    enabled: General.isZhtlcReady(api_wallet_page.ticker)
                    anchors.fill: parent
                    radius: 18

                    label.text: qsTr("Receive")
                    label.font.pixelSize: 16
                    content.anchors.left: content.parent.left
                    content.anchors.leftMargin: enabled ? 23 : 48

                    onClicked: receive_modal.open()

                    Row
                    {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        anchors.rightMargin: 23

                        Qaterial.Icon
                        {
                            icon: Qaterial.Icons.arrowBottomRight
                            size: 24
                            anchors.verticalCenter: parent.verticalCenter
                            color: Dex.CurrentTheme.okColor
                        }
                    }
                }

                // Receive button error icon
                DefaultAlertIcon
                {
                    visible: !General.isZhtlcReady(api_wallet_page.ticker)
                    tooltipText: api_wallet_page.ticker + qsTr(" Activation: " + activation_pct + "%")
                }
            }

            ModalLoader
            {
                id: receive_modal
                sourceComponent: ReceiveModal {}
            }

            // Swap Button
            Item
            {
                Layout.preferredWidth: 165
                Layout.preferredHeight: 40

                DefaultButton
                {
                    enabled: !General.isWalletOnly(api_wallet_page.ticker) && activation_pct == 100
                    anchors.fill: parent
                    radius: 18

                    // Inner text.
                    label.text: qsTr("Swap")
                    label.font.pixelSize: 16
                    content.anchors.left: content.parent.left
                    content.anchors.leftMargin: enabled ? 23 : 48

                    onClicked: onClickedSwap()

                    Row
                    {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        anchors.rightMargin: 23

                        Qaterial.Icon
                        {
                            icon: Qaterial.Icons.swapHorizontal
                            size: 28
                            anchors.verticalCenter: parent.verticalCenter
                            color: Dex.CurrentTheme.swapIconColor
                        }
                    }

                }

                // Swap button error icon
                DefaultAlertIcon
                {
                    visible: General.isWalletOnly(api_wallet_page.ticker) || activation_pct != 100
                    tooltipText: General.isWalletOnly(api_wallet_page.ticker)
                                    ? api_wallet_page.ticker + qsTr(" is wallet only")
                                    : api_wallet_page.ticker + qsTr(" Activation: " + activation_pct + "%")
                }
            }

            Item { Layout.fillWidth: true }

            // Rewards Button
            Item
            {
                Layout.preferredWidth: 165
                Layout.preferredHeight: 40
                visible: current_ticker_infos.is_claimable && !API.app.is_pin_cfg_enabled()

                Item { Layout.fillWidth: true }

                DefaultButton
                {
                    label.text: qsTr("Rewards")
                    label.font.pixelSize: 16
                    content.anchors.left: content.parent.left
                    content.anchors.leftMargin: enabled ? 23 : 48
                    radius: 18
                    font.pixelSize: 16
                    anchors.fill: parent
                    enabled: parseFloat(current_ticker_infos.balance) > 0
                    onClicked:
                    {
                        claimRewardsModal.open()
                        claimRewardsModal.item.prepareClaimRewards()
                    }
                    Row
                    {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        anchors.rightMargin: 23

                        Qaterial.Icon
                        {
                            icon: Qaterial.Icons.leaf
                            size: 24
                            anchors.verticalCenter: parent.verticalCenter
                            color: "forestgreen"
                        }
                    }
                }

                ModalLoader
                {
                    id: claimRewardsModal
                    sourceComponent: ClaimRewardsModal {}
                }
            }

            // Faucet Button
            Item
            {
                Layout.preferredWidth: 165
                Layout.preferredHeight: 40
                visible:  current_ticker_infos.is_faucet_coin

                DefaultButton
                {
                    enabled: activation_pct == 100
                    anchors.fill: parent
                    radius: 18
                    label.text: qsTr("Faucet")
                    label.font.pixelSize: 16
                    content.anchors.left: content.parent.left
                    content.anchors.leftMargin: enabled ? 23 : 48
                    content.anchors.rightMargin: 23

                    onClicked: api_wallet_page.claim_faucet()

                    Row
                    {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        anchors.rightMargin: 23

                        Qaterial.Icon
                        {
                            icon: Qaterial.Icons.water
                            size: 24
                            anchors.verticalCenter: parent.verticalCenter
                            color: "#33D488"
                        }
                    }
                }

                // Faucet button error icon
                DefaultAlertIcon
                {
                    visible: activation_pct != 100
                    tooltipText: api_wallet_page.ticker + qsTr(" Activation: " + activation_pct + "%")
                }
            }

            // Proposals Button
            Item
            {
                Layout.preferredWidth: 165
                Layout.preferredHeight: 40
                visible:  current_ticker_infos.is_vote_coin

                DefaultButton
                {
                    enabled: activation_pct == 100
                    anchors.fill: parent
                    radius: 18
                    label.text: qsTr("Vote Info")
                    label.font.pixelSize: 16
                    content.anchors.left: content.parent.left
                    content.anchors.leftMargin: enabled ? 23 : 48
                    content.anchors.rightMargin: 23

                    onClicked: {
                        let url = "https://vote.komodoplatform.com/" + api_wallet_page.ticker.toLowerCase() + "/";
                        Qt.openUrlExternally(url);
                    }

                    Row
                    {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        anchors.rightMargin: 23

                        Qaterial.Icon
                        {
                            icon: Qaterial.Icons.vote
                            size: 24
                            anchors.verticalCenter: parent.verticalCenter
                            color: "#2FD083"
                        }
                    }
                }

                // Faucet button error icon
                DefaultAlertIcon
                {
                    visible: activation_pct != 100
                    tooltipText: api_wallet_page.ticker + qsTr(" Activation: " + activation_pct + "%")
                }
            }

            Component.onCompleted: api_wallet_page.claimingFaucetRpcDataChanged.connect(onClaimFaucetRpcResultChanged)
            Component.onDestruction: api_wallet_page.claimingFaucetRpcDataChanged.disconnect(onClaimFaucetRpcResultChanged)
            function onClaimFaucetRpcResultChanged() { claimFaucetResultModal.open() }

            ModalLoader
            {
                id: claimFaucetResultModal
                sourceComponent: ClaimFaucetResultModal {}
            }

            // Public Key button
            Item
            {
                Layout.preferredHeight: 40
                Layout.preferredWidth: 165

                visible: current_ticker_infos.name === "Tokel" || current_ticker_infos.name === "Marmara Credit Loops"

                DefaultButton
                {
                    label.text: qsTr("Public Key")
                    label.font.pixelSize: 16
                    content.anchors.left: content.parent.left
                    content.anchors.leftMargin: enabled ? 23 : 48
                    radius: 18
                    font.pixelSize: 16
                    anchors.fill: parent
                    onClicked:
                    {
                        API.app.settings_pg.fetchPublicKey()
                        publicKeyModal.open()
                    }
                    Row
                    {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        anchors.rightMargin: 23

                        Qaterial.Icon
                        {
                            icon: Qaterial.Icons.keyVariant
                            size: 24
                            anchors.verticalCenter: parent.verticalCenter
                            color: "gold"
                        }
                    }
                }

                ModalLoader
                {
                    id: publicKeyModal
                    sourceComponent: MultipageModal
                    {
                        MultipageModalContent
                        {
                            titleText: qsTr("Public Key")

                            DefaultBusyIndicator
                            {
                                Layout.alignment: Qt.AlignCenter

                                visible: API.app.settings_pg.fetchingPublicKey
                                enabled: visible
                            }

                            RowLayout
                            {
                                Layout.fillWidth: true

                                DexLabel
                                {
                                    Layout.fillWidth: true
                                    visible: !API.app.settings_pg.fetchingPublicKey
                                    text: API.app.settings_pg.publicKey
                                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                                }

                                Qaterial.RawMaterialButton
                                {
                                    backgroundImplicitWidth: 40
                                    backgroundImplicitHeight: 30
                                    backgroundColor: "transparent"
                                    icon.source: Qaterial.Icons.contentCopy
                                    icon.color: Dex.CurrentTheme.foregroundColor
                                    onClicked:
                                    {
                                        API.qt_utilities.copy_text_to_clipboard(API.app.settings_pg.publicKey)
                                        app.notifyCopy(qsTr("Public Key"), qsTr("Copied to Clipboard"))
                                    }
                                }
                            }

                            Image
                            {
                                visible: !API.app.settings_pg.fetchingPublicKey

                                Layout.topMargin: 20
                                Layout.alignment: Qt.AlignHCenter

                                sourceSize.width: 300
                                sourceSize.height: 300
                                source: API.qt_utilities.get_qrcode_svg_from_string(API.app.settings_pg.publicKey)
                            }
                        }
                    }
                }
            }

            // Explorer button
            Item
            {
                Layout.preferredHeight: 40
                Layout.preferredWidth: 165
                enabled: explorerURL != ""

                DefaultButton
                {
                    radius: 18
                    anchors.fill: parent
                    onClicked: Qt.openUrlExternally(explorerURL)
                    label.text: qsTr("Explore")
                    label.font.pixelSize: 16
                    content.anchors.left: content.parent.left
                    content.anchors.leftMargin: enabled ? 23 : 48

                    Row
                    {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        anchors.rightMargin: 23

                        Qaterial.Icon
                        {
                            icon: Qaterial.Icons.databaseSearch
                            size: 24
                            anchors.verticalCenter: parent.verticalCenter
                            color: "#70E0D7"
                        }
                    }
                }
            }

        }

        // Price Graph + Transactions, resizeable split (chart defaults to 60%)
        SplitView
        {
            id: chart_tx_split

            orientation: Qt.Vertical
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.leftMargin: layout_margin
            Layout.rightMargin: layout_margin
            Layout.bottomMargin: layout_margin

            handle: Rectangle
            {
                implicitWidth: 8
                implicitHeight: 10
                color: Dex.CurrentTheme.lineSeparatorColor

                Rectangle
                {
                    width: 48
                    height: 3
                    radius: 2
                    anchors.centerIn: parent
                    color: Dex.CurrentTheme.textSelectionColor
                }
            }

            // Price Graph
            InnerBackground
            {
                id: price_graph_bg

                property bool ticker_supported: false
                readonly property bool is_fetching: chart_loader.loadProgress < 100
                readonly property string chartTheme: Dex.CurrentTheme.getColorMode() === Dex.CurrentTheme.ColorMode.Dark ? "dark" : "light"
                property var ticker: api_wallet_page.ticker

                SplitView.fillHeight: true
                SplitView.preferredHeight: chart_tx_split.height * 0.6

                radius: 18

            onTickerChanged: loadChart()

            Component.onCompleted: {
                console.log("Chart: ticker =", ticker)
                if (ticker && ticker !== "") loadChart()
            }

            function loadChart()
            {
                console.log("loadChart() called, ticker=", ticker, "ticker_supported=", ticker_supported)
                const pair = atomic_qt_utilities.retrieve_main_ticker(ticker) + "/" + atomic_qt_utilities.retrieve_main_ticker(API.app.settings_pg.current_currency)
                const pair_reversed = atomic_qt_utilities.retrieve_main_ticker(API.app.settings_pg.current_currency) + "/" + atomic_qt_utilities.retrieve_main_ticker(ticker)
                const pair_usd = atomic_qt_utilities.retrieve_main_ticker(ticker) + "/" + "USD"
                const pair_usd_reversed = "USD" + "/" + atomic_qt_utilities.retrieve_main_ticker(ticker)
                const pair_busd = atomic_qt_utilities.retrieve_main_ticker(ticker) + "/" + "BUSD"
                const pair_busd_reversed = "BUSD" + "/" + atomic_qt_utilities.retrieve_main_ticker(ticker)

                // Normal pair
                let symbol = General.supported_pairs[pair]
                if (!symbol) {
                    console.warn("Symbol not found for", pair)
                    symbol = General.supported_pairs[pair_reversed]
                }

                // Reversed pair
                if (!symbol) {
                    console.warn("Symbol not found for", pair_reversed)
                    symbol = General.supported_pairs[pair_usd]
                }

                // Pair with USD
                if (!symbol) {
                    console.warn("Symbol not found for", pair_usd)
                    symbol = General.supported_pairs[pair_usd_reversed]
                }

                // Reversed pair with USD
                if (!symbol) {
                    console.warn("Symbol not found for", pair_usd_reversed)
                    symbol = General.supported_pairs[pair_busd]
                }

                // Pair with BUSD
                if (!symbol) {
                    console.warn("Symbol not found for", pair_busd)
                    symbol = General.supported_pairs[pair_busd_reversed]
                }

                // Reversed pair with BUSD
                if (!symbol) {
                    // No TradingView pair is known for this ticker. Route the chart
                    // inside the WebEngine page: prefer a LiveCoinWatch widget when
                    // LiveCoinWatch tracks the coin (e.g. LCC/BCH), otherwise fall back
                    // to a CoinPaprika daily price chart (e.g. MAZA, CAS), and only
                    // report "no chart data" when neither source has data for the coin.
                    const coin_info = API.app.portfolio_pg.global_cfg_mdl.get_coin_info(ticker)
                    const rel_ticker = coin_info.livecoinwatch_id
                    const cp_ticker  = coin_info.coinpaprika_id
                    const base_ticker = General.getChartTicker(atomic_app_secondary_coin)

                    const has_lcw = rel_ticker && rel_ticker !== "test-coin" && base_ticker
                    const has_cp  = cp_ticker && cp_ticker !== "test-coin"

                    if (!has_lcw && !has_cp)
                    {
                        console.warn("No chart for", ticker)
                        ticker_supported = false
                        return
                    }

                    ticker_supported = true
                    chart_loader_show_force = false
                    chart_loader_force_timer.restart()

                    const widget_x = 385
                    const widget_y = 150
                    const fallback_scale = Math.max(0.5, Math.min(chart_loader.width / widget_x, chart_loader.height / widget_y))

                    console.log("Wallet: Loading fallback chart for %1 (lcw=%2, coinpaprika=%3)".arg(ticker).arg(rel_ticker).arg(cp_ticker))

                    chart_loader.loadHtml(`
                        <!DOCTYPE html>
                        <html>
                        <head>
                        <meta charset="utf-8">
                        <style>
                            html, body { margin: 0; padding: 0; width: 100%; height: 100%; overflow: hidden; background: ${Dex.CurrentTheme.comboBoxBackgroundColor}; }
                            .livecoinwatch-widget-1 { transform: scale(${fallback_scale}); transform-origin: top left; }
                            a { pointer-events: none; }
                            #cp { width: 100%; height: 100%; display: flex; flex-direction: column; font-family: "Helvetica Neue", Helvetica, Arial, sans-serif; }
                            #cpHead { display: flex; justify-content: space-between; align-items: baseline; padding: 12px 16px 0 16px; }
                            #cpName { font-size: 13px; color: ${Dex.CurrentTheme.foregroundColor}; font-weight: 600; }
                            #cpPrice { font-size: 18px; color: ${Dex.CurrentTheme.foregroundColor}; font-weight: 600; }
                            #cpChange { font-size: 12px; margin-left: 8px; }
                            #cpChart { flex: 1; min-height: 0; padding: 6px 12px 8px 12px; }
                            #cpChart svg { width: 100%; height: 100%; display: block; }
                            #cpFoot { font-size: 10px; color: ${Dex.CurrentTheme.foregroundColor}; opacity: .6; text-align: right; padding: 0 16px 8px 16px; }
                        </style>
                        </head>
                        <body>
                        <div id="cp" style="display:none;">
                            <div id="cpHead"><span id="cpName"></span><span id="cpPrice"></span></div>
                            <div id="cpChart"></div>
                            <div id="cpFoot">Daily prices in USD - CoinPaprika</div>
                        </div>
                        <script>
                            (function()
                            {
                                var LCW = "${rel_ticker}";
                                var CP  = "${cp_ticker}";
                                var BASE = "${base_ticker}";
                                var COIN = "${ticker}";

                                var GRAD_TOP    = "${Dex.CurrentTheme.dark_theme ? Dex.CurrentTheme.colorGreen3 : Dex.CurrentTheme.colorGreen}";
                                var GRAD_BOTTOM = "${Dex.CurrentTheme.dark_theme ? Dex.CurrentTheme.colorGreen2 : Dex.CurrentTheme.colorGreen3}";
                                var LINE_COLOR  = "${Dex.CurrentTheme.colorGreen2}";

                                function noData() { document.title = "chart:nodata"; }

                                function injectCoinPaprika(rows)
                                {
                                    var prices = rows.map(function(r){ return r.price; });
                                    var min = Math.min.apply(null, prices);
                                    var max = Math.max.apply(null, prices);
                                    if (min === max) { min *= 0.99; max *= 1.01; }
                                    var range = max - min;
                                    var W = 380, H = 140, P = 8;
                                    var pts = [];
                                    for (var i = 0; i < prices.length; i++)
                                    {
                                        var x = P + (i / (prices.length - 1)) * (W - 2*P);
                                        var y = H - P - ((prices[i] - min) / range) * (H - 2*P);
                                        pts.push(x.toFixed(1) + "," + y.toFixed(1));
                                    }
                                    var last = prices[prices.length - 1];
                                    var first = prices[0];
                                    var chg = (last / first - 1) * 100;
                                    var chgColor = chg >= 0 ? "#26da71" : "#fb0000";
                                    var poly = pts.join(" ");
                                    var svg = '<svg width="' + W + '" height="' + H + '" viewBox="0 0 ' + W + ' ' + H + '" preserveAspectRatio="none" xmlns="http://www.w3.org/2000/svg">'
                                        + '<defs><linearGradient id="grad" x1="0" y1="0" x2="0" y2="1">'
                                        + '<stop offset="0" stop-color="' + GRAD_TOP + '"/>'
                                        + '<stop offset="1" stop-color="' + GRAD_BOTTOM + '"/>'
                                        + '</linearGradient></defs>'
                                        + '<polygon points="' + P + ',' + (H - P) + ' ' + poly + ' ' + (W - P) + ',' + (H - P) + '" fill="url(#grad)"/>'
                                        + '<polyline points="' + poly + '" fill="none" stroke="' + LINE_COLOR + '" stroke-width="2" stroke-linejoin="round" stroke-linecap="round"/>'
                                        + '</svg>';
                                    var priceStr = last < 1 ? last.toFixed(8) : last < 100 ? last.toFixed(4) : last.toFixed(2);
                                    document.getElementById("cpChart").innerHTML = svg;
                                    document.getElementById("cpName").textContent = COIN + " - last " + rows.length + " days";
                                    document.getElementById("cpPrice").innerHTML = "$" + priceStr + '<span id="cpChange" style="color:' + chgColor + '">' + (chg >= 0 ? "+" : "") + chg.toFixed(2) + "%</span>";
                                    document.getElementById("cp").style.display = "flex";
                                    document.title = "chart:ok";
                                }

                                function injectLiveCoinWatch()
                                {
                                    var div = document.createElement("div");
                                    div.className = "livecoinwatch-widget-1";
                                    div.setAttribute("lcw-coin", LCW);
                                    div.setAttribute("lcw-base", BASE);
                                    div.setAttribute("lcw-secondary", "USDC");
                                    div.setAttribute("lcw-period", "w");
                                    div.setAttribute("lcw-color-tx", "${Dex.CurrentTheme.foregroundColor}");
                                    div.setAttribute("lcw-color-pr", "#58c7c5");
                                    div.setAttribute("lcw-color-bg", "${Dex.CurrentTheme.comboBoxBackgroundColor}");
                                    div.setAttribute("lcw-border-w", "0");
                                    div.setAttribute("lcw-digits", "8");
                                    document.body.appendChild(div);
                                    var s = document.createElement("script");
                                    s.src = "https://www.livecoinwatch.com/static/lcw-widget.js";
                                    document.head.appendChild(s);
                                    document.title = "chart:ok";
                                }

                                function tryCoinPaprika()
                                {
                                    if (!CP || CP === "test-coin") { noData(); return; }
                                    var end = new Date();
                                    var start = new Date(end.getTime() - 90*86400000);
                                    var url = "https://api.coinpaprika.com/v1/tickers/" + CP + "/historical?start=" + start.toISOString().slice(0,10) + "&end=" + end.toISOString().slice(0,10) + "&interval=1d";
                                    fetch(url)
                                        .then(function(r){ return r.json(); })
                                        .then(function(rows)
                                        {
                                            if (Array.isArray(rows) && rows.length >= 2) injectCoinPaprika(rows);
                                            else noData();
                                        })
                                        .catch(noData);
                                }

                                if (!LCW || LCW === "test-coin" || !BASE)
                                {
                                    tryCoinPaprika();
                                    return;
                                }

                                var check = "https://http-api.livecoinwatch.com/widgets/coins?only=" + LCW + "&currency=" + BASE + "&location=" + encodeURIComponent(window.location.href) + "&utm_medium=widgets&utm_source=atomicdex&utm_campaign=coin-widget";
                                fetch(check)
                                    .then(function(j){ return j.json(); })
                                    .then(function(j)
                                    {
                                        if (j && j.data && j.data.length > 0) injectLiveCoinWatch();
                                        else tryCoinPaprika();
                                    })
                                    .catch(function(){ tryCoinPaprika(); });
                            })();
                        </script>
                        </body>
                        </html>
                    `)
                    return
                }

                ticker_supported = true

                console.log("Wallet: Loading chart for %1, chart_loader visible=%2, width=%3, height=%4".arg(symbol).arg(chart_loader.visible).arg(chart_loader.width).arg(chart_loader.height))

                chart_loader_show_force = false
                chart_loader_force_timer.restart()
                chart_loader.loadHtml(`<style>
                                        html, body { margin: 0; width: 100%; height: 100%; background: %1; overflow: hidden }
                                        .tradingview-widget-container, .tradingview-widget-container__widget { width: 100%; height: 100% }
                                        </style>
                                        <!-- TradingView Widget BEGIN -->
                                        <div class="tradingview-widget-container">
                                          <div class="tradingview-widget-container__widget"></div>
                                          <script type="text/javascript" src="https://s3.tradingview.com/external-embedding/embed-widget-mini-symbol-overview.js" async>
                                          {
                                              "symbol": "${symbol}",
                                              "locale": "en",
                                              "dateRange": "12M",
                                              "colorTheme": "${chartTheme}",
                                              "trendLineColor": "%2",
                                              "isTransparent": true,
                                              "autosize": true,
                                              "largeChartUrl": ""
                                          }
                                          </script>
                                        </div>
                                        <!-- TradingView Widget END -->`.arg(Dex.CurrentTheme.floatingBackgroundColor).arg(Dex.CurrentTheme.textSelectionColor), "https://www.tradingview.com/")
            }

            WebEngineView
            {
                id: chart_loader
                anchors.fill: parent
                visible: parent.ticker_supported && (chart_loader.loadProgress >= 100 || parent.chart_loader_show_force)
                backgroundColor: "transparent"
                profile.httpUserAgent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
                settings.localContentCanAccessRemoteUrls: true
                settings.allowRunningInsecureContent: true
            }

            property bool chart_loader_show_force: false

            Timer {
                id: chart_loader_force_timer
                interval: 4000
                onTriggered: {
                    if (chart_loader.loadProgress > 0 && chart_loader.loadProgress < 100) {
                        parent.chart_loader_show_force = true
                    }
                }
            }

            RowLayout
            {
                visible: parent.ticker_supported && chart_loader.loadProgress < 100 && !parent.chart_loader_show_force
                anchors.centerIn: parent

                DefaultBusyIndicator
                {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.leftMargin: -15
                    Layout.rightMargin: Layout.leftMargin*0.75
                    scale: 0.5
                }

                DexLabel
                {
                    text_value: qsTr("Loading ticker chart data") + "..."
                }
            }

            DexLabel
            {
                visible: !parent.ticker_supported
                text_value: qsTr("There is no chart data for this ticker yet")
                anchors.centerIn: parent
            }

            Connections
            {
                target: Dex.CurrentTheme
                function onThemeChanged()
                {
                    loadChart();
                }
            }

            Connections
            {
                target: chart_loader
                function onTitleChanged()
                {
                    if (chart_loader.title === "chart:ok") price_graph_bg.ticker_supported = true
                    else if (chart_loader.title === "chart:nodata") price_graph_bg.ticker_supported = false
                }
            }
        }

        Rectangle {
            id: transactions_bg
            SplitView.fillHeight: true
            SplitView.preferredHeight: chart_tx_split.height * 0.4

            color: Dex.CurrentTheme.floatingBackgroundColor
            radius: 22

            ClipRRect
            {
                id: clip_rect
                radius: parent.radius
                width: transactions_bg.width
                height: transactions_bg.height

                DefaultRectangle
                {
                    anchors.fill: parent
                    gradient: Gradient
                    {
                        orientation: Gradient.Vertical
                        GradientStop { position: 0.001; color: Dex.CurrentTheme.innerBackgroundColor }
                        GradientStop { position: 1; color: Dex.CurrentTheme.backgroundColor }
                    }
                }
                
                // Transactions history table
                Transactions
                {
                    width: parent.width
                    height: parent.height
                }

                // Placeholder if no tx history available, or being fetched.
                ColumnLayout
                {
                    visible: current_ticker_infos.tx_state !== "InProgress" && transactions_mdl.length === 0
                    anchors.fill: parent
                    anchors.centerIn: parent
                    spacing: 24

                    DexLabel
                    {
                        id: fetching_text_row
                        Layout.topMargin: 24
                        Layout.alignment: Qt.AlignHCenter
                        font.pixelSize: Style.textSize
                        text_value:
                        {
                            if (General.isZhtlc(api_wallet_page.ticker))
                            {
                                if (activation_pct != 100) return qsTr("Please wait, %1 is %2").arg(api_wallet_page.ticker).arg(activation_pct) + qsTr("% activated...")
                            }
                            if (root.tx_fetch_timeout_reached) return qsTr('No transactions available.')
                            if (api_wallet_page.tx_fetching_busy) return qsTr("Fetching transactions...")
                            return qsTr('No transactions available.')
                        }
                    }

                    DefaultBusyIndicator
                    {
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                        Layout.preferredWidth: Style.textSizeSmall3
                        Layout.preferredHeight: Layout.preferredWidth
                        indicatorSize: 32
                        indicatorDotSize: 5
                        visible: api_wallet_page.tx_fetching_busy && !root.tx_fetch_timeout_reached
                    }

                    Item { Layout.fillHeight: true }
                }
            }
        }
        }
    }
}
