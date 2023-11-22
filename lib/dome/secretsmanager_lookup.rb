# frozen_string_literal: true
require 'aws-sdk-secretsmanager'

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
            secret_ecosystem = key
            if secret_ecosystem == @ecosystem
              val.each do |eco_key, eco_val|
                if eco_val.is_a?(String)
                  set_env_var(client, eco_key, eco_val)
                elsif eco_val.is_a?(Hash)
                  secret_environment = eco_key
                  if secret_environment == @environment
                    eco_val.each do |env_key, env_val|
                      set_env_var(client, env_key, env_val)
                    end
                  end
                end
              end
            end
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
          puts "[!] Secrets Manager lookup failed for '#{val}', so #{terraform_env_var} was not set.".colorize(:yellow)
        else
          puts "[*] Setting #{terraform_env_var.colorize(:green)}."
        ensure
          ENV[terraform_env_var] = secret_string
        end
      end
    end
  end
