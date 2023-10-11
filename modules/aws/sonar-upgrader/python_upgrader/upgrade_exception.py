# upgrade_exception.py

class UpgradeException(Exception):

    def __init__(self, message):
        super().__init__(message)
