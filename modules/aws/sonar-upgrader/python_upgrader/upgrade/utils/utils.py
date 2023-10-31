# utils.py

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


def format_dictionary_to_json_string(data, object_serialize_hook=None):
    '''
    Formats a dictionary data to a human-readable, pretty-printed JSON format.
    :param data: a dictionary data
    :param object_serialize_hook: an object serialize
    :return: The formatted JSON string
    '''
    pretty_json = json.dumps(data, default=object_serialize_hook , indent=4)
    return pretty_json


def format_string_to_json(json_string, object_deserialize_hook=None):
    '''
    :param json_string: A json string
    :param object_deserialize_hook: An object deserialize
    :return: The file contents as JSON object
    '''
    return json.loads(json_string, object_hook=object_deserialize_hook)


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


def value_to_enum(enum, value):
    for member in enum:
        if member.value == value:
            return member
    return None
