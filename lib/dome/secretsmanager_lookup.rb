# frozen_string_literal: true

module Dome
  class SecretsManagerLookup
    def initialize(environment)
      @environment = environment.environment
      @account     = environment.account
      @ecosystem   = environment.ecosystem
      @settings    = Dome::Settings.new
    end

    def get_the_secrets(h)
      h.each_with_object([]) do |(k,v),keys|
        keys << {"#{k}": v} unless v.is_a? Hash 
        if ecosystem_level? k, v
          add_to_the_keys keys, k, v, @ecosystem
        else
          add_to_the_keys keys, k, v, @environment
        end
      end
    end

    def ecosystem_level? key, value
      key.eql?(@ecosystem) && value[key]
    end

    def add_to_the_keys keys, k, v, level
      keys.concat(get_the_secrets(v)) if (v.is_a? Hash) && k.eql?(level)
    end

    def secret_env_vars(secret_vars)
      client = Aws::SecretsManager::Client.new
      secrets = get_the_secrets(secret_vars.each)
      secrets.each do |key, val|
        set_env_var(client, key.keys[0].to_s, key.values[0].to_s)
      end
    end

    def set_env_var(client, key, val)
      val.gsub! '{environment}', @environment
      val.gsub! '{ecosystem}', @ecosystem
      terraform_env_var = "TF_VAR_#{key}"
      ENV[terraform_env_var] = key
      puts key
      # begin
      #   secret_string = client.get_secret_value(secret_id: val).secret_string
      # rescue Aws::SecretsManager::Errors::AccessDeniedException
      #   secret_string = nil
      #   puts "[!] Access denied by Secrets Manager for '#{val}', so #{terraform_env_var} was not set.".colorize(:yellow)
      # rescue Aws::SecretsManager::Errors::ResourceNotFoundException
      #   secret_string = nil
      #   puts "[!] Secrets Manager secret not found for '#{val}', so #{terraform_env_var} was not set.".colorize(:yellow)
      # else
      #   puts "[*] Setting #{terraform_env_var.colorize(:green)}."
      # ensure
      #   ENV[terraform_env_var] = secret_string
      # end
      # end
    end
  end
end
