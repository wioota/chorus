import os
import sys
sys.path.append("..")
from options import options
def configure_ldap():
    os.system("${EDITOR:-vi} " + os.path.join(options.chorus_path, "shared/ldap.properties"))

