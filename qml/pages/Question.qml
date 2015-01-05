import QtQuick 2.1
import Sailfish.Silica 1.0
import harbour.nemosyne.QmlLogger 2.0
import harbour.nemosyne.SailfishWidgets.Components 1.3
import harbour.nemosyne.SailfishWidgets.Utilities 1.3
import harbour.nemosyne.Nemosyne 1.0

Dialog {
    id: questionPage
    property alias question: questionLabel.text
    property alias answer: answerCard.answer
    property Manager manager;
    property Card card: !!manager ? manager.card : null;
    property CardDetail cardDetailPage

    signal next(int rating)

    objectName: "question"
    canAccept: !!card
    acceptDestination: Answer {
        answer: !!card ? card.answer : ""
        id: answerCard
        onRated: {
            next(rating)
            pageStack.navigateBack()
        }

        Component.onCompleted: next(-1)
    }

    DynamicLoader {
        id: loader
        onObjectCompleted: {
            if(!!object.objectName) {
                if(object.objectName == "addCard") {
                    object.accepted.connect(_addCard)
                    cardDetailPage = object
                } else if(object.objectName == "editCard") {
                    object.accepted.connect(_editCard)
                    cardDetailPage = object
                }
            }
            pageStack.push(object)
        }
    }

    RemorsePopup {
        id: remorse
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: pageCol.height

        PageColumn {
            id: pageCol
            //anchors.top: header.bottom
            title: ""

            Paragraph {
                color: Theme.primaryColor
                id: questionLabel;
                width: parent.width;
                text: !!card ? card.question : ""
            }
        }

        PullDownMenu  {
            id: cardOps

            StandardMenuItem {
                text: qsTr("Add Card(s)")

                onClicked: {
                    Console.info("Add card selected")
                    loader.create(Qt.createComponent("CardDetail.qml"), questionPage, {
                                      "objectName": "addCard"
                                  })
                }
            }

            StandardMenuItem {
                text: qsTr("Edit")
                visible: canAccept

                onClicked: {
                    loader.create(Qt.createComponent("CardDetail.qml"), questionPage, {
                                      "cardOperation": CardOperations.EditOperation,
                                      "questionText": question,
                                      "answerText": answer,
                                      "objectName": "editCard"
                                  })
                }
            }

            StandardMenuItem {
                text: qsTr("Delete")
                visible: canAccept

                onClicked: {
                    remorse.execute(qsTr("Deleting card"), manager.deleteCard)
                }
            }
        }

        VerticalScrollDecorator {}
    }

    Column {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        visible: !canAccept

        InformationalLabel {
            anchors.horizontalCenter: parent.horizontalCenter
            text: qsTr("No cards")
        }

        Subtext {
            anchors.horizontalCenter: parent.horizontalCenter
            text: qsTr("Add cards to begin")
        }
    }

    StatusBar {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Theme.paddingLarge
        anchors.left: parent.left
        anchors.leftMargin: Theme.paddingLarge
        width: parent.width - Theme.paddingLarge * 2
        visible: canAccept

        scheduled: manager.scheduled
        active: manager.active
        unmemorized: manager.unmemorized
    }

    onNext: {
        Console.log("Question: answer was rated: " + rating)
        if(rating == null) {
            rating = -1
        }

        manager.next(rating)
        Console.log("Question: card is " + card)
    }

    onManagerChanged: {
        if(!!manager) {
            manager.deleteCard.connect(_next)
        }
    }

    function _next() {next(-1);}

    function _addCard() {
        Console.log("card added")
    }

    function _editCard() {
        card.question = cardDetailPage.questionText
        card.answer = cardDetailPage.answerText
        manager.saveCard()
        Console.log("card editted")
    }
}
