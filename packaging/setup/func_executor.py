import threading
import sys
import time
from multiprocessing import Process, Queue

def processify(msg=''):

    def wrap(func):
        def process_func(q, *args, **kwargs):
            try:
                ret = func(*args, **kwargs)
            except Exception as e:
                ret = None
                error = e
            else:
                error = None
            q.put((ret, error))
        def wrapper(*args, **kwargs):
            q = Queue()
            p = Process(target=process_func, args=[q]+list(args), kwargs=kwargs)
            p.start()
            print msg
            while p.is_alive():
                sys.stdout.write(".")
                sys.stdout.flush()
                time.sleep(2)
            ret, error = q.get()
            if error:
                print
                raise Exception(error)
            print "\r" + "." * 60 + "[Done]"
            return ret
        return wrapper
    return wrap

@processify(msg='processing...')
def worker():
    time.sleep(10)




