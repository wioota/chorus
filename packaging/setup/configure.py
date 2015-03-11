import os
import re
from options import options
from installer_io import io
from log import logger

class Configure:
    def __init__(self):
        pass
    def is_alpine_installed(self):
        if os.path.exists(os.path.join(options.chorus_path, "alpine-releases")):
            return True
        return False

    def config_alpine_conf(self):
        contents = ""
        alpine_conf = os.path.join(options.chorus_path, "shared/ALPINE_DATA_REPOSITORY/configuration/alpine.conf")
        with open(alpine_conf, "r") as f:
            contents = f.read()
        content = re.match(r"(.*)( .*agent.*})(.*})", contents, re.DOTALL).groups()[1]
        dic = {}
        idx = 1
        for line in content.split("\n"):
            if "enabled" in line:
                dic[idx] = line.split("#")[-1].strip()
                idx += 1
        agents_str = "\n".join( str(e) + ". " + dic[e] for e in dic.keys()) + "\n"\
                + "input the number(multiple agents using ',' to seperate)"

        agents = io.require_selection("which alpine agent you want to enable? By default, will enable all:\n"
                                      + agents_str, range(1, idx), default=range(1, idx))

        replace = ""
        idx = 1
        for line in content.split("\n"):
            line = line.lstrip().lstrip("#")
            if "enabled" in line:
                line = "\t%d.enabled=%s\t# %s" % (idx, str(idx in agents).lower(), dic[idx])
                idx += 1
            replace += line + "\n"
        contents = contents.replace(content, replace)
        with open(alpine_conf, "w") as f:
            f.write(contents)
        logger.info(str([dic[agent] for agent in agents]) + " is enabled.")
        logger.info("For more advanced configuration, change %s manually" % alpine_conf)
    def config(self):
        self.config_alpine_conf()

configure = Configure()
