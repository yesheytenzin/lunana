import QtQuick
import "../../lunana-vendor/modules/iris/session" as LnSession

// iRiS session screen. Self-gates on GlobalStates.sessionOpen, which the
// island's power/session button sets in this same plugin's GlobalStates.
LnSession.IrisSessionScreen {}
