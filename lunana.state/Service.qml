import QtQuick
import Quickshell

// lunana.state — M0 placeholder service.
//
// A kind:"service" plugin, mounted by the host at startup. It will grow to own
// the validated `lunana.*` configuration subtree in shell.json and the shared
// runtime state the other lunana plugins read (the role Shibumi gives its
// `*.state` plugin). For M0 it only establishes the service-plugin shape and
// announces itself in the shell log so loading can be confirmed.
//
// lunana.bar does NOT depend on this, so the M0 swap proof stands even if this
// service is absent.
Scope {
  Component.onCompleted: console.log("[lunana.state] M0 service loaded")
}
