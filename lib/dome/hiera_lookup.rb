# frozen_string_literal: true

module Dome
  class HieraLookup
    def initialize(environment)
      @environment = environment.environment
      @account     = environment.account
      @ecosystem   = environment.ecosystem
      @settings    = Dome::Settings.new
    end

    def config
      return @config if @config

      config = YAML.load_file(File.join(puppet_dir, 'hiera.yaml')).merge(default_config)
      if config[:vault]
        vault_env = ENV['TF_VAR_env'] || "infra#{ENV['TF_VAR_ecosystem']}"
        config[:vault][:address] = "https://secrets.#{vault_env}.#{ENV['TF_VAR_product']}.itv.com:8200"
        config[:vault][:auth_method] = :env
        config[:vault][:role] = 'dome_ro'
      end
      @config = config
    end

    def default_config
      {
        logger: 'noop',
        yaml: {
          datadir: "#{puppet_dir}/hieradata"
        },
        eyaml: {
          datadir: "#{puppet_dir}/hieradata",
          pkcs7_private_key: eyaml_private_key,
          pkcs7_public_key: eyaml_public_key
        }
      }
    end

    def puppet_dir
      directory = File.join(@settings.project_root, 'puppet')
      # TODO: Add a debug flag to enable certain output
      # puts "The configured Puppet directory is: #{directory.colorize(:green)}" unless @directory
      @puppet_dir ||= directory
    end

    def eyaml_dir
      if File.exist?(File.join(puppet_dir, 'keys/private_key.pkcs7.pem'))
        eyaml_directory = File.join(puppet_dir, 'keys')
      elsif File.exist?('/etc/puppet/keys/private_key.pkcs7.pem')
        eyaml_directory = '/etc/puppet/keys'
      else
        abort("Puppet private key not in found in either '/etc/puppet/keys' or #{puppet_dir}keys.")
      end
      # TODO: Add a debug flag to enable certain output
      # puts "The configured EYAML directory is: #{eyaml_directory.colorize(:green)}" unless @eyaml_directory
      @eyaml_dir ||= eyaml_directory
    end

    def eyaml_private_key
      private_key = File.join(eyaml_dir, 'private_key.pkcs7.pem')
      raise "Cannot find eyaml private key! Make sure it exists at #{private_key}" unless File.exist?(private_key)

      # TODO: Add a debug flag to enable certain output
      # puts "Found eyaml private key: #{private_key.colorize(:green)}"
      private_key
    end

    def eyaml_public_key
      public_key = File.join(eyaml_dir, 'public_key.pkcs7.pem')
      raise "Cannot find eyaml public key! Make sure it exists at #{public_key}" unless File.exist?(public_key)

      # TODO: Add a debug flag to enable certain output
      # puts "Found eyaml public key: #{public_key.colorize(:green)}"
      public_key
    end

    def lookup(key, default = nil, order_override = nil, resolution_type = :priority)
      hiera = Hiera.new(config: config)

      hiera_scope = {}
      hiera_scope['ecosystem'] = @ecosystem
      hiera_scope['location']  = 'aeuw1'
      hiera_scope['env']       = @environment

      hiera.lookup(key.to_s, default, hiera_scope, order_override, resolution_type)
    end

    def secret_env_vars(secret_vars)
      secret_vars.each_pair do |key, val|
        hiera_lookup = lookup(val)
        terraform_env_var = "TF_VAR_#{key}"
        ENV[terraform_env_var] = hiera_lookup
        if hiera_lookup
          puts "[*] Setting #{terraform_env_var.colorize(:green)}."
        else
          puts "[!] Hiera lookup failed for '#{val}', so #{terraform_env_var} was not set.".colorize(:yellow)
        end
      end

      puts
    end

    def extract_certs(certs)
      create_certificate_directory

      certs.each_pair do |key, val|
        directory = "#{certificate_directory}/#{key}"
        puts "Extracting certificate #{key.colorize(:green)} into #{directory.colorize(:green)}"
        File.open(directory, 'w') { |f| f.write(lookup(val)) }
      end
    end

    def create_certificate_directory
      puts "Creating certificate directory at #{certificate_directory.colorize(:green)}"
      FileUtils.mkdir_p certificate_directory
    end

    def certificate_directory
      "#{@settings.project_root}/terraform/certs"
    end
  end
end
