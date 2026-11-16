import QtQuick
import QtQuick.Layouts
import Iris

Item {
    id: root

    property var quotes: [
        "Your life is ending one minute at a time.",
        "Nothing ever ends poetically. It just ends.",
        "The world is yours, even when it doesn't feel like it.",
        "Somewhere, something incredible is waiting to be known.",
        "We are all just stories in the end.",
        "Time moves differently when you're paying attention.",
        "Perhaps the ordinary is extraordinary enough.",
        "You don't have to understand everything.",
        "The stars don't care, but they're beautiful anyway.",
        "Life is short, but the moments are long.",
        "Everything is temporary. Even this moment.",
        "There is beauty in things that don't last.",
        "The present is the only place you can exist.",
        "Make something meaningful out of something ordinary.",
        "Not everything needs a purpose to matter.",
        "Tomorrow is another chance to begin.",
        "Sometimes, existing is enough."
    ]
    property string shownQuote: "Try your luck!"

    function randomPick() {
        if (quotes.length === 0)
            return ;

        if (quotes.length === 1) {
            shownQuote = quotes[0];
            return ;
        }
        var newQuote;
        do {
            newQuote = quotes[Math.floor(Math.random() * quotes.length)];
        } while (newQuote === shownQuote)
        shownQuote = newQuote;
    }

    width: 200
    height: 200

    ColumnLayout {
        anchors.fill: parent
        spacing: 0
        
        Text {
            Layout.fillWidth: true
            text: root.shownQuote
        }

        Chip {
            onClicked: root.randomPick()
        }
    }

    

}
