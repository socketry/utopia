#!/usr/bin/env -S falcon host
# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2026, by Samuel Williams.

require "async/service/supervisor"
require "falcon/environment/application"
require "falcon/environment/lets_encrypt_tls"
require "utopia/application"

hostname = File.basename(__dir__)

service hostname do
	include Falcon::Environment::Application
	include Falcon::Environment::LetsEncryptTLS
	
	def middleware
		Utopia::Application.load
	end
end

service "supervisor" do
	include Async::Service::Supervisor::Environment
end
