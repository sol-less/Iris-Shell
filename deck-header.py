import shutil

p = "/home/confid/.config/quickshell/components/deck/Deck.qml"
t = open(p, encoding="utf-8").read()

start = "                        RowLayout {\n                            Layout.fillWidth: true\n                            spacing: 8\n\n                            Rectangle {\n                                implicitHeight: 42"
end = "                        Flow {\n                            id: palette"

assert t.count(start) == 1, "start marker not found"
assert t.count(end) == 1, "end marker not found"
a = t.index(start)
b = t.index(end)
assert a < b

new = '''                        DeckHeader {
                            Layout.fillWidth: true
                            pages: root.pages
                            page: root.page
                            editing: root.editing
                            active: root.open
                            onPageRequested: (i) => root.page = i
                            onEditToggled: root.editing = !root.editing
                            onSettingsRequested: { root.open = false; root.openSettings() }
                            onAddPageRequested: root.addPage()
                            onDeletePageRequested: root.deletePage()
                            onResetRequested: Config.reset("deck.pages")
                        }

'''

shutil.copy(p, p + ".bak-header")
open(p, "w", encoding="utf-8").write(t[:a] + new + t[b:])
print("patched", p)