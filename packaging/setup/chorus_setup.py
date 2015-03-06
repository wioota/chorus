import sys, os
import shutil
import glob
import hashlib
import hmac
import base64
from options import options, get_version
from log import logger
from installer_io import io
from chorus_executor import executor
from health_check import health_check
from configure import configure

CHORUS_PSQL = "\
if [ \"$CHORUS_HOME\" = \"\" ]; then\n\
    echo \"CHORUS_HOME is not set.  Exiting...\"\n\
else\n\
    $CHORUS_HOME/current/postgres/bin/psql -U postgres_chorus -p 8543 chorus;\n\
fi\n"

CHORUS_RAILS_CONSOLE = "\
if [ \"$CHORUS_HOME\" = \"\" ]; then\n\
    echo \"CHORUS_HOME is not set.  Exiting...\"\n\
else\n\
    RAILS_ENV=production $CHORUS_HOME/current/bin/ruby $CHORUS_HOME/current/script/rails console\n\
fi\n"

failover_file = os.path.join(options.chorus_path, ".failover")
upgrade = not os.path.exists(failover_file) \
        and os.path.exists(os.path.join(options.data_path, "db")) \
        and os.listdir(os.path.join(options.data_path, "db")) != []
def failover():
    if not upgrade:
        try:
            with open(os.path.join(options.chorus_path, ".failover"), "w") as f:
                f.write("failover")
        except IOError:
            pass
