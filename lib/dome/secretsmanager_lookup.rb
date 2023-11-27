# frozen_string_literal: true

module Dome
  class SecretsManagerLookup
    def initialize(environment)
      @environment = environment.environment
      @account     = environment.account
      @ecosystem   = environment.ecosystem
      @settings    = Dome::Settings.new
      @level       = 'eco'
    end

    def secret_env_vars(secret_vars)
      client = Aws::SecretsManager::Client.new
      secrets = get_the_secrets(secret_vars)
      secrets.each do |key, val|
        set_env_var(client, key, val)
      end
    end

    private

    def get_the_secrets(secret_vars)
      secrets = {}
      # global secrets
      secret_vars.each do |key, val|
        secrets[key] = val if val.is_a?(String)
      end

      # ecosystem secrets
      eco_secrets = get_eco_secrets(secret_vars)
      secrets = secrets.merge(eco_secrets) if eco_secrets

      # environment secrets
      env_secrets = get_env_secrets(secret_vars)
      secrets = secrets.merge(env_secrets) if env_secrets
    end

    def get_eco_secrets(secret_vars)
      eco_secrets = {}
      secret_vars.fetch(@ecosystem, {}).each do |key, val|
        eco_secrets[key] = val if val.is_a?(String)
      end
      eco_secrets
    end

    def get_env_secrets(secret_vars)
      env_secrets = {}
      secret_vars.fetch(@ecosystem, {}).fetch(@environment, {}).each do |key, val|
        env_secrets[key] = val if val.is_a?(String)
      end
      env_secrets
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
