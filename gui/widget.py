# This Python file uses the following encoding: utf-8
import sys

from PySide6.QtWidgets import QApplication, QWidget

from rclone_python import rclone

# Important:
# You need to run the following command to generate the ui_form.py file
#     pyside6-uic form.ui -o ui_form.py, or
#     pyside2-uic form.ui -o ui_form.py
from ui_form import Ui_Widget
from ui_error import Ui_Error


class Widget(QWidget):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.ui = Ui_Widget()
        self.ui.setupUi(self)

        #print(self.ui.backupbutton.isEnabled())

        #print(self.ui.textEdit)

        self.ui.backupbutton.clicked.connect(self.teste)


    def teste(self):
        #print("test")

        self.ui.textEdit.setEnabled(not(self.ui.textEdit.isEnabled()))

class Error(QWidget):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.ui = Ui_Error()
        self.ui.setupUi(self)

        self.ui.exitbutton.clicked.connect(self.exit)


    def exit(self):
        sys.exit(0)

if __name__ == "__main__":
    app = QApplication(sys.argv)
    widget = Widget()
    error = Error()
    widget.show()

    if rclone.is_installed() == True:
        error.show()

    sys.exit(app.exec())
