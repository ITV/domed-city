# frozen_string_literal: true

module Dome
    class SecretsManagerLookup
      def initialize(environment)
        @environment = environment.environment
        @account     = environment.account
        @ecosystem   = environment.ecosystem
        @settings    = Dome::Settings.new
      end

      def secret_env_vars(secret_vars)
        client = Aws::SecretsManager::Client.new()
        secret_vars.each do |key, val|
          if val.is_a?(String)
            set_env_var(client, key, val)
          elsif val.is_a?(Hash)
            set_ecosystem_env_var(client, key, val)
          end
        end
      end

      def set_ecosystem_env_var(client, secret_ecosystem, secrets)
        if secret_ecosystem == @ecosystem
          secrets.each do |key, val|
            if val.is_a?(String)
              set_env_var(client, key, val)
            elsif val.is_a?(Hash)
              set_environment_env_var(client, key, val)
            end
          end
        end
      end

      def set_environment_env_var(client, secret_environment, secrets)
        if secret_environment == @environment
          secrets.each do |key, val|
            set_env_var(client, key, val)
          end
        end
      end

      def set_env_var(client, key, val)
        val.gsub! '{environment}', @environment
        val.gsub! '{ecosystem}', @ecosystem
        terraform_env_var = "TF_VAR_#{key}"
        begin
          secret_string = client.get_secret_value(secret_id: val).secret_string

        rescue Aws::SecretsManager::Errors::AccessDeniedException
          secret_string = nil
          puts "[!] Access denied by Secrets Manager for '#{val}', so #{terraform_env_var} was not set.".colorize(:yellow)
        rescue Aws::SecretsManager::Errors::ResourceNotFoundException
          secret_string = nil
          puts "[!] Secrets Manager secret not found for '#{val}', so #{terraform_env_var} was not set.".colorize(:yellow)
        else
          puts "[*] Setting #{terraform_env_var.colorize(:green)}."
        ensure
          ENV[terraform_env_var] = secret_string
        end
      end

    end
  end
