import sys
import signal
from options import arg, options
from chorus_setup import chorus_set, failover
from health_check import health_check
from configure import configure
from log import logger
import traceback

handler = {"setup":chorus_set.setup, "health_check":health_check, "configure":configure.config}
def exit_gracefully(signum, frame):
    print "\nSetup aborted, Cancelled by user"
    failover()
    sys.exit(1)
def main():
    try:
        signal.signal(signal.SIGINT, exit_gracefully)
        handler[arg]()
    except Exception as e:
        logger.error(traceback.format_exc())
        logger.error("Exception Occured, see %s/install.log for details" % options.chorus_path.rstrip("/"))
        failover()
