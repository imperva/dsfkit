# file_utils.py

import os
import shutil


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
    '''
    Copy a file to the destination path
    '''
    shutil.copy2(source_path, destination_path)


def join_paths(*args):
    '''
    Join multiple path components into a single path using the appropriate
    path separator for the current operating system.
    '''
    return os.path.join(*args)


def is_file_exist(file_path):
    '''
    :param file_path: A path to a file
    :return: whether the file exist or not
    '''
    return os.path.exists(file_path)


def delete_file(file_path):
    '''
    :param file_path: A path to a file
    delete the file
    '''
    try:
        os.remove(file_path)
    except FileNotFoundError:
        raise Exception(f"File not found: {file_path}")
    except Exception as e:
        raise Exception(f"Failed to delete file {file_path}: {str(e)}")


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

