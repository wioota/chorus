import os
import sys
import re
sys.path.append("..")
def enable_https():
    from installer_io import InstallIO
    from chorus_executor import ChorusExecutor
    from options import options
    from log import logger
    io = InstallerIO(options.silent)
    executor = ChorusExecutor(options.chorus_path)
    server_key = os.path.join(os.path.join(options.chorus_path, "shared/server.key"))
    server_csr = os.path.join(os.path.join(options.chorus_path, "shared/server.csr"))
    executor.run("openssl genrsa -des3 -out %s 1024" % server_key)
    ret = executor.call("openssl req -new -key %s -out %s" % (server_key, server_csr))
    if ret != 0:
        logger.error("failed to enable https, try again.")
        return
    server_key_org = os.path.join(os.path.join(options.chorus_path, "shared/server.key.org"))
    executor.run("cp %s %s" % (server_key, server_key_org))
    executor.run("openssl rsa -in %s -out %s" % (server_key_org, server_key))
    server_crt = os.path.join(os.path.join(options.chorus_path, "shared/server.crt"))
    executor.run("openssl x509 -req -days 365 -in %s -signkey %s -out %s" % \
                 (server_csr, server_key, server_crt))

    port = io.prompt_int("Which port you want to use for https?", default=8443)

    with open(os.path.join(options.chorus_path, "shared/chorus.properties"), "a") as f:
        f.write("ssl.enabled= true\n"\
                + "ssl_server_port= %d\n" % port\
                + "ssl_certificate= %s\n" % server_crt\
                + "ssl_certificate_key= %s" % server_key)
        contents = ""
        alpine_conf = os.path.join(options.chorus_path, "shared/ALPINE_DATA_REPOSITORY/configuration/alpine.conf")
    with open(alpine_conf, "r") as f:
        contents = f.read()
        content = re.findall(r"chorus *{(.*?)}", contents, re.DOTALL)[0]
        replace = "active = true\n" + "scheme = HTTPS\n" + "port = %d\n" % port
        contents = contents.replace(content, replace)
    with open(alpine_conf, "w") as f:
        f.write(contents)
        logger.info("https has been configured successfully on port %d" % port)
