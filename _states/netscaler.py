def __virtual__():
    if 'netscaler.server_exists' in __salt__:
        return 'netscaler'
    else:
        return False

def present(name, ip=None, port=None, type=None, sslcert=None, servicegroup=None, **connection_args):
    '''
    Ensure a lb vserver resource, and everything related to it, is present
    (ie: servicegroup, servers, ssl certificate)
 
    name
        The name of the vserver

    ip
        ip of the vserver

    port
        port of the vserver

    type
        type of the vserver (HTTP, and SSL, are the most common)

    sslcert
        name of the ssl certificate bound to this vserver (if type != SSL it will be ignored)

    servicegroup
        Structure representing the servicegroup tied to the vserver

    Example:

        alex.lbvs.cws.443:
          netscaler.present:
            - ip: 10.121.2.223
            - port: 443
            - type: SSL
            - sslcert: nix.freedom.net
            - servicegroup: 
              name: alex.sg.cws.83
              type: HTTP
              servers:
                alex.cws01:
                  ip: 1.2.3.4
                  port: 83
                  status: enabled
                alex.cws02:
                  ip: 1.2.3.5
                  port: 83
                  status: enabled
    '''
    ret = {'name': name,
           'changes': {},
           'result': True,
           'comment': 'vserver {0} is already present'.format(name)}

    if __opts__['test']:
        ret['result'] = None
        ret['comment'] = ''
        if not __salt__['netscaler.vserver_exists'](name, ip, port, type, **connection_args):
            ret['comment'] = 'vserver "{0}" does not exist.'.format(name)
        if type.upper() == 'SSL' \
            and sslcert is not None \
            and not __salt__['netscaler.vserver_sslcert_exists'](name, sslcert, **connection_args):
            ret['comment'] += '"{0}" SSL certificate does not exist.'.format(sslcert)
        if servicegroup is not None:
            sg_name = servicegroup.get('name', None)
            sg_type = servicegroup.get('type', None)
            if not __salt__['netscaler.servicegroup_exists'](sg_name, sg_type, **connection_args):
                ret['comment'] += 'servicegroup "{0}" does not exist.'.format(sg_name)
            elif not __salt__['netscaler.vserver_servicegroup_exists'](name, sg_name, **connection_args):
                ret['comment'] += 'vserver "{0}" is not bound to servicegroup {1}.'.format(name, sg_name)
            servers = servicegroup.get('servers', {})
            for server, attrs in servers.iteritems():
                s_name = server
                s_ip = attrs.get('ip', None)
                s_port = attrs.get('port', None)
                s_status = attrs.get('status', None)
                if not __salt__['netscaler.server_exists'](s_name, s_ip, **connection_args):
                    ret['comment'] += 'server "{0}" does not exist.'.format(s_name)
                elif not __salt__['netscaler.servicegroup_server_exists'](sg_name, s_name, s_port, **connection_args):
                    ret['comment'] += 'server "{0}" is not bound to servicegroup {1}.'.format(s_name, sg_name)
        if ret['comment'] == '':
            ret['comment'] = 'vserver {0} is already present and up to date'.format(name)
        return ret

    # TODO: support updates
    if not __salt__['netscaler.vserver_exists'](name, ip, port, type, **connection_args):
        # Add vserver 
        if not __salt__['netscaler.vserver_add'](name, ip, port, type, **connection_args):
            ret['comment'] = 'failed to add vserver {0}'.format(name)
            ret['result'] = False
        else:
            ret['comment'] = 'added vserver {0}'.format(name)
            ret['changes'][name] = 'Present'

    # SSL cert check
    if type.upper() == 'SSL' and sslcert is not None:
        if not __salt__['netscaler.vserver_sslcert_exists'](name, sslcert, **connection_args):
            if not __salt__['netscaler.vserver_sslcert_add'](name, sslcert, **connection_args): 
                 ret['comment'] += ' && failed to bind ssl certificate {0} to it'.format(sslcert, name)
                 ret['result'] = False
                 return ret
            else:
                 ret['comment'] += ' && ssl certificate {0} is now bound to it'.format(sslcert,name)
                 ret['changes'][name] = 'Present'

    # Servicegroup check
    if servicegroup is not None:
        sg_name = servicegroup.get('name', None)
        sg_type = servicegroup.get('type', None)
        # Check if service group exists
        if not __salt__['netscaler.servicegroup_exists'](sg_name, sg_type, **connection_args):
            # Add service group
            if not __salt__['netscaler.servicegroup_add'](sg_name, sg_type, **connection_args):
                ret['comment'] += ' && failed to create servicegroup {0}'.format(sg_name)
                ret['result'] = False
                return ret
            else:
                ret['comment'] += ' && created servicegroup {0}'.format(sg_name)
        
        # Check if service group is tied to vserver
        if not __salt__['netscaler.vserver_servicegroup_exists'](name, sg_name, **connection_args):
            if not __salt__['netscaler.vserver_servicegroup_add'](name, sg_name, **connection_args):
                ret['comment'] += ' && failed to bind vserver to servicegroup {0}'.format(sg_name)
                ret['result'] = False
                return ret
            else:
                ret['comment'] += ' && bound vserver to servicegroup {0}'.format(sg_name)
               
        # Check if each servers exists && is tied to the service group
        servers = servicegroup.get('servers', {})
        for server, attrs in servers.iteritems():
            s_name = server
            s_ip = attrs.get('ip', None)
            s_port = attrs.get('port', None)
            s_status = attrs.get('status', None)
            # Server existensialism
            if not __salt__['netscaler.server_exists'](s_name, **connection_args):
                if not __salt__['netscaler.server_add'](s_name, s_ip, s_status, **connection_args):
                    ret['comment'] += ' && failed to create server {0}'.format(s_name)
                    ret['result'] = False
                else:
                    ret['comment'] += ' && created server {0}'.format(s_name)

            # Check if server already present, but needs to be updated
            elif not __salt__['netscaler.server_exists'](s_name, s_ip, **connection_args):
                if not __salt__['netscaler.server_update'](s_name, s_ip, **connection_args):
                    ret['comment'] += ' && failed to update server {0} with ip {1}'.format(s_name, s_ip)
                    ret['result'] = False
                else:
                    ret['comment'] += ' && updated server {0} with ip {1}'.format(s_name, s_ip)

            # servicegroup, and servers bondages
            if not __salt__['netscaler.servicegroup_server_exists'](sg_name, s_name, s_port, **connection_args):
                if not __salt__['netscaler.servicegroup_server_add'](sg_name, s_name, s_port, **connection_args):
                    ret['comment'] += ' && failed to bind server {0} to servicegroup {1}'.format(s_name, sg_name)
                    ret['result'] = False
                else:
                    ret['comment'] += ' && bound server {0} to servicegroup {1}'.format(s_name, sg_name)                    
      
    return ret         

