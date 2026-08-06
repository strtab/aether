import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import Quickshell
import Quickshell.Io

AndroidQuickToggleButton {
    id: root
    name: Translation.tr("v2rayA")
    toggled: false
    buttonIcon: Network.materialSymbol
    
    Component.onCompleted: {
        fetchActiveState.running = true
    }
    
    Process {
        id: stopProc
        command: ["systemctl", "stop", "v2raya.service"]
        onExited: (exitCode, exitStatus) => {
            fetchActiveState.running = true
            if (exitCode !== 0) {
                Quickshell.execDetached(["notify-send", 
                    Translation.tr("v2rayA"), 
                    Translation.tr("Failed to stop service")
                    , "-a", "Shell"
                ])
            }
        }
    }
    
    Process {
        id: connectProc
        command: ["systemctl", "start", "v2raya.service"]
        onExited: (exitCode, exitStatus) => {
            fetchActiveState.running = true
            if (exitCode !== 0) {
                Quickshell.execDetached(["notify-send", 
                    Translation.tr("v2rayA"), 
                    Translation.tr("Connection failed. Please inspect manually with the <tt>systemctl status v2raya</tt> command")
                    , "-a", "Shell"
                ])
            }
        }
    }
    
    Process {
        id: fetchActiveState
        command: ["systemctl", "is-active", "v2raya.service"]
        
        stdout: SplitParser {
            id: activeParser
            onRead: data => {
                const state = data.trim()
                root.toggled = (state === "active")
                root.visible = true
            }
        }
        
        stderr: SplitParser {
            onRead: data => {
                // Service not found or other error
                if (data.includes("could not be found") || data.includes("not-found")) {
                    root.visible = false
                    root.toggled = false
                }
            }
        }
        
        onExited: (exitCode, exitStatus) => {
            // Schedule next check in 5 seconds
            statusTimer.start()
        }
    }
    
    Timer {
        id: statusTimer
        interval: 5000
        repeat: false
        onTriggered: {
            fetchActiveState.running = true
        }
    }

    onClicked: {
        if (toggled) {
            stopProc.running = true
        } else {
            connectProc.running = true
        }
    }
    
    altAction: () => {
        Quickshell.execDetached(["bash", "-c", "xdg-open http://localhost:2017"])
        GlobalStates.sidebarRightOpen = false
    }
    StyledToolTip {
        text: Translation.tr("v2rayA | Right-click to configure")
    }
}
