import sys
import signal
from options import arg, health_args, options
from chorus_setup import chorus_set, failover
from health_check import health_check, hard_require
from configure import configure
from log import logger
from color import bold, error
import traceback

handler = {"setup":chorus_set.setup, "health_check":health_check, "configure":configure.config}
def exit_gracefully(signum, frame):
    print "\nSetup aborted, Cancelled by user"
    failover()
    sys.exit(1)
def main():
    try:
        signal.signal(signal.SIGINT, exit_gracefully)

        if (arg == "setup" and not options.disable_spec) \
           or (arg == "health_check" and (health_args == [] or "checkos" in health_args)):
            logger.info(bold("System Specification Checking:"))
            hard_require()

        if arg == "health_check":
            handler[arg](" ".join(health_args))
        else:
            handler[arg]()
    except Exception as e:
        logger.error(error(str(e) + "\nException Occured, see %s/install.log for details" % options.chorus_path.rstrip("/")))
        logger.debug(traceback.format_exc())
        failover()
