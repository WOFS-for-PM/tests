#!/usr/bin/env python3
import os
import subprocess
from subprocess import Popen
import threading
import time

class NVMSimulator(object):    
    def __init__(self) -> None:
        self.qemu_path = "/home/deadpool/HUNTER-REPO/simulators/qemu"

    def start_qemu(self):
        start_qemu_cmd = ["bash", "setup-x86.sh", "-r", "k"]
        
        os.chdir(self.qemu_path)
        
        self.proc = Popen(start_qemu_cmd, 
                          stdout = subprocess.PIPE,
                          stderr = subprocess.STDOUT,
                          stdin = subprocess.PIPE)
        # Accumulated output as a string
        self.output = ""
        # Accumulated output as a bytearray
        self.outbytes = bytearray()
        self.on_output = []

        # Activate console
        while True: 
            self.handle_read()
            if self.output.find("Please press Enter to activate this console.") != -1:
                self.write("\n") 
            if self.output.find("/ #") != -1:
                break

    def handle_read(self):
        buf = os.read(self.proc.stdout.fileno(), 4096)
        self.outbytes.extend(buf)
        self.output = self.outbytes.decode("utf-8", "replace")
        for callback in self.on_output:
            callback(buf)
        if buf == b"":
            self.wait()
    
    def wait(self):
        if self.proc:
            self.proc.wait()
            self.proc = None

    def write(self, buf):
        if isinstance(buf, str):
            buf = buf.encode('utf-8')
        self.proc.stdin.write(buf)
        self.proc.stdin.flush()

    def get_output(self):
        return self.output

    def kill(self):
        if self.proc:
            self.proc.terminate()
            
    def run_test(self, script, terminal_match = None):
        with open(script, "r") as f:
            lines = f.readlines()
            
            for line in lines:
                self.write(line)
                self.write("\n")            
            
            if terminal_match == None:
                terminal_match = "# SLEEP FOR WHILE"
                time.sleep(1)    
        while True:
            self.handle_read()
            if self.output.find(terminal_match) != -1:
                self.output = self.output.replace(terminal_match, "")
                break

simulator = NVMSimulator()

simulator.start_qemu()

simulator.run_test("/home/deadpool/HUNTER-REPO/tests/qemu/scripts/mount-simfs.sh", None)
simulator.run_test("/home/deadpool/HUNTER-REPO/tests/qemu/scripts/fio.sh", "Disk stats (read/write):")

print(simulator.get_output())