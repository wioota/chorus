from optparse import OptionParser
import os, sys
def get_options(args):
    usage = "usage: %prog setup | health_check | configure [options]\n" \
            + "\tsetup: setup the chorus and alpine if exist\n" \
            + "\thealth_check: check the system health for chorus and alpine\n" \
            + "\tconfigure: configure the chorus property and alpine property\n"
    parser = OptionParser(usage=usage)

    parser.add_option('--chorus_path', action="store", dest="chorus_path",
                      help="provide the chorus installation path [default: %default]", default="/usr/local/chorus")
    parser.add_option('--data_path', action="store", dest="data_path",
                      help="provide the chorus data path [default: %default]", default="/data/chorus")
    parser.add_option('--disable_spec', action="store_true", dest="disable_spec",
                      help="disable the spec check [default: %default]", default=False)
    parser.add_option('-s', '--silent', action="store_true", dest="silent",
                      help="runing script silently [default: %default]", default=False)
    parser.add_option('-v', '--verbose', action="store_true", dest="verbose",
                      help="product debug output [default: %default]", default=False)
    options, args = parser.parse_args(args)
    if len(args) != 2 or args[1] not in ["setup", "health_check", "configure"]:
        parser.print_help()
        quit()
    return options, args[1]


def get_version():
    version = ""
    with open(os.path.join(options.chorus_path, "version_build"), "r") as f:
        version = f.read().strip()
    return version

options, arg = get_options(sys.argv)
