import subprocess
def health_check(args=''):
    command = "%s %s" % (os.path.join(os.path.abspath(__file__), "atk"), args)
    p = subprocess.Popen("", shell=True, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    stdout, stderr = p.communicate()
    print  stdout
    print stderr
    return p.returncode, stdout, stderr
