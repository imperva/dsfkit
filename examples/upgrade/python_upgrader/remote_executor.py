import paramiko


def _run_remote_script(remote_host, remote_user, remote_key_filename, remote_script, proxy_channel):
    remote_client = paramiko.SSHClient()
    remote_client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    remote_client.connect(remote_host, port=22, username=remote_user, key_filename=remote_key_filename, sock=proxy_channel)

    # Execute the SSH script on the remote server
    stdin, stdout, stderr = remote_client.exec_command(remote_script)

    script_output = stdout.read().decode('utf-8')
    # print(f"Script output: {script_output}")

    remote_client.close()

    return script_output


def run_remote_script(remote_host, remote_user, remote_key_filename, remote_script):
    return _run_remote_script(remote_host, remote_user, remote_key_filename, remote_script, 'None')


def run_remote_script_via_proxy(remote_host, remote_user, remote_key_filename, remote_script, proxy_host, proxy_user, proxy_key_filename):
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

    script_output = _run_remote_script(remote_host, remote_user, remote_key_filename, remote_script, proxy_channel)

    proxy_client.close()

    return script_output

