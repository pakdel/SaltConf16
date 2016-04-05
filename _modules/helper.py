# -*- coding: utf-8 -*-

# https://github.com/saltstack/salt/issues/21397
# https://github.com/saltstack/salt/pull/22025/files

import salt.utils
import sys
import time
# import logging
# log = logging.getLogger(__name__)
#
# if sys.platform.startswith('linux'):
#     import ctypes
#     ctypes.CDLL('libc.so.6').__res_init(None)

def __virtual__():
    return sys.platform.startswith('linux')

def reload_resolv_conf():
    # log.info('Forced Lazy Loading')
    salt.utils.res_init()

def dns_sequence():
	return int(time.time()/100)
