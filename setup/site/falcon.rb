#!/usr/bin/env -S falcon host

load :rack, :self_signed_tls, :supervisor

rack 'utopia.localhost', :self_signed_tls
supervisor
