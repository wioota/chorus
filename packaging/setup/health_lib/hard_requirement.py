import os
import sys
import re
import platform
sys.path.append("..")
from log import logger
from chorus_executor import ChorusExecutor
from func_executor import processify
executor = ChorusExecutor()

def check_runing_user():
    @processify(msg="->Checking Running User...")
    def check():
        if os.getuid() == 0:
            raise Exception("Please don't run this program as root")
    check()

def check_java_version():
    @processify(msg="->Checking Java Version...")
    def check():
        ret, stdout, stderr = executor.run("java -version 2>&1")
        if "command not found" in stdout:
            raise Exception("no java installed, please install ocacle jdk")
        elif "openjdk" in stdout.lower():
            raise Exception("openjdk not supported, please install oracle jdk!")
        else:
            java_version = stdout.split("\n")[0].split(" ")[2].strip("\"").split(".")[0:2]
            java_version = float(".".join(java_version))
            if java_version < 1.6:
                raise Exception("%s\n only support java version > 1.6, please upgrade" % stdout)
    check()

def check_os_system():
    @processify(msg="->Checking OS Version...")
    def check():
        os_name, version, release = platform.linux_distribution()
        if os_name.lower() in ["redhat", "centos"] and re.match(r"^[5|6]", version):
            logger.debug("os version %s-%s-%s" % (os_name, version, release))
        elif os_name.lower() == "suse" and version.startswith(11):
            logger.debug("os version %s-%s-%s" % (os_name, version, release))
        else:
            raise Exception("os version %s-%s-%s not supported!" % (os_name, version, release))
    check()
