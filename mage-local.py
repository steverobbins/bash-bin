#!/usr/bin/env python

import os
import subprocess
import sys

zettrFile='/Users/steve/.config/zettr/mage-local.csv'
zettrBin='/Users/steve/bin/zettr'

def main():
    if len(sys.argv) != 3:
        showHelp(True)
    applyZettr(sys.argv[1], sys.argv[2])

def applyZettr(env, dbName):
    os.environ['ENV']      = env
    os.environ['DB_NAME']  = dbName
    print shell('%s -vvv --skipEnvMissingError apply %s %s' % (zettrBin, env, zettrFile))

def prepareBaseUrl(string):
    return 'http://%s.127.0.0.1.xip.io/' % string

def showHelp(die = False):
    print
    print '    Usage: %s <html_name> <database_name>' % sys.argv[0]
    print
    print '    Arguments:'
    print
    print '        html_name:     The name of the folder in ~/html used in the browser.  For example, a value'
    print '                       of "foo" will result in a base url setting of "http://foo.127.0.0.1.xip.io/"'
    print
    print '        database_name: The name of the Magento database for app/etc/local.xml (root:root@127.0.0.1)'
    print
    if (die):
        sys.exit(1)

def shell(cmd):
    return subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE).stdout.read().strip()

if __name__ == '__main__':
    main()