class ChorusSetup:
    """
    chorus installer
    """
    def __init__(self):
        self.release_path = os.path.join(options.chorus_path, 'releases/%s' % get_version())
        self.database_username = None
        self.database_password = None
        self.alpine_installer = None
        self.alpine_release_path = None
        if os.path.exists(failover_file):
           os.remove(failover_file)

    def _eula_by_brand(self):
        filename = ""
        if os.getenv('PIVOTALLABEL') is None:
            filename = 'eula_alpine.txt'
        else:
            filename = 'eula_emc.txt'
        filename = os.path.join(os.path.dirname(os.path.abspath(__file__)), filename)
        with open(filename, 'r') as f:
            eula = f.read();
        return eula

    def prompt_for_eula(self):
        eula = self._eula_by_brand()
        print eula
        ret = io.require_confirmation("Do you accept the terms above?")
        if not ret:
            logger.fatal("Setup aborted, Cancelled by user")
            quit()

    def configure_secret_key(self):
        key_file_path = os.path.join(options.chorus_path, "shared")
        key_file = os.path.join(key_file_path, 'secret.key')
        if not os.path.exists(key_file):
            passphrase = io.prompt("Enter optional passphrase to generate "
                                    + "a recoverable secret key for encrypting passwords."
                                    + "By default, a random key will be generated", default=True)
            if passphrase is None or passphrase.strip() == '':
                passphrase = os.urandom(32)
            secret_key = base64.b64encode(hmac.new(passphrase, digestmod=hashlib.sha256).digest())
            with open(key_file, 'w') as f:
                f.write(secret_key)
        else:
            logger.debug(key_file + " already existed, skipped")

        logger.info("Secure " + key_file)
        os.chmod(key_file, 0600)
        symbolic = os.path.join(self.release_path, "config/secret.key")
        logger.debug("Create symbolic to " + symbolic)
        if os.path.lexists(symbolic):
            os.remove(symbolic)
        os.symlink(key_file, symbolic)

    def configure_secret_token(self):
        token_file_path = os.path.join(options.chorus_path, "shared")
        token_file = os.path.join(token_file_path, 'secret.token')

        if not os.path.exists(token_file):
            with open(token_file, 'w') as f:
                f.write(os.urandom(64).encode('hex'))
        else:
            logger.debug(token_file + " already existed, skipped")
        logger.info("Secure " + token_file)
        os.chmod(token_file, 0600)
        symbolic = os.path.join(self.release_path, "config/secret.token")
        logger.debug("Create symbolic to " + symbolic)
        if os.path.lexists(symbolic):
            os.remove(symbolic)
        os.symlink(token_file, symbolic)

    def generate_paths_file(self):
        file_path = os.path.join(options.chorus_path, "chorus_path.sh")
        logger.debug("Generating paths file: " + file_path)
        with open(file_path, 'w') as f:
            f.write("export CHORUS_HOME=%s\n" % options.chorus_path)
            f.write("export PATH=$PATH:$CHORUS_HOME\n")
            f.write("export PGPASSFILE=$CHORUS_HOME/.pgpass")

    def generate_chorus_psql_files(self):
        file_path = os.path.join(options.chorus_path, ".pgpass")
        logger.debug("generating chorus_psql files")
        if os.path.exists(file_path):
            logger.debug(file_path + " existed, skipped")
        else:
            with open(file_path, "w") as f:
                f.write("*:*:*:"+ self.database_username + ":" + self.database_password)
        os.chmod(file_path, 0400)

        file_path = os.path.join(options.chorus_path, "chorus_psql.sh")
        if os.path.exists(file_path):
            logger.debug(file_path + " existed, skipped")
        else:
            with open(file_path, "w") as f:
                f.write(CHORUS_PSQL)
        os.chmod(file_path, 0500)

    def generate_chorus_rails_console_file(self):
        file_path = os.path.join(options.chorus_path, "chorus_rails_console.sh")
        logger.debug("generating chorus_rails_console file")
        if os.path.exists(file_path):
            logger.debug(file_path + " existed, skipped")
            return
        with open(file_path, "w") as f:
            f.write(CHORUS_RAILS_CONSOLE)
        os.chmod(file_path,0700)

    def create_database_config(self):
        database_config_file = os.path.join(options.chorus_path, "shared/database.yml")

        content = ""
        with open(database_config_file, 'r') as f:
            lines = f.readlines()
            for i in xrange(0, len(lines)):
                if lines[i].lstrip().startswith("username:"):
                    self.database_username = lines[i].split(":")[1].strip()
                elif lines[i].lstrip().startswith("password:"):
                    if "!binary" in lines[i]:
                        self.database_password = base64.b64decode(lines[i+1].strip())
                        logger.debug("password generated already, skipped")
                        return
                    else:
                        self.database_password = os.urandom(16).encode('hex')
                        lines[i] = lines[i].split(":")[0] + ": !binary |-\n"
                        lines[i] = lines[i] + "    " + base64.b64encode(self.database_password) + "\n"
                if not ":" in lines[i] and not lines[i].startswith("---"):
                    continue
                content += lines[i]
        with open(database_config_file, 'w') as f:
            f.write(content)

    def setup_database(self):
        logger.info("Initializing database...")
        pwfile = os.path.join(self.release_path, "postgres/pwfile")
        if not os.path.exists(pwfile):
            with open(pwfile, "w") as f:
                f.write(self.database_password)
        os.chmod(pwfile, 0400)
        executor.initdb(options.data_path, self.database_username)
        executor.start_postgres()
        db_commands = "db:create db:migrate"
        db_commands += " db:seed"
        db_commands += " enqueue:refresh_and_reindex"
        logger.info("Running rake " + db_commands)
        executor.rake(db_commands)
        executor.stop_postgres()

    def upgrade_database(self):
        executor.start_postgres()
        logger.info("Running database migrations...")
        db_commands = "db:migrate"
        db_commands += " enqueue:refresh_and_reindex"
        logger.info("Running rake " + db_commands)
        executor.rake(db_commands)
        executor.stop_postgres()

    def validate_data_sources(self):
        executor.start_postgres()
        executor.rake("validations:data_source")

    def stop_previous_release(self):
        logger.info("Stopping Chorus...")
        executor.stop_previous_release()

    def is_alpine_exits(self):
        alpine_dir = os.path.join(self.release_path, "vendor/alpine")
        alpine_sources = [ f for f in glob.glob(os.path.join(alpine_dir, "alpine*.sh")) ]
        if len(alpine_sources) <= 0:
            return False
        else:
            alpine_sources.sort(key=lambda x: os.path.getmtime(x), reverse=True)
            self.alpine_installer = alpine_sources[0]
            alpine_version = os.path.basename(self.alpine_installer.rstrip(".sh"))
            self.alpine_release_path = os.path.join(options.chorus_path, "alpine-releases/%s" % alpine_version)
            return True

    def configure_alpine(self):
        logger.info("Extracting %s to %s" % (self.alpine_installer, self.alpine_release_path))
        executor.run("sh %s --target %s --noexec" % (self.alpine_installer, self.alpine_release_path))
        logger.info("Configuring alpine")
        logger.debug("Preparing Alpine Data Repository")
        alpine_data_repo = os.path.join(options.chorus_path, "shared/ALPINE_DATA_REPOSITORY")
        if os.path.exists(alpine_data_repo):
            logger.debug("Alpine Data Repository existed, skipped")
        else:
            shutil.copytree(os.path.join(self.alpine_release_path, "ALPINE_DATA_REPOSITORY"), alpine_data_repo)

        #agents = io.require_selection("which alpine agent you want to enable? \
        #                              By default, will enable all:\n"
        #                              + "1. PHD2.0\n"
        #                              + "2. CDH4\n"
        #                              + "3. MAPR3\n"
        #                              + "4. CDH5\n"
        #                              + "5. HDP2.1\n"
        #                              + "6. MapR4\n", default="all")
        #if agents is None:
        #    logger.debug("alll agents are enabled")
        #    return
        #dic = {1:"PHD2.0", 2:"CDH4", 3:"MAPR3", 4:"CDH5", 5:"HDP2.1", 6:"MapR4"}
        #contents = ""
        #alpine_conf = os.path.join(options.chorus_path, "shared/ALPINE_DATA_REPOSITORY/configuration/alpine.conf")
        #with open(alpine_conf, "r") as f:
        #    index = 0
        #    for line in f:
        #        if "enabled" in line:
        #            if dic[agents[index]] in line:
        #                line = "\t\t%d.enabled=true\t# %s" % (agents[index], dic[agents[index]])
        #                if index + 1 < len(agents)
        #                    index += 1
        #            else:
        #                line = line.replace("true", "false")
        #        contents += line
        #with open(alpine_conf, "w") as f:
        #    f.write(contents)


    def link_current_to_release(self, link_name, rel_path):
        current = os.path.join(options.chorus_path, link_name)
        if os.path.lexists(current):
            os.unlink(current)
        os.symlink(rel_path, current)

    def setup(self):
        if not io.require_confirmation("Do you want to set up the chorus, "
                                            + "please make sure you have installed chorus before setting up?"):
            logger.fatal("Setup aborted, Cancelled by user")
            quit()
        if not options.disable_spec:
            health_check()
        self.prompt_for_eula()

        logger.info("Configuring secret key...")
        self.configure_secret_key()

        logger.info("Configuring secret token...")
        self.configure_secret_token()

        self.generate_paths_file()
        if upgrade:
            logger.info("Updaing database...")
            self.validate_data_sources()
            logger.info("Shutting down previous Chorus install...")
            self.stop_previous_release()
            self.upgrade_database()
        else:
            logger.info("Creating database...")
            self.create_database_config()
            self.generate_chorus_psql_files()
            self.generate_chorus_rails_console_file()
            self.setup_database()
            #self.enqueue_solr_reindex()
        self.link_current_to_release("current", self.release_path)
        if self.is_alpine_exits():
            if io.require_confirmation("Do you want to install alpine?"):
                logger.info("Setting up alpine...")
                self.configure_alpine()
                self.link_current_to_release("alpine-current", self.alpine_release_path)
            else:
                logger.info("alpine is not installed")

        if io.require_confirmation("Do you want to change default configure?", default="no"):
            configure.config()
