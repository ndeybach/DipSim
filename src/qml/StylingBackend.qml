/* 
MIT License

Copyright (c) 2020 Nils DEYBACH & Léo OUDART

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE. 
*/

import QtQuick 2.15
import QtQuick.Controls.Material 2.15
import Qt.labs.settings 1.0

Item {
    id: root

    property string appTheme: "DARK" // "BLACK" or "DARK" or "LIGHT" or "WHITE" or "MATERIAL_DARK_DEFAULT" or "MATERIAL_LIGHT_DEFAULT"
    property var appThemes: ["BLACK", "DARK", "LIGHT", "WHITE", "MATERIAL_DARK_DEFAULT", "MATERIAL_LIGHT_DEFAULT"]
    property var darkThemes: ["BLACK", "DARK", "MATERIAL_DARK_DEFAULT"]
    property bool darkTheme: darkThemes.indexOf(appTheme) > -1
    property bool highContrastTheme: (appTheme === "BLACK" || appTheme === "WHITE") // add to condition list if new high contrast theme added to amphisize boders
    property bool currentDarkAccentColor : true
    property bool enableDarkAccentColor: true
    property bool enableDarkAccentColorOnlyOnDarkTheme: true

    //////// COLORS ////////

    property color defaultColor: "white" // to initialize before setAppTheme is called

    property string accentColorID: "RED"
    property color accentColor: defaultColor
    property color backgroundColor: defaultColor
    property color backgroundColorAlt: defaultColor
    property color backgroundColorAltAlt: defaultColor
    property color foregroundColor: defaultColor
    property color textColor: defaultColor
    property color borderColor: defaultColor
    property color headerColor: defaultColor
    property color iconsColor: defaultColor

    onEnableDarkAccentColorChanged: root.setAccentColor(accentColorID)
    onDarkThemeChanged: root.setAccentColor(accentColorID)
    onEnableDarkAccentColorOnlyOnDarkThemeChanged: root.setAccentColor(accentColorID)
    onAppThemeChanged: root.setAppTheme(appTheme, root)

    //////// SETTINGS SAVE ////////

    Settings{
        category: "stylingBackend"
        property alias appTheme: root.appTheme
        property alias enableDarkAccentColor: root.enableDarkAccentColor
        property alias enableDarkAccentColorOnlyOnDarkTheme: root.enableDarkAccentColorOnlyOnDarkTheme
        property alias accentColorID: root.accentColorID
    }

    //////// FUNCTIONS ////////

    Component.onCompleted:{
        initTheme(root, appTheme, accentColorID)
    }

    function setAccentColor(colorStrID){
        accentColor = accentColorIDToColorString(colorStrID)
        accentColorID = colorStrID
    }

    function initTheme(root, appThemeStr, accentColorSTRID){ //init theme on startup with default values
        setAppTheme(appThemeStr, root)
        setAccentColor(accentColorSTRID)
    }

    function isDarkTheme(themeStr, root){ // check if themeStr is a dark color
        if(root.darkThemes.includes(themeStr)) return true
        else return false
    }

    function accentColorIDToColorString(colorStringID){
        currentDarkAccentColor = (darkTheme && enableDarkAccentColor) || (!enableDarkAccentColorOnlyOnDarkTheme && !darkTheme && enableDarkAccentColor)
        if(colorStringID === "RED") return currentDarkAccentColor ? "#721d1d" : "#AB0E0E"; // light colors are default but dark from picker on displayed qt material colors
        else if (colorStringID === "PINK") return currentDarkAccentColor ? "#7d1c60" : "#E91E63";
        else if (colorStringID === "PURPLE") return currentDarkAccentColor? "#641d72" : "#9C27B0";
        else if (colorStringID === "DEEPPURPLE") return currentDarkAccentColor ? "#3d1a75" : "#673AB7";
        else if (colorStringID === "INDIGO") return currentDarkAccentColor ? "#273268" : "#3F51B5";
        else if (colorStringID === "BLUE") return currentDarkAccentColor ? "#032540" : "#2196F3";
        else if (colorStringID === "STEELBLUE")return currentDarkAccentColor ? "#366389" : "#4682b4";
        else if (colorStringID === "LIGHTBLUE") return currentDarkAccentColor ? "#022F43" : "#03A9F4";
        else if (colorStringID === "CYAN") return currentDarkAccentColor ? "#09363B" : "#00BCD4";
        else if (colorStringID === "TEAL") return currentDarkAccentColor ? "#15312F" : "#009688";
        else if (colorStringID === "GREEN") return currentDarkAccentColor ? "#142C16" : "#4CAF50";
        else if (colorStringID === "LIGHTGREEN") return currentDarkAccentColor ? "#21300F" : "#8BC34A";
        else if (colorStringID === "LIME") return currentDarkAccentColor ? "#333709" : "#CDDC39";
        else if (colorStringID === "YELLOW") return currentDarkAccentColor ? "#413C00" : "#FFEB3B";
        else if (colorStringID === "AMBER") return currentDarkAccentColor ? "#443400" : "#FFC107";
        else if (colorStringID === "ORANGE") return currentDarkAccentColor ? "#462B00" : "#FF9800";
        else if (colorStringID === "DEEPORANGE") return currentDarkAccentColor ? "#380E09" : "#FF5722";
        else if (colorStringID === "BROWN") return currentDarkAccentColor ? "#251E1B" : "#795548";
        else if (colorStringID === "GREY") return currentDarkAccentColor ? "#1A1B1C" : "#9E9E9E";
        else if (colorStringID === "BLUEGREY") return currentDarkAccentColor ? "#1E1F21" : "#607D8B";
        else if (colorStringID === "BLACK/WHITE") return darkTheme ? "#AAAAAA" : "#222222";
    }

    function setAppTheme(theme, root){
        if(theme === "BLACK"){
            backgroundColor = "#000000"
            backgroundColorAlt = "#000000"
            backgroundColorAltAlt = "#292929"

            foregroundColor = "#FFFFFF"
            textColor = "#C9C9C9"
            borderColor = "#262626"
            headerColor = "#000000"
            iconsColor = "#AEB8B8"
        }
        else if(theme === "DARK"){
            root.backgroundColor = "#2B2B2B"
            root.backgroundColorAlt = "#242424"
            root.backgroundColorAltAlt = "#333333"

            root.foregroundColor = "#DDDDDD"
            root.textColor = "#CFCFCF"
            root.borderColor = "#262626"
            root.headerColor = "#262626"
            root.iconsColor = "#A1A4A6"
        }
        else if(theme === "LIGHT"){
            root.backgroundColor = "#D9D9D9"
            root.backgroundColorAlt = "#BFBFBF"
            root.backgroundColorAltAlt = "#ABABAB"

            root.foregroundColor = "#0F0F0F"
            root.textColor = "#1C1C1C"
            root.borderColor = "#8C8C8C"
            root.headerColor = "#A8A8A8"
            root.iconsColor = "#26282B"
        }
        else if(theme === "WHITE"){
            root.backgroundColor = "#FFFFFF"
            root.backgroundColorAlt = "#EBEBEB"
            root.backgroundColorAltAlt = "#EBEBEB"

            root.foregroundColor = "#000000"
            root.textColor = "#080808"
            root.borderColor = "#CCCCCC"
            root.headerColor = "#E3E3E3"
            root.iconsColor = "#212326"

        }
        else if(theme === "MATERIAL_DARK_DEFAULT"){ // to modify
            root.backgroundColor = "#000000"
            root.backgroundColorAlt = "#000000"
            root.backgroundColorAltAlt = "#292929"

            root.foregroundColor = "#FFFFFF"
            root.textColor = "#C9C9C9"
            root.borderColor = "#262626"
            root.headerColor = "#000000"
            root.iconsColor = "#AEB8B8"

        }
        else if(theme === "MATERIAL_LIGHT_DEFAULT"){ // to modify
            root.backgroundColor = "#000000"
            root.backgroundColorAlt = "#000000"
            root.backgroundColorAltAlt = "#292929"

            root.foregroundColor = "#FFFFFF"
            root.textColor = "#C9C9C9"
            root.borderColor = "#262626"
            root.headerColor = "#000000"
            root.iconsColor = "#AEB8B8"

        }
    }
}
