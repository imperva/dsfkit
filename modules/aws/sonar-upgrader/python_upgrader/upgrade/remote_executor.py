# remote_executor.py
from contextlib import contextmanager

import paramiko


def run_remote_script(extended_node, script_contents, script_run_command, connection_timeout):
    with remote_client_context(extended_node, connection_timeout) as client:
        print(f"Executing script (first 20 lines): {script_contents.strip().splitlines()[:20]}")
        stdin, stdout, stderr = client.exec_command(script_run_command)

        script_output = stdout.read().decode('utf-8')
        # print(f"Script output: {script_output}")
        print(f"Script stderr: {stderr.read().decode('utf-8')}")

        return script_output


def get_proxy_client_channel(extended_node, connection_timeout):
    host = extended_node.get('host')
    proxy_host = extended_node.get("proxy").get('host')
    proxy_ssh_user = extended_node.get("proxy").get('ssh_user')
    proxy_ssh_private_key_file_path = extended_node.get("proxy").get("ssh_private_key_file_path")

    proxy_client = paramiko.SSHClient()
    try:
        proxy_client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        proxy_client.connect(proxy_host, port=22, username=proxy_ssh_user, key_filename=proxy_ssh_private_key_file_path,
                             timeout=connection_timeout, banner_timeout=connection_timeout, auth_timeout=connection_timeout)
        # Create a transport over the SSH connection to the remote server via the proxy
        transport = proxy_client.get_transport()
        proxy_channel = transport.open_channel("direct-tcpip", (host, 22), ('localhost', 0))
    except Exception:
        # close client on exception
        proxy_client.close()
        raise

    return proxy_client, proxy_channel


@contextmanager
def remote_client_context(extended_node, connection_timeout):
    proxy_client = None

    host = extended_node.get('host')
    ssh_user = extended_node.get('ssh_user')
    ssh_private_key_file_path = extended_node.get('ssh_private_key_file_path')
    client = paramiko.SSHClient()

    try:
        proxy_channel = None
        if extended_node.get('proxy'):
            proxy_client, proxy_channel = get_proxy_client_channel(extended_node, connection_timeout)

        client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        client.connect(host, port=22, username=ssh_user, key_filename=ssh_private_key_file_path,
                       sock=proxy_channel, timeout=connection_timeout, banner_timeout=connection_timeout,
                       auth_timeout=connection_timeout)

        yield client
    finally:
        client.close()
        if proxy_client:
            proxy_client.close()
