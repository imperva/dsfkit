# utils.py

import os
import random
import string
import json
import shutil


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


def update_file_safely(file_path, contents):
    '''
    Create or update a file safely
    '''
    try:
        # Create a temporary file
        temp_file_psth = file_path + '.tmp'
        create_file(temp_file_psth, contents)

        # If the write operation was successful, replace the original file
        os.replace(temp_file_psth, file_path)
    except Exception as ex:
        raise Exception(f"Failed to update file safely {file_path}: {str(ex)}")


def copy_file(source_path, destination_path):
    shutil.copy2(source_path, destination_path)
    print(f"File '{source_path}' copied to '{destination_path}' successfully")


def format_dictionary_to_json(data, object_serialize_hook=None):
    '''
    Formats a dictionary data to a human-readable, pretty-printed JSON format.
    :param data: a dictionary data
    :return: The formatted JSON string
    '''
    pretty_json = json.dumps(data, default=object_serialize_hook , indent=4)
    return pretty_json


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


def read_file_as_json(file_path, object_deserialize_hook=None):
    '''
    :param file_path: An absolute path to a file
    :return: The file contents as JSON object
    '''
    file_contents = read_file_contents(file_path)
    return json.loads(file_contents, object_hook=object_deserialize_hook)


def get_file_path(file_name):
    '''
    Get the absolute path to a file in the same directory as this
    '''
    file_dir = _get_current_directory()
    return os.path.join(file_dir, file_name)


def is_file_exist(file_path):
    '''
    :param file_path: A path to a file
    :return: whether the file exist or not
    '''
    return os.path.exists(file_path)


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


def value_to_enum(enum, value):
    for member in enum:
        if member.value == value:
            return member
    return None
