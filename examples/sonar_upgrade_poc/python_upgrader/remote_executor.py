# remote_executor.py

import paramiko


def run_remote_script(remote_host, remote_user, remote_key_filename, script_contents, script_run_command):
    return _run_remote_script(remote_host, remote_user, remote_key_filename, script_contents, script_run_command, None)


def run_remote_script_via_proxy(remote_host, remote_user, remote_key_filename, script_contents, script_run_command,
                                proxy_host, proxy_user, proxy_key_filename):
    proxy_channel, proxy_client = _connect_to_proxy(proxy_host, proxy_key_filename, proxy_user, remote_host)
    script_output = _run_remote_script(remote_host, remote_user, remote_key_filename, script_contents,
                                       script_run_command, proxy_channel)
    proxy_client.close()
    return script_output


def _connect_to_proxy(proxy_host, proxy_key_filename, proxy_user, remote_host):
    proxy_client = paramiko.SSHClient()
    # Automatically add the remote host's public key to the 'known_hosts' file of the proxy, if not there already,
    # the first time the proxy connects to the remote host connects
    proxy_client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    # Connect to the proxy server
    proxy_client.connect(proxy_host, port=22, username=proxy_user, key_filename=proxy_key_filename)
    # Create a transport over the SSH connection to the remote server via the proxy
    transport = proxy_client.get_transport()
    proxy_channel_type = "direct-tcpip"
    dest_addr = (remote_host, 22)
    local_addr = ('localhost', 0)  # Local address on the proxy server
    proxy_channel = transport.open_channel(proxy_channel_type, dest_addr, local_addr)
    return proxy_channel, proxy_client


def _run_remote_script(remote_host, remote_user, remote_key_filename, script_contents, script_run_command,
                       proxy_channel):
    remote_client = paramiko.SSHClient()
    remote_client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    remote_client.connect(remote_host, port=22, username=remote_user, key_filename=remote_key_filename,
                          sock=proxy_channel)

    print(f"Executing script (first 20 lines): {script_contents.strip().splitlines()[:20]}")
    stdin, stdout, stderr = remote_client.exec_command(script_run_command)

    script_output = stdout.read().decode('utf-8')
    # print(f"Script output: {script_output}")
    print(f"Script stderr: {stderr.read().decode('utf-8')}")

    remote_client.close()

    return script_output

