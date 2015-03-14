import sys
import os
import re
sys.path.append("..")
from log import logger
from installer_io import io
from options import options

def enable_alpine_agent():
    contents = ""
    alpine_conf = os.path.join(options.chorus_path, "shared/ALPINE_DATA_REPOSITORY/configuration/alpine.conf")
    with open(alpine_conf, "r") as f:
        contents = f.read()

    content = re.findall(r"(#?\s*agent.*{.*?})", contents, re.DOTALL)[0]
    dic = {}
    idx = 1
    for line in content.split("\n"):
        if "enabled" in line:
            dic[idx] = line.split("#")[-1].strip()
            idx += 1

    agents_str = "\n".join( str(e) + ". " + dic[e] for e in dic.keys()) + "\n"\
            + "input the number(multiple agents using ',' to seperate)"

    agents = io.require_selection("which alpine agent you want to enable(The choice you don't choose will be disabled)?\n"\
                                  + "By default, will enable CDH5:\n"
                                  + agents_str, range(1, idx), default=[4])

    replace = ""
    idx = 1
    for line in content.split("\n"):
        line = line.lstrip().lstrip("#")
        if "enabled" in line:
            line = "\t%d.enabled=%s\t# %s" % (idx, str(idx in agents).lower(), dic[idx])
            idx += 1
        replace += line + "\n"
    contents = contents.replace(content, replace.rstrip("\n"))
    with open(alpine_conf, "w") as f:
        f.write(contents)
    logger.info(str([dic[agent] for agent in agents]) + " is enabled.")
    logger.info("For more advanced configuration, change %s manually" % alpine_conf)

