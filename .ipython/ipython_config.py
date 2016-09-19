try:
    c
except NameError:
    c = get_config()

c.InteractiveShellApp.setdefault('exec_lines', [])
c.InteractiveShellApp.exec_lines.extend([
    'import sys, time, dis, os',
])

import IPython
if IPython.version_info > (4,0,0):
    profile_dir = IPython.paths.locate_profile()
else: # should apply to at least IPython 0.13.1-1.2.1
    profile_dir = IPython.utils.path.locate_profile()

c.InteractiveShellApp.setdefault('exec_files', [])
c.InteractiveShellApp.exec_files.extend([
    profile_dir + '/ipython_helpers.py'
])
