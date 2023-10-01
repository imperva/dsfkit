# utils.py

import os
import random
import string
import json


def generate_random(char_count):
    '''
    Generates a random string made of lowercase letters and numbers
    :param char_count: The number of characters in the generated string
    :return: A random string
    '''
    return ''.join(random.choices(string.ascii_lowercase + string.digits, k=char_count))


def create_file(file_name, contents):
    '''
    Creates a file
    :param file_name: The name of the file
    :param contents: The contents to write to the new file
    '''
    with open(file_name, 'w') as file:
        file.write(contents)


def format_json_string(json_string):
    '''
    Formats a JSON string to a human-readable, pretty-printed JSON format.
    It assumes the JSON string has " around the JSON attribute names, and not '.
    :param json_string: The JSON string to format
    :return: The formatted JSON string
    '''
    data = json.loads(json_string)
    pretty_json = json.dumps(data, indent=4)
    return pretty_json


def read_file_as_json(file_path):
    '''
    :param file_path: An absolute path to a file
    :return: The file contents as JSON object
    '''
    file_contents = read_file_contents(file_path)
    return json.loads(file_contents)


def get_file_path(file_name):
    '''
    Get the absolute path to a file in the same directory as this
    '''
    file_dir = _get_current_directory()
    return os.path.join(file_dir, file_name)


def read_file_contents(file_path):
    '''
    :param file_path: An absolute path to a file
    :return: The file contents as string
    '''
    try:
        with open(file_path, "r") as file:
            file_contents = file.read()
        return file_contents
    except FileNotFoundError:
        raise Exception(f"File not found: {file_path}")
    except Exception:
        raise Exception(f"Failed to read contents of file: {file_path}")


def _get_current_directory():
    '''
    Get the absolute path of the currently executing script
    '''
    return os.path.dirname(os.path.abspath(__file__))
