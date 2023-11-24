# frozen_string_literal: true

module Dome
  class SecretsManagerLookup
    def initialize(environment)
      @environment = environment.environment
      @account     = environment.account
      @ecosystem   = environment.ecosystem
      @settings    = Dome::Settings.new
    end

    def get_the_secrets(secrets_config)
      secrets_config.each_with_object([]) do |(key, value),keys|
        keys << {"#{key}": value} unless value.is_a? Hash 
        if ecosystem_level? key, value
          add_to_the_keys keys, key, value, @ecosystem
        else
          add_to_the_keys keys, key, value, @environment
        end
      end
    end

    def ecosystem_level? key, value
      key.eql?(@ecosystem) && value[key]
    end

    def add_to_the_keys keys, key, value, level
      keys.concat(get_the_secrets(value)) if (value.is_a? Hash) && key.eql?(level)
    end

    def secret_env_vars(secret_vars)
      client = Aws::SecretsManager::Client.new
      secrets = get_the_secrets(secret_vars.each)
      secrets.each do |key, val|
        set_env_var(client, key.keys[0].to_s, key.values[0].to_s)
      end
    end

    def set_env_var(client, key, val)
      secret_id = val.gsub('{environment}', @environment).gsub('{ecosystem}', @ecosystem)
      terraform_env_var = "TF_VAR_#{key}"
      begin
        secret_string = client.get_secret_value(secret_id: secret_id).secret_string
      rescue Aws::SecretsManager::Errors::AccessDeniedException
        secret_string = nil
        puts "[!] Access denied by Secrets Manager for '#{secret_id}', so #{terraform_env_var} was not set.".colorize(:yellow)
      rescue Aws::SecretsManager::Errors::ResourceNotFoundException
        secret_string = nil
        puts "[!] Secrets Manager secret not found for '#{secret_id}', so #{terraform_env_var} was not set.".colorize(:yellow)
      else
        puts "[*] Setting #{terraform_env_var.colorize(:green)}."
      ensure
        ENV[terraform_env_var] = secret_string
      end
    end
  end
end
