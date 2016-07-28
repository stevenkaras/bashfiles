
c.InteractiveShellApp.exec_lines.extend([
    'import sys, time, dis, os',
])

c.InteractiveShellApp.exec_files.extend([
    IPython.paths.locate_profile() + '/ipython_helpers.py'
])
