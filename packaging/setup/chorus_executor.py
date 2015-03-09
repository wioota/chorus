import os
import subprocess
from log import logger
from options import options, get_version
class PSQLException(Exception):
    pass

class ChorusExecutor:
    def __init__(self):
        self.release_path = os.path.join(options.chorus_path, 'releases/%s' % get_version())

    def run(self, command, postgres_bin_path=None):
        if postgres_bin_path is None:
            postgres_bin_path = self.release_path
        command = "PATH=%s/postgres/bin:$PATH && %s" % (postgres_bin_path, command)
        logger.debug(command)
        p = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        stdout, stderr = p.communicate()
        if stdout:
            logger.debug(stdout)
        if stderr:
            logger.debug(stderr)
        return stdout, stderr
    def chorus_control(self, command):
       command = "CHORUS_HOME=%s %s %s/packaging/chorus_control.sh %s" % \
               (self.release_path, self.alpine_env(), self.release_path, command)
       return self.run(command)

    def previous_chorus_control(self, command):
        command = "CHORUS_HOME=%s %s %s %s" % \
                (os.path.join(options.chorus_path, "current"), self.alpine_env(),\
                os.path.join(options.chorus_path, "chorus_control.sh"), command)
        self.run(command, os.path.join(options.chorus_path, "current"))

    def alpine_env(self):
        return "ALPINE_HOME=%s/alpine-current ALPINE_DATA_REPOSITORY=%s/shared/ALPINE_DATA_REPOSITORY" % \
                (options.chorus_path, options.chorus_path)

    def start_previous_release(self):
        self.previous_chorus_control("start")

    def stop_previous_release(self):
        #self.previous_chorus_control("stop")
        self.run("killall chorus")
    def start_postgres(self):
        logger.info("Starting postgres...")
        stdout, stderr = self.chorus_control("start postgres")
        if "postgres failed" in stdout:
            raise PSQLException(stdout)

    def stop_postgres(self):
        logger.info("Stopping postgres")
        stdout, stderr = self.chorus_control("stop postgres")
        if "postgres failed" in stdout:
            raise PSQLException(stdout)

    def initdb(self, data_path, database_user):
        command = "initdb --locale=en_US.UTF-8 -D %s/db --auth=md5 --pwfile=%s/postgres/pwfile --username=%s" % \
                (data_path, self.release_path, database_user)
        stdout, stderr = self.run(command)
        if "exists but is not empty" in stderr:
            logger.warning(stderr)

    def rake(self, command):
        command = "cd %s && RAILS_ENV=production bin/ruby -S bin/rake %s --trace" % \
                (self.release_path, command)
        self.run(command)

executor = ChorusExecutor()
