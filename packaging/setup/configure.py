import os
import re
import rpm
import pkgutil
import inspect
import config_lib
from options import options
from installer_io import io
from log import logger

class Configure:
    def __init__(self):
        pass

    def _version_detect(self):
        ts = rpm.TransactionSet()
        mi = ts.dbMatch('name', 'chorus')
        self.chorus_version = None
        for h in mi:
            self.chorus_version = h['name'] + "-" + h['version']
        self.alpine_version = None
        mi = ts.dbMatch('name', 'alpine')
        for h in mi:
            self.alpine_version = h['name'] + "-" + h['version']

    def _load_configure_func(self):
        dic = {}
        idx = 1
        for importer, modname, ispkg in pkgutil.iter_modules(config_lib.__path__):
            module = __import__("config_lib." + modname, fromlist="config_lib")
            for function in inspect.getmembers(module, inspect.isfunction):
                if not inspect.getmodule(function[1]) == module:
                    continue
                dic[idx] = function
                idx += 1
        return dic

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

    def config(self):
        self._version_detect()
        print "*" * 60
        header = ""
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
        print "*" * 60
        if self.chorus_version is None:
            return

        self.method = self._load_configure_func()
        print self.method
        while True:
            lens = len(self.method) + 1
            menu = "\n".join(str(e) + ". " + self.method[e][0] for e in self.method.keys()) + "\n%d. exit\n" % lens
            selection = io.require_menu("choose the configuration you want to change: (default is exit)\n" \
                                        + menu, range(1, lens + 1), default=lens)
            if selection == lens:
                break
            self.method[selection][1]()
            if io.require_confirmation("continue changing other configuration?", default="no"):
                continue
            else:
                break
        logger.info("Run \"chorus_control.sh restart\" to affect the change of configuration.")

configure = Configure()
