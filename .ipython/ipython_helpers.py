
def common_apis(*args):
    """
    Find a common subset of public attributes between all the given args
    """
    return reduce(lambda r,e: r & e, [set([k for k in clazz.__dict__.keys() if k[0] != '_']) for clazz in args])


def elapsed(f):
    """
    print the elapsed time while running the given callable
    """
    from datetime import datetime
    start = datetime.utcnow()
    f()
    print('elapsed: %f' % (datetime.utcnow() - start).total_seconds())


def histtime(f, time=5.0):
    """
    Run the given callable as many times as possible in the allotted time, and print statistics on how long it took to run
    """
    import pandas
    from datetime import datetime,timedelta
    start = datetime.utcnow()
    finish_by = start + timedelta(seconds = time)
    times = []
    while True:
        if start > finish_by:
            break
        try:
            f()
        except:
            pass
        prev = start
        start = datetime.utcnow()
        times.append((start - prev).total_seconds())
    print pandas.Series(times).describe(percentiles = [ 0.25, 0.5, 0.75, 0.9, 0.95, 0.99, 0.999 ])


def get_exception(f):
    """
    Easy way to get an exception thrown by the given callable
    """
    try:
        return f()
    except Exception as e:
        return e
