import sys, os
import pwd
import re
import shutil
import glob
import hashlib
import hmac
import base64
import platform
from options import options, get_version
from log import logger
from installer_io import InstallerIO
from chorus_executor import ChorusExecutor
from health_check import health_check
from configure import configure
io = InstallerIO(options.silent)
executor = ChorusExecutor(options.chorus_path)

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
        and os.path.exists(os.path.join(options.chorus_path, "shared"))\
        and os.listdir(os.path.join(options.chorus_path, "shared")) != []\
        and os.path.exists(os.path.join(options.data_path, "db")) \
        and os.listdir(os.path.join(options.data_path, "db")) != []
def failover():
    if not upgrade:
        try:
            with open(os.path.join(options.chorus_path, ".failover"), "w") as f:
                f.write("failover")
        except IOError:
            pass

def done():
    print "." * 60 + "[Done]"

class ChorusSetup:
    """
    chorus installer
    """
    def __init__(self):
        self.database_username = None
        self.database_password = None
        self.alpine_installer = None
        self.alpine_release_path = None
        if os.path.exists(failover_file):
           os.remove(failover_file)

    def set_path(self):
        self.release_path = os.path.join(options.chorus_path, 'releases/%s' % get_version(options.chorus_path))
        self.shared = os.path.join(options.chorus_path, "shared")

    def construct_shared_structure(self):
        logger.debug("Construct shared structure in %s" % self.shared)
        self._mkdir_p(self.shared)
        self._mkdir_p(os.path.join(self.shared, "demo_data"))
        self._mkdir_p(os.path.join(self.shared, "libraries"))
        self._mkdir_p(os.path.join(self.shared, "solr"))
        self._mkdir_p(os.path.join(self.shared, "tmp"))
        self._cp_if_not_exist(os.path.join(self.release_path, "packaging/database.yml.example"), \
                              os.path.join(self.shared, "database.yml"))
        self._cp_if_not_exist(os.path.join(self.release_path, "packaging/sunspot.yml.example"), \
                              os.path.join(self.shared, "sunspot.yml"))
        self._cp_if_not_exist(os.path.join(self.release_path, "config/chorus.defaults.properties"), \
                              os.path.join(self.shared, "chorus.properties"))
        os.chmod(os.path.join(self.shared, "chorus.properties"), 0600)
        self._cp_f(os.path.join(self.release_path, "config/chorus.defaults.properties"), \
                   os.path.join(self.shared, "chorus.properties.example"))
        self._cp_f(os.path.join(self.release_path, "config/chorus.license.default"), \
                   os.path.join(self.shared, "chorus.license.default"))
        self._cp_if_not_exist(os.path.join(self.release_path, "config/chorus.license.default"), \
                              os.path.join(self.shared, "chorus.license"))
        os.chmod(os.path.join(self.shared, "chorus.license"), 0600)
        self._cp_f(os.path.join(self.release_path, "config/ldap.properties.active_directory"), \
                   os.path.join(self.shared, "ldap.properties.active_directory"))
        self._cp_f(os.path.join(self.release_path, "config/ldap.properties.opensource_ldap"), \
                   os.path.join(self.shared, "ldap.properties.opensource_ldap"))
        self._cp_if_not_exist(os.path.join(self.release_path, "config/ldap.properties.example"), \
                              os.path.join(self.shared, "ldap.properties"))
        os.chmod(os.path.join(self.shared, "ldap.properties"), 0600)

    def construct_data_structure(self):
        logger.debug("Construct data structure in %s" % options.data_path)
        for folder in ["db","system","log","solr/data"]:
            executor.run("mkdir -p %s" % os.path.join(options.data_path, folder))

    def link_shared_config(self):
        logger.debug("Linking shared configuration files to %s/config" % self.release_path)
        self._ln_sf(os.path.join(self.shared, "chorus.properties"), \
                   os.path.join(self.release_path, "config/chorus.properties"))
        self._ln_sf(os.path.join(self.shared, "chorus.license"), \
                   os.path.join(self.release_path, "config/chorus.license"))
        self._ln_sf(os.path.join(self.shared, "database.yml"), \
                   os.path.join(self.release_path, "config/database.yml"))
        self._ln_sf(os.path.join(self.shared, "sunspot.yml"), \
                   os.path.join(self.release_path, "config/sunspot.yml"))
        self._ln_sf(os.path.join(self.shared, "ldap.properties"), \
                   os.path.join(self.release_path, "config/ldap.properties"))
        self._ln_sf(os.path.join(self.shared, "demo_data"), \
                   os.path.join(self.release_path, "demo_data"))

    def link_data_folder(self):
        logger.debug("Linking data folders to %s" % options.data_path)
        os.chmod(os.path.join(options.data_path, "db"), 0700)
        self._ln_sf(os.path.join(options.data_path, "db"), \
                   os.path.join(self.shared, "db"))
        self._ln_sf(os.path.join(options.data_path, "log"), \
                   os.path.join(self.shared, "log"))
        self._ln_sf(os.path.join(options.data_path, "solr/data"), \
                   os.path.join(self.shared, "solr/data"))
        self._ln_sf(os.path.join(options.data_path, "system"), \
                   os.path.join(self.shared, "system"))

        self._ln_sf(os.path.join(self.shared, "db"), \
                   os.path.join(self.release_path, "postgres-db"))
        self._ln_sf(os.path.join(self.shared, "log"), \
                   os.path.join(self.release_path, "log"))
        self._ln_sf(os.path.join(self.shared, "solr/data"), \
                   os.path.join(self.release_path, "solr/data"))
        self._ln_sf(os.path.join(self.shared, "tmp"), \
                   os.path.join(self.release_path, "tmp"))
        self._ln_sf(os.path.join(self.shared, "system"), \
                   os.path.join(self.release_path, "system"))
        logger.debug("Linking nginx logs to %s/vendor/nginx/nginx_dist/nginx_data/logs" % self.release_path)
        self._mkdir_p(os.path.join(self.shared, "log/nginx"))
        self._ln_sf(os.path.join(self.shared, "log/nginx"), \
                   os.path.join(self.release_path, "vendor/nginx/nginx_dist/nginx_data/logs"))

        self._ln_sf(os.path.join(self.release_path, "packaging/chorus_control.sh"), \
                   os.path.join(options.chorus_path, "chorus_control.sh"))
        self._ln_sf(os.path.join(self.release_path, "packaging/setup/chorus_server"), \
                   os.path.join(options.chorus_path, "chorus_server"))
        executor.run("chmod -R 0555 %s", os.path.join(self.release_path, "public"))

    def extract_postgres(self):
        logger.debug("Extract postgres database to %s", self.release_path)
        os_name, version, release = platform.linux_distribution()
        if os_name.lower() in ["redhad", "centos"]  and version.startswith("5"):
            executor.extract_postgres("postgres-redhat5.5-9.2.4.tar.gz")
        elif os_name.lower() in ["redhad", "centos"]  and version.startswith("6"):
            executor.extract_postgres("postgres-redhat6.2-9.2.4.tar.gz")
        elif os_name.lower()  == "susu" and version == "11":
            executor.extract_postgres("postgres-suse11-9.2.4.tar.gz")
        else:
            raise Exception("postgres not installed, no version match the operation system")

    def _ln_sf(self, src, dst):
        logger.debug("Link %s to %s" % (src, dst))
        if os.path.lexists(dst):
            if os.path.isdir(dst) and not os.path.islink(dst):
                shutil.rmtree(dst)
            else:
                os.remove(dst)
        os.symlink(src, dst)

    def _mkdir_p(self, path):
        logger.debug("mkdir %s" % path)
        if os.path.exists(path):
            return
        os.makedirs(path)

    def _cp_if_not_exist(self, src, dst):
        logger.debug("cp %s to %s if not exists" % (src, dst))
        if os.path.exists(dst):
            return
        shutil.copyfile(src, dst)

    def _cp_f(self, src, dst):
        logger.debug("cp -f %s to %s" % (src, dst))
        if os.path.exists(dst):
           os.remove(dst)
        shutil.copyfile(src, dst)

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
                                    + "By default, a random key will be generated", default='')
            if passphrase.strip() == '':
                passphrase = os.urandom(32)
            secret_key = base64.b64encode(hmac.new(passphrase, digestmod=hashlib.sha256).digest())
            with open(key_file, 'w') as f:
                f.write(secret_key)
        else:
            logger.debug(key_file + " already existed, skipped")
        logger.info("Configuring secret key...")
        logger.debug("Secure " + key_file)
        os.chmod(key_file, 0600)
        symbolic = os.path.join(self.release_path, "config/secret.key")
        logger.debug("Create symbolic to " + symbolic)
        if os.path.lexists(symbolic):
            os.remove(symbolic)
        os.symlink(key_file, symbolic)
        done()

    def configure_secret_token(self):
        token_file_path = os.path.join(options.chorus_path, "shared")
        token_file = os.path.join(token_file_path, 'secret.token')

        if not os.path.exists(token_file):
            with open(token_file, 'w') as f:
                f.write(os.urandom(64).encode('hex'))
        else:
            logger.debug(token_file + " already existed, skipped")
        logger.info("Configuring secret token...")
        logger.debug("Secure " + token_file)
        os.chmod(token_file, 0600)
        symbolic = os.path.join(self.release_path, "config/secret.token")
        logger.debug("Create symbolic to " + symbolic)
        if os.path.lexists(symbolic):
            os.remove(symbolic)
        os.symlink(token_file, symbolic)
        done()

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
            os.chmod(file_path, 0600)
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
        if os.path.exists(pwfile):
            os.chmod(pwfile, 0600)
        with open(pwfile, "w") as f:
            f.write(self.database_password)
        os.chmod(pwfile, 0400)
        executor.initdb(options.data_path, self.database_username)
        executor.start_postgres()
        db_commands = "db:create db:migrate"
        db_commands += " db:seed"
        db_commands += " enqueue:refresh_and_reindex"
        executor.rake(db_commands)
        executor.stop_postgres()

    def upgrade_database(self):
        executor.start_postgres()
        logger.info("Running database migrations...")
        db_commands = "db:migrate"
        db_commands += " enqueue:refresh_and_reindex"
        logger.debug("Running rake " + db_commands)
        executor.rake(db_commands)
        executor.stop_postgres()

    def validate_data_sources(self):
        logger.info("Running data validation...")
        executor.start_postgres()
        executor.rake("validations:data_source")

    def stop_previous_release(self):
        logger.info("Shutting down previous Chorus install...")
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
        logger.debug("Extracting %s to %s" % (self.alpine_installer, self.alpine_release_path))
        executor.run("sh %s --target %s --noexec" % (self.alpine_installer, self.alpine_release_path))
        logger.debug("Preparing Alpine Data Repository")
        alpine_data_repo = os.path.join(options.chorus_path, "shared/ALPINE_DATA_REPOSITORY")
        if os.path.exists(alpine_data_repo):
            logger.debug("Alpine Data Repository existed, skipped")
        else:
            shutil.copytree(os.path.join(self.alpine_release_path, "ALPINE_DATA_REPOSITORY"), alpine_data_repo)

    def link_current_to_release(self, link_name, rel_path):
        current = os.path.join(options.chorus_path, link_name)
        if os.path.lexists(current):
            os.unlink(current)
        os.symlink(rel_path, current)

    def source_chorus_path(self):
        logger.debug("source %s/chorus_path.sh" % options.chorus_path)
        with open(os.path.join(os.path.expanduser("~"), ".bash_profile"), "a") as f:
            f.write("source %s/chorus_path.sh\n" % options.chorus_path)

    def setup(self):
        self.set_path()
        #if not io.require_confirmation("Do you want to set up the chorus, "
        #                                    + "please make sure you have installed chorus before setting up?"):
        #    logger.fatal("Setup aborted, Cancelled by user")
        #    quit()
        #if not options.disable_spec:
        #    health_check()
        #self.prompt_for_eula()

        #pre step:
        logger.info("Construct Chorus Directory...")
        self.construct_shared_structure()
        self.construct_data_structure()
        self.link_shared_config()
        self.link_data_folder()
        self.extract_postgres()
        self.generate_paths_file()
        done()

        self.configure_secret_key()
        self.configure_secret_token()

        if upgrade:
            logger.info("Updaing postgres database...")
            self.validate_data_sources()
            self.stop_previous_release()
            self.upgrade_database()
        else:
            logger.info("Creating postgres database...")
            self.create_database_config()
            self.generate_chorus_psql_files()
            self.generate_chorus_rails_console_file()
            self.setup_database()
        done()
            #self.enqueue_solr_reindex()
        self.link_current_to_release("current", self.release_path)

        if self.is_alpine_exits():
            msg = "Do you want to extract alpine?"
            if os.path.exists(self.alpine_release_path):
                msg = "%s already exists in your machine, do you want to overwrite it?" % \
                        os.path.basename(self.alpine_release_path.rstrip("/"))
            if io.require_confirmation(msg, default="no"):
                logger.info("Configuring alpine...")
                self.configure_alpine()
                self.link_current_to_release("alpine-current", self.alpine_release_path)
                done()
        #self.source_chorus_path()
        if io.require_confirmation("Do you want to change default configure?", default="no"):
            configure.config()

        print "Completely Setup"
        if upgrade:
            print "Confirm custom configuration settings as directed in the upgrade guide before restarting Chorus."
        print "*" * 60
        print "To start Chorus, run the following commands:"
        print "su - %s" % pwd.getpwuid(os.getuid()).pw_name
        print "source %s/chorus_path.sh" % options.chorus_path
        print "and run chorus_control.sh start"
        print "*" * 60

chorus_set = ChorusSetup()
