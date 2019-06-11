#!/usr/bin/env -S falcon host

load :rack, :self_signed_tls, :supervisor

hostname = File.basename(__dir__)
rack hostname, :lets_encrypt

supervisor
