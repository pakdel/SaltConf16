#!/usr/bin/env python

baseurl = "http://169.254.169.254/latest/meta-data/"

# Import libs
try:
    import urllib2
    import logging
    logging.getLogger('boto').setLevel(logging.CRITICAL)
    HAS_LIBS = True
    urllib2.urlopen(baseurl, timeout=3)
    HAS_NET = True
except ImportError:
    HAS_LIBS = False
except Exception:
    HAS_NET = False


def __virtual__():
    '''
    Only load if libraries exist.
    '''
    if HAS_LIBS and HAS_NET:
        return True
    return False


log = logging.getLogger(__name__)

def ec2_instance_id():
  '''EC2 Instance ID
 
  CLI Example::
    salt myminion grains.get ec2_instance_id
  '''
  url = baseurl + "instance-id"
  try:
    return {'ec2_instance_id': urllib2.urlopen(url, timeout=3).read()}
  except Exception as e:
    log.error('EC2 instance_id grain: {0}'.format(e))
  return {}
