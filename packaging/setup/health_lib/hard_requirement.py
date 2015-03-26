import os
import sys
import re
import socket
import platform
import xml.etree.ElementTree as ET
sys.path.append("..")
from log import logger
from chorus_executor import ChorusExecutor
from func_executor import processify
executor = ChorusExecutor()

def a_check_os_system():
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

def b_check_runing_user():
    @processify(msg="->Checking Running User...")
    def check():
        if os.getuid() == 0:
            raise Exception("Please don't run this program as root")
    check()

def c_check_java_version():
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

def d_check_open_port():
    from configParser import ConfigParser
    from options import options, get_version
    def get_ports():
        config = None
        if os.path.exists(os.path.join(options.chorus_path, "shared/chorus.properties")):
            config = ConfigParser(os.path.join(options.chorus_path, "shared/chorus.properties"))
        else:
            config = ConfigParser(os.path.join(options.chorus_path, \
                                               'releases/%s/config/chorus.defaults.properties' %\
                                               get_version(options.chorus_path)))
        ports = {}
        ports["server_port"] = config["server_port"]
        ports["postgres_port"] = config["postgres_port"]
        ports["solr_port"] = config["solr_port"]
        ports["workflow.url"] = config["workflow.url"].split(":")[-1]
        if config.has_key("ssl.enabled") and config["ssl.enabled"].lower() == "true":
            ports["ssl_server_port"] = config["ssl_server_port"]
        tree = ET.parse(os.path.join(options.chorus_path, "releases/%s/vendor/jetty/jetty.xml" % get_version(options.chorus_path)))
        root = tree.getroot()
        for e in root.findall('./Call/Arg/New/Set'):
            if e.attrib.has_key('name') and e.attrib['name'] == "port":
                ports["jetty_port"] = e.text
        return ports
    @processify(msg="->Checking Open Ports...")
    def check():
        try:
            ports = get_ports()
            for key in ports:
                port = int(ports[key])
                sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                result = sock.connect_ex(("localhost", port))
                if result == 0:
                    sock.close()
                    msg = "%s: %s is Occupied, \n" % (key, ports[key])
                    if key in ["server_port", "postgres_port", "solr_port", "workflow.url", "ssl_server_port"]:
                        msg += "Please change the %s in %s\nto a non-occupied port or kill the process that occupied %s" % \
                                (key, os.path.join(options.chorus_path, "shared/chorus.properties"), ports[key])
                    elif key in ["jetty_port"]:
                        msg += "Please change the %s in %s\nto a non-occupied port or kill the process that occupied %s" % \
                                (key, os.path.join(options.chorus_path, "current/vendor/jetty/jetty.xml"), ports[key])
                    raise Exception(msg)
        except socket.gaierror as e:
            raise Exception(e)
        except socket.error as e:
            raise Exception(e)
    check()
