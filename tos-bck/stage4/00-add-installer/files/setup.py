import sys
from PyQt5.QtWidgets import QApplication, QWidget, QLabel, QVBoxLayout, QPushButton, QStackedWidget, QLineEdit
from PyQt5.QtCore import Qt
from PyQt5.QtGui import QPixmap
import os
button_heigh=60
class WelcomePage(QWidget):
    def __init__(self):
        super().__init__()

        # Layout for the welcome page
        layout = QVBoxLayout()
        # Image
        image_label = QLabel(self)
        pixmap = QPixmap("/usr/share/icons")  # Replace with your image path
        image_label.setPixmap(pixmap)
        image_label.setAlignment(Qt.AlignCenter)

        label = QLabel("Welcome to ToasterOS", self)
        label.setAlignment(Qt.AlignCenter)
        label.setStyleSheet("font-size: 36px; font-weight: bold; color: white;")

        next_button = QPushButton("Start Setup", self)
        next_button.clicked.connect(self.next_page)
        next_button.setStyleSheet("font-size: 24px; padding: 20px;")  # Larger font and padding
        next_button.setFixedHeight(button_heigh)  # Increase button height

        layout.addWidget(label)
        layout.addWidget(next_button)

        self.setLayout(layout)

    def next_page(self):
        # Transition to the first setup page
        self.parent().setCurrentIndex(1)

class SetupPage1(QWidget):
    def __init__(self):
        super().__init__()

        # Layout for the first setup page
        layout = QVBoxLayout()

        label = QLabel("Step 1: Enter your details", self)
        label.setAlignment(Qt.AlignCenter)
        label.setStyleSheet("font-size: 24px; font-weight: bold;")

        self.name_input = QLineEdit(self)
        self.name_input.setStyleSheet("font-size: 24px; padding: 20px;")  # Larger font and padding
        self.name_input.setPlaceholderText('Your Full name')

        self.nick_input = QLineEdit(self)
        self.nick_input.setStyleSheet("font-size: 24px; padding: 20px;")  # Larger font and padding
        self.nick_input.setPlaceholderText('Your nickname/fursona name')

        self.email_input = QLineEdit(self)
        self.email_input.setStyleSheet("font-size: 24px; padding: 20px;")  # Larger font and padding
        self.email_input.setPlaceholderText('Your email to use')

        self.pass_input = QLineEdit(self)
        self.pass_input.setStyleSheet("font-size: 24px; padding: 20px;")  # Larger font and padding
        self.pass_input.setPlaceholderText('Password')

        self.passcheck_input = QLineEdit(self)
        self.passcheck_input.setStyleSheet("font-size: 24px; padding: 20px;")  # Larger font and padding
        self.passcheck_input.setPlaceholderText('Password again')

        next_button = QPushButton("Next", self)
        next_button.clicked.connect(self.next_page)
        next_button.setStyleSheet("font-size: 24px; padding: 20px;")  # Larger font and padding
        next_button.setFixedHeight(button_heigh)  # Increase button height

        layout.addWidget(label)
        layout.addWidget(self.name_input)
        layout.addWidget(self.nick_input)
        layout.addWidget(self.email_input)
        layout.addWidget(self.pass_input)
        layout.addWidget(self.passcheck_input)
        layout.addWidget(next_button)

        self.setLayout(layout)

    def next_page(self):
        try:
            with open("/home/toaster/ToasterOS/settings.toml"):
                pass
        except Exception:
            pass
        # Transition to the second setup page
        self.parent().setCurrentIndex(2)

class SetupPage2(QWidget):
    def __init__(self):
        super().__init__()

        # Layout for the second setup page
        layout = QVBoxLayout()

        label = QLabel("Step 2: Set your preferences", self)
        label.setAlignment(Qt.AlignCenter)
        label.setStyleSheet("font-size: 24px; font-weight: bold;")

        self.text_input = QLineEdit(self)
        self.text_input.setPlaceholderText('Enter your preference')

        next_button = QPushButton("Next", self)
        next_button.clicked.connect(self.next_page)
        next_button.setStyleSheet("font-size: 24px; padding: 20px;")  # Larger font and padding
        next_button.setFixedHeight(button_heigh)  # Increase button height

        layout.addWidget(label)
        layout.addWidget(self.text_input)
        layout.addWidget(next_button)

        self.setLayout(layout)

    def next_page(self):
        # Transition to the third setup page
        self.parent().setCurrentIndex(3)

class SetupPage3(QWidget):
    def __init__(self):
        super().__init__()
        
        # Layout for the second setup page
        layout = QVBoxLayout()

        label = QLabel("Setup Complete! Please restart the device", self)
        label.setAlignment(Qt.AlignCenter)
        label.setStyleSheet("font-size: 36px; font-weight: bold; color: white;")

        next_button = QPushButton("Restart", self)
        next_button.clicked.connect(self.restart)
        next_button.setStyleSheet("font-size: 24px; padding: 20px;")  # Larger font and padding
        next_button.setFixedHeight(button_heigh)  # Increase button height

        layout.addWidget(label)
        layout.addWidget(next_button)

        self.setLayout(layout)

    def restart(self):
        # For now, just print a restart message (simulate restart)
        print("Restarting the app...")
        open('/home/toaster/ToasterOS/setup/.done', 'a').close()
        os.system('shutdown -r now')
        QApplication.quit()

class SetupApp(QWidget):
    def __init__(self):
        super().__init__()

        self.setWindowTitle("Setup Window")

        # Layout for the root window
        layout = QVBoxLayout(self)

        # Create a stacked widget to hold the pages
        self.stacked_widget = QStackedWidget(self)

        # Add pages to the stacked widget
        self.stacked_widget.addWidget(WelcomePage())
        self.stacked_widget.addWidget(SetupPage1())
        self.stacked_widget.addWidget(SetupPage2())
        self.stacked_widget.addWidget(SetupPage3())
        # Add the stacked widget to the layout
        layout.addWidget(self.stacked_widget)

        # Set the root window to fullscreen
        self.setWindowFlags(Qt.FramelessWindowHint)  # Remove window borders
        self.showFullScreen()  # Make the root window fullscreen

        # Set the layout for the root window
        self.setLayout(layout)

if __name__ == "__main__":
    app = QApplication(sys.argv)
    window = SetupApp()
    window.show()
    sys.exit(app.exec_())
