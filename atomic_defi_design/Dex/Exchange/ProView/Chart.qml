import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import QtWebEngine 1.10

import "../../Components"
import "../../Constants"
import Dex.Themes 1.0 as Dex
import AtomicDEX.MarketMode 1.0

Item
{
    id: root
    readonly property string theme: Dex.CurrentTheme.getColorMode() === Dex.CurrentTheme.ColorMode.Dark ? "dark" : "light"
    property string loaded_symbol
    property bool pair_supported: false
    property string selected_testcoin

    // Tracks the in-flight chart request so a failed load can be retried with a
    // different source (see onLoadingChanged). Kept on root so the signal handler
    // can read the pair that was requested.
    property string chart_source: "livecoinwatch"
    property string chart_right: ""
    property string chart_left: ""

    // Single source of truth for the loading state. When true, the chart area is
    // hidden and the spinner / "no data" overlay is shown; when false, the chart
    // area is revealed. This replaces the previous fragile bidirectional sync
    // between webEngineViewPlaceHolder.visible and webEngineView.visible, which
    // could get stuck false and leave the spinner spinning forever.
    property bool chart_loading: false

    // Safety net: if a chart load never reports a terminal status (network hang,
    // widget unreachable, superseded load), drop the loading state so the spinner
    // cannot spin forever.
    Timer
    {
        id: chartLoadTimer
        interval: 15000
        onTriggered: root.chart_loading = false
    }

    function loadChart(right_ticker, left_ticker, force = false, source="livecoinwatch")
    {
        // Remember what we are loading so a failed attempt can be retried via a
        // different source (livecoinwatch -> TradingView).
        root.chart_source = source
        root.chart_right = right_ticker
        root.chart_left = left_ticker

        // Enter the loading state: the chart area is hidden and the spinner / "no
        // data" overlay is shown until the load terminates (or the safety timer
        // fires). Resetting it here also clears any stale loading state left by a
        // previously stuck pair.
        root.chart_loading = true

        // <script defer src="https://www.livecoinwatch.com/static/lcw-widget.js"></script> <div class="livecoinwatch-widget-1" lcw-coin="BTC" lcw-base="USD" lcw-secondary="BTC" lcw-period="w" lcw-color-tx="#ffffff" lcw-color-pr="#58c7c5" lcw-color-bg="#1f2434" lcw-border-w="1" lcw-digits="8" ></div>

        let chart_html = ""
        let symbol = ""
        let widget_x = 385
        let widget_y = 150
        let scale_x = root.width / widget_x
        let scale_y = root.height / widget_y

        if (source == "livecoinwatch")
        {
            selected_testcoin = ""
            if (General.is_testcoin(left_ticker))
            {
                pair_supported = false
                selected_testcoin = left_ticker
                console.log("no chart, testcoin", selected_testcoin)
                root.chart_loading = false
                return
            }
            if (General.is_testcoin(right_ticker))
            {
                pair_supported = false
                selected_testcoin = right_ticker
                console.log("no chart, testcoin", selected_testcoin)
                root.chart_loading = false
                return
            }

            let rel_ticker = General.getChartTicker(right_ticker)
            let base_ticker = General.getChartTicker(left_ticker)
            let cp_ticker = General.getCoinPaprikaTicker(right_ticker)

            // LiveCoinWatch does not expose price data for every coin even when a
            // livecoinwatch_id exists in the coin config (e.g. thin assets like MAZA).
            // The embedded script probes LiveCoinWatch's API and, when the coin has no
            // data there, falls back to a CoinPaprika daily price chart instead of
            // rendering a blank widget.
            if (rel_ticker != "" || (cp_ticker != "" && cp_ticker != "test-coin"))
            {
                pair_supported = true
                symbol = (rel_ticker != "" ? rel_ticker : right_ticker)+"-"+(base_ticker != "" ? base_ticker : left_ticker)
                console.log("symbol", symbol)
                console.log("loaded_symbol", loaded_symbol)
                
                if (symbol === loaded_symbol && !force)
                {
                    root.chart_loading = false
                    console.log("symbol === loaded_symbol, ok")
                    return
                }
                loaded_symbol = symbol

                chart_html = `
                <style>
                    html, body { margin: 0; padding: 0; width: 100%; height: 100%; overflow: hidden; background: ${Dex.CurrentTheme.comboBoxBackgroundColor}; }
                    .livecoinwatch-widget-1 {
                        transform: scale(${Math.min(scale_x, scale_y)});
                        transform-origin: top left;
                    }
                    a { pointer-events: none; }
                    #cp { width: 100%; height: 100%; display: flex; flex-direction: column; font-family: "Helvetica Neue", Helvetica, Arial, sans-serif; }
                    #cpHead { display: flex; justify-content: space-between; align-items: baseline; padding: 12px 16px 0 16px; }
                    #cpName { font-size: 13px; color: ${Dex.CurrentTheme.foregroundColor}; font-weight: 600; }
                    #cpPrice { font-size: 18px; color: ${Dex.CurrentTheme.foregroundColor}; font-weight: 600; }
                    #cpChange { font-size: 12px; margin-left: 8px; }
                    #cpChart { flex: 1; min-height: 0; padding: 6px 12px 8px 12px; }
                    #cpFoot { font-size: 10px; color: ${Dex.CurrentTheme.foregroundColor}; opacity: .6; text-align: right; padding: 0 16px 8px 16px; }
                </style>
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
                        var COIN = "${right_ticker}";

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

                        if (!LCW || LCW === "test-coin")
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
                </body>`
            }
        }
        console.log(chart_html)

        if (chart_html == "")
        {
            const pair = atomic_qt_utilities.retrieve_main_ticker(left_ticker) + "/" + atomic_qt_utilities.retrieve_main_ticker(right_ticker)
            const pair_reversed = atomic_qt_utilities.retrieve_main_ticker(right_ticker) + "/" + atomic_qt_utilities.retrieve_main_ticker(left_ticker)

            // Try checking if pair/reversed-pair exists
            symbol = General.supported_pairs[pair]
            if (!symbol) symbol = General.supported_pairs[pair_reversed]

            if (!symbol)
            {
                pair_supported = false
                console.log("pair not supported", pair, pair_reversed)
                root.chart_loading = false
                return
            }

            pair_supported = true

            if (symbol === loaded_symbol && !force)
            {
                root.chart_loading = false
                return
            }

            loaded_symbol = symbol

            chart_html = `
            <style>
            body { margin: 0; }
            </style>

            <!-- TradingView Widget BEGIN -->
            <div class="tradingview-widget-container">
            <div id="tradingview_af406"></div>
            <script type="text/javascript" src="https://s3.tradingview.com/tv.js"></script>
            <script type="text/javascript">
            new TradingView.widget(
            {
            "timezone": "Etc/UTC",
            "locale": "en",
            "autosize": true,
            "symbol": "${symbol}",
            "interval": "D",
            "theme": "${theme}",
            "style": "1",
            "enable_publishing": false,
            "save_image": false
            }
            );
            </script>
            </div>
            <!-- TradingView Widget END -->`
        }
        // chart_loading was set true at the top of loadChart, so the chart area is
        // already hidden and the spinner / "no data" overlay shown. Arm the safety
        // timer; restarting on every call keeps rapid pair switches from leaving a
        // stale timer that could hide a still-loading chart.
        chartLoadTimer.restart()
        dashboard.webEngineView.loadHtml(chart_html)
    }

    Component.onCompleted:
    {
        try
        {
            loadChart(left_ticker?? atomic_app_primary_coin,
                      right_ticker?? atomic_app_secondary_coin)
        }
        catch (e) { console.error(e) }
    }

// Currently chart should not resize, but in future it might be needed

//    onWidthChanged: {
//        try
//        {
//            loadChart(left_ticker?? atomic_app_primary_coin,
//                      right_ticker?? atomic_app_secondary_coin)
//        }
//        catch (e) { console.error(e) }
//    }

    RowLayout
    {
        anchors.fill: parent
        visible: !webEngineViewPlaceHolder.visible

        DefaultBusyIndicator
        {
            visible: pair_supported
            Layout.alignment: Qt.AlignHCenter
            Layout.leftMargin: -15
            Layout.rightMargin: Layout.leftMargin*0.75
            scale: 0.5
        }

        DexLabel
        {
            visible: pair_supported
            text_value: qsTr("Loading pair chart data") + "..."
        }

        DexLabel
        {
            visible: !pair_supported && selected_testcoin == ""
            text_value: qsTr("There is no chart data for this pair")
            Layout.topMargin: 30
            Layout.alignment: Qt.AlignCenter
        }

        DexLabel
        {
            visible: !pair_supported && selected_testcoin != ""
            text_value: qsTr("There is no chart data for %1 (testcoin) pairs").arg(selected_testcoin)
            Layout.topMargin: 30
            Layout.alignment: Qt.AlignCenter
        }
    }

    Item
    {
        id: webEngineViewPlaceHolder
        anchors.fill: parent
        anchors.centerIn: parent
        // Hidden while loading (spinner / "no data" overlay shown) or when the
        // pair is unsupported (message overlay shown); revealed once the load
        // terminates via the chart_loading flag.
        visible: !root.chart_loading && root.pair_supported

        Component.onCompleted:
        {
            dashboard.webEngineView.parent = webEngineViewPlaceHolder
            dashboard.webEngineView.anchors.fill = webEngineViewPlaceHolder
        }
        Component.onDestruction:
        {
            dashboard.webEngineView.visible = false
            dashboard.webEngineView.stop()
        }

        // The dashboard WebEngineView is created hidden (visible: false) and is
        // reparented into this placeholder. Reveal it whenever this placeholder is
        // shown so the loaded chart actually renders. This only ever forces it
        // true; while the placeholder is hidden the chart area (and the view) is
        // hidden regardless, so we never risk getting stuck invisible.
        onVisibleChanged:
        {
            if (visible)
            {
                dashboard.webEngineView.visible = true
            }
        }

        Connections
        {
            target: dashboard.webEngineView

            // A chart load terminating (success OR failure OR superseded by a newer
            // load) drops the loading state so the chart area is revealed and the
            // spinner clears. The old code only revealed on success, which left the
            // spinner spinning forever for unavailable pairs / unreachable widgets.
            function onLoadingChanged(loadRequest)
            {
                if (loadRequest.status === WebEngineLoadRequest.LoadSucceededStatus ||
                    loadRequest.status === WebEngineLoadRequest.LoadFailedStatus ||
                    loadRequest.status === WebEngineLoadRequest.LoadStoppedStatus)
                {
                    root.chart_loading = false
                }

                // Livecoinwatch is an external site. If its load genuinely fails
                // (e.g. unreachable / blocked), retry the same pair with the
                // TradingView widget, which is sourced from General.supported_pairs
                // and does not depend on livecoinwatch. Only do this on a real
                // failure (not LoadStoppedStatus, which just means a newer load
                // superseded this one) and only once (chart_source is updated to
                // "tradingview" by the retry call, preventing any loop).
                if (loadRequest.status === WebEngineLoadRequest.LoadFailedStatus &&
                    root.chart_source === "livecoinwatch")
                {
                    console.log("livecoinwatch chart failed; falling back to TradingView for",
                                root.chart_left, "/", root.chart_right)
                    loadChart(root.chart_right, root.chart_left, true, "tradingview")
                }
            }
        }
    }

    MouseArea {
        id: chart_mousearea
        anchors.fill: webEngineViewPlaceHolder
        onClicked: {
            if (webEngineView.visible) {
                Qt.openUrlExternally("https://www.livecoinwatch.com")
            }
        }
    }

    Connections
    {
        target: app
        function onPairChanged(left, right)
        {
            if (API.app.trading_pg.market_mode == MarketMode.Sell)
            {
                root.loadChart(left, right)
            }
            else
            {
                root.loadChart(right, left)
            }
        }
    }

    Connections
    {
        target: Dex.CurrentTheme
        function onThemeChanged()
        {
            loadChart(left_ticker?? atomic_app_primary_coin,
                      right_ticker?? atomic_app_secondary_coin,
                      true)
        }
    }

    // The embedded livecoinwatch/CoinPaprika probe reports its result through the
    // page title. "chart:ok" reveals the chart; "chart:nodata" (no data on either
    // source) marks the pair as unsupported so the message overlay is shown.
    Connections
    {
        target: dashboard.webEngineView
        function onTitleChanged()
        {
            const t = dashboard.webEngineView.title
            if (t === "chart:nodata")
            {
                root.chart_loading = false
                root.pair_supported = false
            }
            else if (t === "chart:ok")
            {
                root.pair_supported = true
            }
        }
    }
}
