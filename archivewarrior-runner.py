#!/usr/bin/env python

import subprocess
import sys
import re

bin_vbox = '/usr/local/bin/VBoxManage'
box = 'archiveteam-warrior-2'

def main():
    state = getState()
    print 'Box "%s" is in state "%s"' % (box, state)
    if state == 'running':
        print 'Already running, nothing to do.'
    elif state == 'powered off' or state == 'saved' or state == 'aborted':
        print 'Starting box...'
        print shell('%s startvm %s --type headless' % (bin_vbox, box))
    else:
        print 'Not implemented'
        sys.exit(1)

def shell(cmd):
    return subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE).stdout.read().strip()

def getState():
    output = shell('%s showvminfo %s | grep State' % (bin_vbox, box))
    match = re.search(r'State: +(.*) \(', output)
    if match:
        return match.group(1)
    print 'Failed to retrieve state of box "%s"' % box
    sys.exit(1)

if __name__ == '__main__':
    main()
