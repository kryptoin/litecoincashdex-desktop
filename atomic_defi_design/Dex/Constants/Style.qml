pragma Singleton
import QtQuick 2.15
import Qaterial 1.0 as Qaterial
import Dex.Themes 1.0 as Dex

QtObject {
    function setQaterialStyle() {
        Qaterial.Style.accentColorLight = Style.colorTheme4
        Qaterial.Style.accentColorDark = Style.colorTheme4
    }

    Component.onCompleted: {
        setQaterialStyle()
    }

    onDark_themeChanged: setQaterialStyle()

    readonly property FontLoader fontB: FontLoader { source: "../../assets/fonts/Ubuntu-B.ttf" }
    readonly property FontLoader fontBI: FontLoader { source: "../../assets/fonts/Ubuntu-BI.ttf" }
    readonly property FontLoader fontL: FontLoader { source: "../../assets/fonts/Ubuntu-L.ttf" }
    readonly property FontLoader fontLI: FontLoader { source: "../../assets/fonts/Ubuntu-LI.ttf" }
    readonly property FontLoader fontM: FontLoader { source: "../../assets/fonts/Ubuntu-M.ttf" }
    readonly property FontLoader fontMI: FontLoader { source: "../../assets/fonts/Ubuntu-MI.ttf" }
    readonly property FontLoader fontR: FontLoader { source: "../../assets/fonts/Ubuntu-R.ttf" }
    readonly property FontLoader fontRI: FontLoader { source: "../../assets/fonts/Ubuntu-R.ttf" }
    readonly property FontLoader fontTh: FontLoader { source: "../../assets/fonts/Ubuntu-Th.ttf" }
    readonly property string font_family: "Ubuntu"

    readonly property string listItemPrefix:  " ⚬   "
    readonly property string successCharacter:  "✓"
    readonly property string failureCharacter:  "✘"
    readonly property string warningCharacter:  "⚠"

    readonly property int animationDuration: 125

    readonly property int textSizeSmall: 10
    readonly property int textSizeSmall1: 11
    readonly property int textSizeSmall2: 12
    readonly property int textSizeSmall3: 13
    readonly property int textSizeSmall4: 14
    readonly property int textSizeSmall5: 15
    readonly property int textSize: 16
    readonly property int textSizeMid: 17
    readonly property int textSizeMid1: 18
    readonly property int textSizeMid2: 19
    readonly property int textSize1: 20
    readonly property int textSize2: 24
    readonly property int textSize3: 36
    readonly property int textSize4: 48
    readonly property int textSize5: 60
    readonly property int textSize6: 72
    readonly property int textSize7: 84
    readonly property int textSize8: 96
    readonly property int textSize9: 108
    readonly property int textSize10: 120
    readonly property int textSize11: 132
    readonly property int textSize12: 144

    readonly property int rectangleCornerRadius: 7
    readonly property int itemPadding: 12
    readonly property int buttonSpacing: 12
    readonly property int rowSpacing: 12
    readonly property int rowSpacingSmall: 6
    readonly property int iconTextMargin: 5
    readonly property int sidebarLineHeight: 44
    readonly property double hoverLightMultiplier: 1.5
    readonly property double hoverOpacity: 0.6

    property bool dark_theme: Dex.CurrentTheme.getColorMode() === Dex.CurrentTheme.ColorMode.Dark


    function applyOpacity(hex, opacity="00") {
        return "#" + opacity + hex.substr(hex.length - 6)
    }

    function colorOnlyIf(condition, color) {
        return applyOpacity(color, condition ? "FF" : "00")
    }

    readonly property string colorQtThemeAccent: colorGreen
    readonly property string colorQtThemeForeground: colorWhite1
    readonly property string colorQtThemeBackground: colorTheme9

    readonly property string colorRed: dark_theme ? "#D13990" : "#9a1165" // Light is 15% darker than Red2, same with the green set
    readonly property string colorRed2:  dark_theme ? "#b61477" : "#b61477"
    readonly property string colorRed3:  dark_theme ? "#6d0c47" : "#D13990"
    readonly property string colorYellow:  dark_theme ? "#FFC305" : "#FFC305"
    readonly property string colorOrange:  dark_theme ? "#F7931A" : "#F7931A"
    readonly property string colorBlue:  dark_theme ? "#2FD083" : "#2FD083"
    readonly property string colorGreen:  dark_theme ? "#74FBEE" : "#109f8d"
    readonly property string colorGreen2:  dark_theme ? "#14bca6" : "#14bca6"
    readonly property string colorGreen3:  dark_theme ? "#07433b" : "#74FBEE"

    readonly property string colorWhite0:  dark_theme ? "#FFFFFF" : "#FFFFFF"
    readonly property string colorWhite1:  dark_theme ? "#FFFFFF" : "#000000"
    readonly property string colorWhite2:  dark_theme ? "#F9F9F9" : "#111111"
    readonly property string colorWhite3:  dark_theme ? "#F0F0F0" : "#222222"
    readonly property string colorWhite4:  dark_theme ? "#C9C9C9" : "#333333"
    readonly property string colorWhite5:  dark_theme ? "#8E9293" : "#444444"
    readonly property string colorWhite6:  dark_theme ? "#777777" : "#555555"
    readonly property string colorWhite7:  dark_theme ? "#666666" : "#666666"
    readonly property string colorWhite8:  dark_theme ? "#555555" : "#777777"
    readonly property string colorWhite9:  dark_theme ? "#444444" : "#8E9293"
    readonly property string colorWhite10:  dark_theme ? "#333333" : "#C9C9C9"
    readonly property string colorWhite11:  dark_theme ? "#222222" : "#F0F0F0"
    readonly property string colorWhite12:  dark_theme ? "#111111" : "#F9F9F9"
    readonly property string colorWhite13:  dark_theme ? "#000000" : "#FFFFFF"

    readonly property string colorTheme1:  dark_theme ? "#3CC9BF" : "#3CC9BF"
    readonly property string colorTheme2:  dark_theme ? "#36A8AA" : "#36A8AA"
    readonly property string colorTheme3:  dark_theme ? "#318795" : "#318795"
    readonly property string colorTheme4:  dark_theme ? "#2B6680" : "#2B6680"
    readonly property string colorTheme5:  dark_theme ? "#183F31" : "#ececf2"
    readonly property string colorTheme6:  dark_theme ? "#14382B" : "#efeff5"
    readonly property string colorTheme7:  dark_theme ? "#15182A" : "#f2f2f7"
    readonly property string colorTheme8:  dark_theme ? "#171A2C" : "#f6f6f9"
    readonly property string colorTheme9:  dark_theme ? "#0E1021" : "#F9F9FB"
    readonly property string colorTheme99:  dark_theme ? "#1A4636" : "#F9F9FB"

    readonly property string colorTheme10:  dark_theme ? "#22A06B" : "#22A06B"
    readonly property string colorTheme11:  dark_theme ? "#00A3FF" : "#00A3FF"
    readonly property string colorThemeLine:  dark_theme ? "#1D1F23" : "#1D1F23"
    readonly property string colorThemePassive:  dark_theme ? "#777F8C" : "#777F8C"
    readonly property string colorThemePassiveLight:  dark_theme ? "#CCCDD0" : "#CCCDD0"
    readonly property string colorThemeDark:  dark_theme ? "#26282C" : "#26282C"
    readonly property string colorThemeDark2:  dark_theme ? "#3C4150" : "#E6E8ED"
    readonly property string colorThemeDark3:  dark_theme ? "#78808D" : "#78808D"
    readonly property string colorThemeDarkLight:  dark_theme ? "#78808D" : "#456078"

    property string colorRectangle:  dark_theme ? colorTheme7 : colorTheme7
    readonly property string colorInnerBackground:  dark_theme ? colorTheme7 : colorTheme7

    readonly property string colorDropShadowLight:  dark_theme ? "#216975a4" : "#21FFFFFF"
    readonly property string colorDropShadowLight2:  dark_theme ? "#606975a4" : "#60FFFFFF"
    readonly property string colorDropShadowDark:  dark_theme ? "#FF050615" : "#BECDE2"
    readonly property string colorBorder:  dark_theme ? "#23273B" : "#DAE1EC"
    readonly property string colorBorder2:  dark_theme ? "#1C1F32" : "#DAE1EC"

    readonly property string colorGradientLine1:  dark_theme ? "#00FFFFFF" : "#00CFD4DB"
    readonly property string colorGradientLine2:  dark_theme ? "#0FFFFFFF" : "#FFCFD4DB"

    readonly property string colorWalletsHighlightGradient:  dark_theme ? "#087A55" : "#087A55"
    readonly property string colorWalletsSidebarDropShadow:  dark_theme ? "#B0000000" : "#BECDE2"

    readonly property string colorScrollbar:  dark_theme ? "#202339" : "#C4CCDA"
    readonly property string colorScrollbarBackground:  dark_theme ? "#10121F" : "#EFF1F6"
    readonly property string colorScrollbarGradient1:  dark_theme ? "#267252" : "#C4CCDA"
    readonly property string colorScrollbarGradient2:  dark_theme ? "#1E5A43" : "#C4CCDA"

    readonly property string colorSidebarIconHighlighted:  dark_theme ? "#33D488" : "#FFFFFF"
    readonly property string colorSidebarHighlightGradient1:  dark_theme ? "#FF237A5A" : "#8b95ed"
    readonly property string colorSidebarHighlightGradient2:  dark_theme ? "#BA237A5A" : "#AD7faaf0"
    readonly property string colorSidebarHighlightGradient3:  dark_theme ? "#5F237A5A" : "#A06dc9f3"
    readonly property string colorSidebarHighlightGradient4:  dark_theme ? "#00237A5A" : "#006bcef4"
    readonly property string colorSidebarDropShadow:  dark_theme ? "#90000000" : "#BECDE2"
    readonly property string colorSidebarSelectedText:  dark_theme ? "#FFFFFF" : "#FFFFFF"

    readonly property string colorCoinListHighlightGradient:  dark_theme ? "#1E5A43" : "#E0E6F0"

    readonly property string colorRectangleBorderGradient1:  dark_theme ? "#267252" : "#DDDDDD"
    readonly property string colorRectangleBorderGradient2:  dark_theme ? "#0D1021" : "#EFEFEF"

    readonly property string colorLineBasic:  dark_theme ? "#3CD88B" : "#3CD88B"


    readonly property string colorText: dark_theme ? Style.colorWhite1 : "#405366"
    readonly property string colorText2: dark_theme ? "#79808C" : "#3C5368"
    readonly property string colorTextDisabled: dark_theme ? Style.colorWhite8 : "#B5B9C1"

    readonly property string colorPlaceholderText: dark_theme ? Style.colorWhite9 : Style.colorWhite9
    readonly property string colorSelectedText: dark_theme ? Style.colorTheme9 : Style.colorTheme9
    readonly property string colorSelection: dark_theme ? Style.colorGreen2 : Style.colorGreen2

    readonly property string colorTrendingLine: dark_theme ? Style.colorGreen : "#37a6ef"

    function getValueColor(v) {
        v = parseFloat(v)
        if(v !== 0)
            return v > 0 ? Style.colorGreen : Style.colorRed

        return Style.colorWhite4
    }

    function getCoinTypeColor(type)
    {
        switch (type)
        {
            case 'IDO':               return dark_theme ? colorCoinDark["IDO"] : colorCoin["IDO"]
            case 'AVX-20':            return dark_theme ? colorCoinDark["AVAX"] : colorCoin["AVAX"]
            case 'ZHTLC':             return dark_theme ? colorCoinDark["ARRR"] : colorCoin["ARRR"]
            case 'COSMOS':            return dark_theme ? colorCoinDark["ATOM"] : colorCoin["ATOM"]
            case 'SLP':               return dark_theme ? colorCoinDark["BCH"] : colorCoin["BCH"]
            case 'BEP-20':            return dark_theme ? colorCoinDark["BNB"] : colorCoin["BNB"]
            case 'RSK Smart Bitcoin': return dark_theme ? colorCoinDark["UTXO"] : colorCoin["UTXO"]
            case 'UTXO':              return dark_theme ? colorCoinDark["UTXO"] : colorCoin["UTXO"]
            case 'Ethereum Classic':  return dark_theme ? colorCoinDark["ETC"] : colorCoin["ETC"]
            case 'Arbitrum':          return dark_theme ? colorCoinDark["ETH"] : colorCoin["ETH"]
            case 'ERC-20':            return dark_theme ? colorCoinDark["ETH"] : colorCoin["ETH"]
            case 'EWT':               return dark_theme ? colorCoinDark["EWT"] : colorCoin["EWT"]
            case 'FTM-20':            return dark_theme ? colorCoinDark["FTM"] : colorCoin["FTM"]
            case 'Moonbeam':          return dark_theme ? colorCoinDark["GLMR"] : colorCoin["GLMR"]
            case 'HecoChain':         return dark_theme ? colorCoinDark["HECO"] : colorCoin["HECO"]
            case 'QRC-20':            return dark_theme ? colorCoinDark["QTUM"] : colorCoin["QTUM"]
            case 'KRC-20':            return dark_theme ? colorCoinDark["KCS"] : colorCoin["KCS"]
            case 'Smart Chain':       return dark_theme ? colorCoinDark["KMD"] : colorCoin["KMD"]
            case 'Matic':
            case 'PLG-20':            return dark_theme ? colorCoinDark["MATIC"] : colorCoin["MATIC"]
            case 'Moonriver':         return dark_theme ? colorCoinDark["MOVR"] : colorCoin["MOVR"]
            case 'HRC-20':            return dark_theme ? colorCoinDark["ONE"] : colorCoin["ONE"]
            case 'SmartBCH':          return dark_theme ? colorCoinDark["SBCH"] : colorCoin["SBCH"]
            case 'Ubiq':              return dark_theme ? colorCoinDark["UBQ"] : colorCoin["UBQ"]
            case 'Optimism':          return "#BB2100"
            case 'WALLET ONLY':       return dark_theme ? colorCoinDark["WALLET ONLY"] : colorCoin["WALLET ONLY"] 
            default:                  return dark_theme ? colorCoinDark["default"] : colorCoin["default"] 
        }
    }

    function getCoinTypeTextColor(type)
    {
        switch (type)
        {
            case 'BEP-20':      return '#232323'
            default:            return '#F9F9F9'
        }
    }

    function getCoinGroupTextColor(type)
    {
        switch (type)
        {
            case 'IDO':               return dark_theme ? colorCoinDark["IDO"] : colorCoin["IDO"]
            case 'AVX-20':            return dark_theme ? colorCoinDark["AVAX"] : colorCoin["AVAX"]
            case 'ZHTLC':             return dark_theme ? colorCoinDark["ARRR"] : colorCoin["ARRR"]
            case 'COSMOS':            return dark_theme ? colorCoinDark["ATOM"] : colorCoin["ATOM"]
            case 'SLP':               return dark_theme ? colorCoinDark["BCH"] : colorCoin["BCH"]
            case 'BEP-20':            return dark_theme ? colorCoinDark["BNB"] : colorCoin["BNB"]
            case 'RSK Smart Bitcoin': return dark_theme ? colorCoinDark["UTXO"] : colorCoin["UTXO"]
            case 'UTXO':              return dark_theme ? colorCoinDark["UTXO"] : colorCoin["UTXO"]
            case 'Ethereum Classic':  return dark_theme ? colorCoinDark["ETC"] : colorCoin["ETC"]
            case 'Arbitrum':          return dark_theme ? colorCoinDark["ETH"] : colorCoin["ETH"]
            case 'ERC-20':            return dark_theme ? colorCoinDark["ETH"] : colorCoin["ETH"]
            case 'EWT':               return dark_theme ? colorCoinDark["EWT"] : colorCoin["EWT"]
            case 'FTM-20':            return dark_theme ? colorCoinDark["FTM"] : colorCoin["FTM"]
            case 'Moonbeam':          return dark_theme ? colorCoinDark["GLMR"] : colorCoin["GLMR"]
            case 'HecoChain':         return dark_theme ? colorCoinDark["HECO"] : colorCoin["HECO"]
            case 'QRC-20':            return dark_theme ? colorCoinDark["QTUM"] : colorCoin["QTUM"]
            case 'KRC-20':            return dark_theme ? colorCoinDark["KCS"] : colorCoin["KCS"]
            case 'Smart Chain':       return dark_theme ? colorCoinDark["KMD"] : colorCoin["KMD"]
            case 'Matic':
            case 'PLG-20':            return dark_theme ? colorCoinDark["MATIC"] : colorCoin["MATIC"]
            case 'Moonriver':         return dark_theme ? colorCoinDark["MOVR"] : colorCoin["MOVR"]
            case 'HRC-20':            return dark_theme ? colorCoinDark["ONE"] : colorCoin["ONE"]
            case 'SmartBCH':          return dark_theme ? colorCoinDark["SBCH"] : colorCoin["SBCH"]
            case 'Ubiq':              return dark_theme ? colorCoinDark["UBQ"] : colorCoin["UBQ"]
            case 'Optimism':          return "#BB2100"
            case 'WALLET ONLY':       return dark_theme ? colorCoinDark["WALLET ONLY"] : colorCoin["WALLET ONLY"] 
            default:                  return dark_theme ? colorCoinDark["default"] : colorCoin["default"] 
        }
    }

    function getCoinColor(ticker) {
        let info = API.app.portfolio_pg.global_cfg_mdl.get_coin_info(ticker)
        if (!info.type) { return colorWhite3 }
        let base_ticker = atomic_qt_utilities.retrieve_main_ticker(ticker)
        if (colorCoin.hasOwnProperty(base_ticker) && !dark_theme)
        {
            return colorCoin[base_ticker]
        }
        if (colorCoinDark.hasOwnProperty(base_ticker) && dark_theme)
        {
            return colorCoinDark[base_ticker]
        }
        // No curated colour for this ticker: derive a stable, distinct colour
        // from the ticker so coins that share a group (e.g. several green
        // UTXO/Smart Chain assets) stay visually distinguishable in the
        // portfolio pie, coin lists and badges.
        return fallbackCoinColor(base_ticker)
    }

    function fallbackCoinColor(ticker) {
        let h = 0
        for (let i = 0; i < ticker.length; i++)
        {
            h = (h * 31 + ticker.charCodeAt(i)) >>> 0
        }
        return colorCoinFallback[h % colorCoinFallback.length]
    }

    readonly property var colorCoin: ({
                                          "ARRR": "#C7A34C",
                                          "ATOM": "#963b9a",
                                          "AVAX": "#E84142",
                                          "BNB": "#b35900",
                                          "BCH": "#8DC351",
                                          "ETC": "#328432",
                                          "ETH": "#687DE3",
                                          "EWT": "#A466FF",
                                          "FTM": "#13B5EC",
                                          "HECO": "#00953F",                             
                                          "GLMR": "#F6007C",
                                          "QTUM": "#2E9AD0",
                                          "KCS": "#25AF90",
                                          "KMD": "#2d4f86",
                                          "MOVR": "#52CCC9",
                                          "MATIC": "#804EE1",
                                          "ONE": "#00BEEE",
                                          "SBCH": "#74dd54",
                                          "UBQ": "#00EB90",
                                          "UTXO": "#349d5f",
                                          "default": "#2f2f2f",
                                          "IDO": "#536E93",
                                          "WALLET ONLY": "#404040"
                                      })

    readonly property var colorCoinDark: ({
                                          "ARRR": "#C7A34C",
                                          "ATOM": "#963b9a",
                                          "AVAX": "#E84142",
                                          "BNB": "#ffc266",
                                          "BCH": "#8DC351",
                                          "ETC": "#328432",
                                          "ETH": "#687DE3",
                                          "EWT": "#A466FF",
                                          "FTM": "#13B5EC",
                                          "HECO": "#00953F",                             
                                          "GLMR": "#F6007C",
                                          "QTUM": "#2E9AD0",
                                          "KCS": "#25AF90",
                                          "KMD": "#799bd2",
                                          "MOVR": "#52CCC9",
                                          "MATIC": "#804EE1",
                                          "ONE": "#00BEEE",
                                          "SBCH": "#74dd54",
                                          "UBQ": "#00EB90",
                                          "UTXO": "#349d5f",
                                          "default": "#c8c8c8",
                                          "IDO": "#536E93",
                                           "WALLET ONLY": "#cccccc"
                                       })

    //! Curated, well-spread palette used as a stable fallback for any ticker
    //! that has no explicit entry in colorCoin / colorCoinDark. Indexed by a
    //! hash of the ticker so the same coin always maps to the same colour.
    readonly property var colorCoinFallback: ([
                                          "#E84142", "#F6A623", "#F8E71C", "#7ED321", "#50E3C2", "#4A90E2",
                                          "#9013FE", "#BD10E0", "#FF6FA5", "#B8E986", "#417505", "#8B572A",
                                          "#00BCD4", "#3F51B5", "#009688", "#FF5722", "#795548", "#607D8B",
                                          "#E91E63", "#CDDC39", "#FFC107", "#00ACC1", "#9C27B0", "#4CAF50"
                                      ])
}
