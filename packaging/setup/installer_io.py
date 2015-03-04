import sys
from options import options
class InstallerIO:
    """
        chorus installer io class
    """
    def __init__(self, silent=False):
        self.silent = silent

    def prompt(self, msg, default=False):
        while True:
            sys.stdout.write(msg + ":")
            if not self.silent:
                inputs = raw_input()
            else:
                print
                return None
            if not default and inputs == '':
                continue
            else:
                return inputs

    def require_confirmation(self, msg, default="yes"):
        valid = {"yes": True, "y": True, "ye": True, "no": False, "n": False}
        if default is None:
            prompt = " [y/n] "
        elif default == "yes":
            prompt = " [Y/n] "
        elif default == "no":
            prompt = " [y/N] "
        else:
            raise ValueError("invalid default answer: '%s'" % default)
        while True:
            sys.stdout.write(msg + " " + prompt)
            if not self.silent:
                choice = raw_input()
            else:
                print default
                return valid[default]
            if default is not None and choice == '':
                return valid[default]
            elif choice.lower() in valid:
                return valid[choice]
            else:
                print "Please respond with 'yes' or 'no' (or 'y' or 'n')"

io = InstallerIO(options.silent)
