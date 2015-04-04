import os
import platform
import re
import pkgutil
import inspect
import health_lib
from log import logger
from color import bold
from chorus_executor import ChorusExecutor
executor = ChorusExecutor()

def _load_configure_func():
    dic = {}
    idx = 1
    #for importer, modname, ispkg in pkgutil.iter_modules(health_lib.__path__):
    #module = __import__("health_lib." + modname, fromlist="health_lib")
    from health_lib import hard_requirement
    for function in inspect.getmembers(hard_requirement, inspect.isfunction):
        if not inspect.getmodule(function[1]) == hard_requirement:
            continue
        dic[idx] = function
        idx += 1
    return dic

def system_checking(install_mode=False):
    logger.info(bold("Verifying Minimum System Requirements:"))
    for func in _load_configure_func().values():
        if func[0] == "b_check_running_user":
            func[1](install_mode=install_mode)
        else:
            func[1]()

def health_check(args=''):

    if args == '' or args == None:
        args = "checkos"
    if "help" not in args:
        logger.info(bold("Running \"atk %s\" Command:" % args))
    command = "%s %s" % (os.path.join(os.path.dirname(os.path.abspath(__file__)), "health_lib/atk"), args)
    ret, stdout, stderr = executor.run(command + " 2>&1")
    print stdout
    return ret, stdout, stderr

if __name__ == "__main__":
    hard_require()
