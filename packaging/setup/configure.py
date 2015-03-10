import os
from options import options
from installer_io import io
class Configure:
    def __init__(self):
        pass
    def is_alpine_installed(self):
        if os.path.exists(os.path.join(options.chorus_path, "alpine-releases")):
            return True
        return False

    def config_alpine_conf(self):
        agents = io.require_selection("which alpine agent you want to enable? \
                                      By default, will enable all:\n"
                                      + "1. PHD2.0\n"
                                      + "2. CDH4\n"
                                      + "3. MAPR3\n"
                                      + "4. CDH5\n"
                                      + "5. HDP2.1\n"
                                      + "6. MapR4\n", default="all")
        if agents is None:
            logger.debug("all agents are enabled")
            return
        dic = {1:"PHD2.0", 2:"CDH4", 3:"MAPR3", 4:"CDH5", 5:"HDP2.1", 6:"MapR4"}
        contents = ""
        alpine_conf = os.path.join(options.chorus_path, "shared/ALPINE_DATA_REPOSITORY/configuration/alpine.conf")
        with open(alpine_conf, "r") as f:
            index = 0
            for line in f:
                if "enabled" in line:
                    if dic[agents[index]] in line:
                        line = "\t\t%d.enabled=true\t# %s" % (agents[index], dic[agents[index]])
                        if index + 1 < len(agents)
                            index += 1
                    else:
                        line = line.replace("true", "false")
                contents += line
        with open(alpine_conf, "w") as f:
            f.write(contents)

    def config(self):
        pass

configure = Configure()
