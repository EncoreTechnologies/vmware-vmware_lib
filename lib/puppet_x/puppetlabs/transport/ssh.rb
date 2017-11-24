# Copyright (C) 2013 VMware, Inc.

module PuppetX::Puppetlabs::Transport

  #### Begin Encore Mods
  ## On all nodes, except the vmware controller we don't want to install net-ssh gem
  ## Requiring this gem makes puppet fail on all nodes before it gets a chance
  ## to even run. This doesn't detract any functionality from the vcenter module
  ## because this transport isn't even used. Also it allows us to install net-ssh
  ## using puppet on a first run, then utilize this transport on subsequent runs.
  begin 
    
    require 'net/ssh' unless Puppet.run_mode.master?
    
    class Ssh
      attr_accessor :ssh
      attr_reader :name, :user, :password, :host

      def initialize(opt)
        @name     = opt[:name]
        @user     = opt[:username]
        @password = opt[:password]
        @host     = opt[:server]
        # symbolize keys for options
        options = opt[:options] || {}
        @options  = options.inject({}){|h, (k, v)| h[k.to_sym] = v; h}
        @options[:password] = @password
        default = {:timeout => 10}
        @options = default.merge(@options)
        Puppet.debug("#{self.class} initializing connection to: #{@host}")
      end

      def connect
        @ssh ||= Net::SSH.start(@host, @user, @options)
      end

      # wrapper for debugging
      def exec!(command)
        Puppet.debug("Executing on #{@host}:\n#{command}")
        result = @ssh.exec!(command)
        Puppet.debug("Execution result:\n#{result}")
        result
      end

      def exec(command)
        Puppet.debug("Executing on #{@host}:\n#{command}")
        @ssh.exec(command)
      end

      # Return an SCP object
      def scp
        require 'net/scp'
        Puppet.debug("Creating SCP session from existing SSH connection")
        @ssh.scp
      end

      def close
        Puppet.debug("#{self.class} closing connection to: #{@host}")
        @ssh.close if @ssh
      end
    end
    
  rescue LoadError => e
    Puppet.debug("#{self.class} - Unable to create SSH transport because net-ssh gem is not installed.")
  end
  #### End Encore Mods
end
