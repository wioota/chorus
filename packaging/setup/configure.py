import os
import re
import rpm
from options import options
from installer_io import io
from log import logger

class Configure:
    def __init__(self):
        self.method = {1:self.enable_alpine_agent}
        ts = rpm.TransactionSet()
        mi = ts.dbMatch('name', 'chorus')
        self.chorus_version = None
        for h in mi:
            self.chorus_version = h['name'] + "-" + h['version']
        self.alpine_version = None
        mi = ts.dbMatch('name', 'alpine')
        for h in mi:
            self.alpine_version = h['name'] + "-" + h['version']

    def get_chorus_state(self):
        if self.chorus_version is None:
            service_state = "Not installed"
        elif self._chorus_pid_exist("jetty.pid") and self._chorus_pid_exist("nginx.pid")\
                and self._chorus_pid_exist("scheduler.production.pid") and self._chorus_pid_exist("solr-production.pid")\
                and self._chorus_pid_exist("worker.production.pid"):
            service_state = "running"
        elif self._chorus_pid_exist("jetty.pid") or self._chorus_pid_exist("nginx.pid")\
                or self._chorus_pid_exist("scheduler.production.pid") or self._chorus_pid_exist("solr-production.pid")\
                or self._chorus_pid_exist("worker.production.pid"):
            service_state = "partially running"
        else:
            service_state = "stopped"
        return service_state

    def get_alpine_state(self):
        if self.alpine_version is None:
           service_state = "Not installed"
        elif self._alpine_pid_exist("alpine.pid"):
           service_state = "running"
        else:
           service_state = "stopped"
        return service_state

    def _chorus_pid_exist(self, pid_name):
        return os.path.exists(os.path.join(options.chorus_path, "shared/tmp/pids/" + pid_name))

    def _alpine_pid_exist(self, pid_name):
        return os.path.exists(os.path.join(options.chorus_path, "alpine-current/" + pid_name))

    def config_chorus_properties(self):
        contents = ""
        chorus_properties = os.path.join(options.chorus_path, "shared/chorus.properties")
        with open(chorus_properies, "r") as f:
            contents = f.read()

    def enable_alpine_agent(self):
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

        agents = io.require_selection("which alpine agent you want to enable(The choice you don't choose will be disabled)?\n"\
                                      + "By default, will enable all:\n"
                                      + agents_str, range(1, idx), default=range(1, idx))

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

    def config(self):
        print "**************************************************"
        if self.chorus_version is None:
            print "Chorus Not Detected"
        else:
            print "Chorus Detected:\t" + self.chorus_version
            print "Chorus Service State:\t" + self.get_chorus_state()
        if self.alpine_version is None:
            print "Alpine Not Detected"
        else:
            print "Alpine Detected:\t" + self.alpine_version
            print "Alpine Service State:\t" + self.get_alpine_state()
        print "**************************************************"
        while True:
            selection = io.require_menu("choose the configuration you want to change: (default is exit)\n" \
                                        + "1. Enable/Disable Alpine Agents\n" \
                                        + "2. Enable HTTPS for webserver\n" \
                                        + "3. Configure Kerberos settings\n" \
                                        + "4. Configure LDAP settings\n" \
                                        + "5. Exit\n", [1,2,3,4,5], default=5)
            if selection == 5:
                break
            self.method[selection]()
            if io.require_confirmation("continue changing other configuration?", default="no"):
                continue
            else:
                break
        logger.info("Run chorus_control.sh restart to affect the change of configuration.")
configure = Configure()
