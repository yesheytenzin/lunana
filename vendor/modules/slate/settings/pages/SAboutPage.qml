pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "../../../../services"
import "../../../common"
import "../../../common/widgets"
import "../../../common/functions"
import "../../looks"
import ".."

SSettingsPage {
    id: root
    settingsPageIndex: 10
    pageTitle: Translation.tr("About")
    pageIcon: "info"
    pageDescription: Translation.tr("Project information and links")
    
    // Hero card — project identity
    SSettingsCard {
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 4
            Layout.rightMargin: 4
            Layout.topMargin: 8
            Layout.bottomMargin: 4
            spacing: 18
            
            MascotImage {
                id: aboutMascot
                Layout.preferredWidth: 116
                Layout.preferredHeight: 116
                surface: "about"
                pose: "about-confident"
            }

            Rectangle {
                Layout.preferredWidth: 72
                Layout.preferredHeight: 72
                Layout.alignment: Qt.AlignVCenter
                visible: !aboutMascot.active
                radius: Looks.radius.medium
                color: Looks.colors.accent

                SText {
                    anchors.centerIn: parent
                    text: "iN"
                    font.pixelSize: Looks.font.pixelSize.xlarger
                    font.weight: Looks.font.weight.stronger
                    color: Looks.colors.accentFg
                }
            }
            
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                
                SText {
                    text: "Lunana"
                    font.pixelSize: Looks.font.pixelSize.xlarger * 1.4
                    font.weight: Looks.font.weight.stronger
                }
                
                SText {
                    text: Translation.tr("Quickshell desktop shell for Niri")
                    font.pixelSize: Looks.font.pixelSize.normal
                    color: Looks.colors.subfg
                }
                
                RowLayout {
                    spacing: 8
                    Layout.topMargin: 4
                    
                    // Version badge
                    Rectangle {
                        implicitWidth: versionLabel.implicitWidth + 16
                        implicitHeight: 24
                        radius: Looks.radius.small
                        color: Looks.colors.accent
                        
                        SText {
                            id: versionLabel
                            anchors.centerIn: parent
                            text: "v" + (ShellUpdates.localVersion || "?")
                            font.pixelSize: Looks.font.pixelSize.small
                            font.weight: Looks.font.weight.strong
                            color: Looks.colors.accentFg
                        }
                    }
                    
                    // Compositor badge
                    Rectangle {
                        implicitWidth: compLabel.implicitWidth + 16
                        implicitHeight: 24
                        radius: Looks.radius.small
                        color: Looks.colors.bg2
                        
                        SText {
                            id: compLabel
                            anchors.centerIn: parent
                            text: CompositorService.isNiri ? "Niri" : (CompositorService.isHyprland ? "Hyprland" : "Unknown")
                            font.pixelSize: Looks.font.pixelSize.small
                            color: Looks.colors.subfg
                        }
                    }
                    
                    // Framework badge
                    Rectangle {
                        implicitWidth: fwLabel.implicitWidth + 16
                        implicitHeight: 24
                        radius: Looks.radius.small
                        color: Looks.colors.bg2
                        
                        SText {
                            id: fwLabel
                            anchors.centerIn: parent
                            text: "Qt 6"
                            font.pixelSize: Looks.font.pixelSize.small
                            color: Looks.colors.subfg
                        }
                    }
                }
            }
        }
    }

    // Links
    SSettingsCard {
        title: Translation.tr("Links")
        icon: "open"
        
        SSettingsButton {
            label: Translation.tr("GitHub Repository")
            description: "github.com/snowarch/inir"
            icon: "globe-search"
            buttonText: Translation.tr("Open")
            onButtonClicked: Qt.openUrlExternally("https://github.com/snowarch/inir")
        }

        SSettingsButton {
            label: Translation.tr("Documentation")
            description: "github.com/snowarch/inir/wiki"
            icon: "library"
            buttonText: Translation.tr("Open")
            onButtonClicked: Qt.openUrlExternally("https://github.com/snowarch/inir/wiki")
        }
        
        SSettingsButton {
            label: Translation.tr("Original Project (end-4)")
            description: "github.com/end-4/dots-hyprland"
            icon: "open"
            buttonText: Translation.tr("Open")
            onButtonClicked: Qt.openUrlExternally("https://github.com/end-4/dots-hyprland")
        }
        
        SSettingsButton {
            label: Translation.tr("Quickshell Documentation")
            description: "quickshell.outfoxxed.me"
            icon: "globe-search"
            buttonText: Translation.tr("Open")
            onButtonClicked: Qt.openUrlExternally("https://quickshell.outfoxxed.me")
        }
    }
    
    // Credits
    SSettingsCard {
        title: Translation.tr("Credits")
        icon: "people"
        
        ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 0
            Layout.rightMargin: 0
            Layout.bottomMargin: 6
            spacing: 12
            
            SText {
                Layout.fillWidth: true
                text: Translation.tr("Based on illogical-impulse by end-4, adapted for the Niri compositor.")
                wrapMode: Text.WordWrap
                font.pixelSize: Looks.font.pixelSize.normal
                color: Looks.colors.subfg
                lineHeight: 1.3
            }
            
            SText {
                Layout.fillWidth: true
                text: Translation.tr("Special thanks to the Quickshell and Niri communities.")
                wrapMode: Text.WordWrap
                font.pixelSize: Looks.font.pixelSize.normal
                color: Looks.colors.subfg
                lineHeight: 1.3
            }
        }
    }
    
    // System Info
    SSettingsCard {
        title: Translation.tr("System Info")
        icon: "info"
        
        SSettingsRow {
            label: Translation.tr("Config path")
            description: FileUtils.trimFileProtocol(`${Directories.config}/illogical-impulse/`)
            icon: "folder"
        }
        
        SSettingsRow {
            label: Translation.tr("Shell path")
            description: FileUtils.trimFileProtocol(`${Directories.config}/quickshell/lunana/`)
            icon: "folder"
        }
        
        SSettingsRow {
            label: Translation.tr("Panel family")
            description: Config.options?.panelFamily === "slate" ? "Slate (Slate)"
                : Config.options?.panelFamily === "atoll" ? "Atoll" : "drift (Material)"
            icon: "app-generic"
        }
    }
}
