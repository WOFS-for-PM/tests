#!/usr/bin/env python3
from copy import copy
import os
import sys
from enum import Enum
import re
import shutil

class KObject(Enum):
    arch = 1
    block = 2
    certs = 3
    crypto = 4
    drivers = 5
    fs = 6
    init = 7
    kernel = 8
    ipc = 9
    lib = 10
    mm = 11
    net = 12
    security = 13
    sound = 14
    tools = 15
    virt = 16
    
    @staticmethod
    def get_object_by_name(name):
        for k in KObject:
            if k.name == name:
                return k
        return None

class SrcCode(object):
    def __init__(self) -> None:
        self.code_dir_path = "/home/deadpool/HUNTER-REPO/simfs"
        self.code_object = KObject.get_object_by_name("fs")
    
    def update_makefile(self, target_dir_path):
        makefile_path = os.path.join(target_dir_path, "Makefile")
        print("makefile_path: " + makefile_path)
        with open(makefile_path, "r") as f:
            lines = f.readlines()
            for i in range(len(lines)):
                line = lines[i]
                if line.startswith("obj-m"):
                    lines[i] = line.replace("obj-m", "obj-y")
            
            lines_copy = copy(lines)
            for line_copy in lines_copy:
                if line_copy.find("make") != -1:
                    lines.remove(line_copy)
                if re.match("[a-zA-Z]+:", line_copy, flags = 0):
                    lines.remove(line_copy)
            lines_copy = []
        
        with open(makefile_path, "w") as f:
            f.writelines(lines)

class KernelTree(object):
    def __init__(self) -> None:
        self.kernel_src_path = os.path.abspath(os.path.join(sys.argv[0], os.path.pardir, os.path.pardir, os.path.pardir, "simulators/qemu/downloads/Kernel/linux-5.1"))

    def get_object_path(self, kobj):
        return os.path.join(self.kernel_src_path, kobj.name)

    def incorporate_code_into_kernel(self, src : SrcCode):
        code_dir_path = src.code_dir_path
        code_object = src.code_object
        code_name = os.path.basename(code_dir_path)
        target_dir = self.get_object_path(code_object) + "/" + code_name
        if os.path.exists(target_dir):
            shutil.rmtree(target_dir)
        shutil.copytree(code_dir_path, target_dir)
        return target_dir

    def update_makefile(self, src : SrcCode, mode = "add"):
        code_dir_path = src.code_dir_path
        code_object = src.code_object
        code_name = os.path.basename(code_dir_path)
        object_path = self.get_object_path(code_object)
        makefile_path = os.path.join(object_path, "Makefile")
        
        if mode == "clean":
            with open(makefile_path, "r") as f:
                lines = f.readlines()
                for line in lines:
                    if line.find(code_name) != -1:
                        lines.remove(line)
                        break
            with open(makefile_path, "w") as f:
                f.writelines(lines)

        elif mode == "add":
            is_exist = False
            with open(makefile_path, "r") as f:
                lines = f.readlines()
                for line in lines:
                    if line.find(code_name) != -1:
                        is_exist = True
                        break
            if not is_exist:
                with open(makefile_path, "a") as f:
                    f.write("obj-y +=" + code_name + "/\n")

k_tree = KernelTree()
src_tree = SrcCode()

target_dir_path = k_tree.incorporate_code_into_kernel(src_tree)
k_tree.update_makefile(src_tree, "add")
src_tree.update_makefile(target_dir_path)


# k_tree.update_makefile(src_tree, "clean")
