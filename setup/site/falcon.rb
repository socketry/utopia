#!/usr/bin/env -S falcon host

load :rack, :lets_encrypt, :supervisor

host 'utopia.localhost', :rack, :lets_encrypt

supervisor
