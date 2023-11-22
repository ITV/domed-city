# frozen_string_literal: true

module Dome
  class Secrets
    attr_reader :settings, :hiera

    def initialize(environment)
      @environment = environment
      @settings    = Dome::Settings.new
      @hiera       = Dome::HieraLookup.new(@environment)
      @secretsmanager = Dome::SecretsManagerLookup.new(@environment)
    end

    def secret_env_vars
      return if dome_config.nil? || hiera_keys_config.nil? || secretsmanager_config.nil?

      @secretsmanager.secret_env_vars(secretsmanager_config) unless secretsmanager_config.nil?
      @hiera.secret_env_vars(hiera_keys_config) unless hiera_keys_config.nil?
    end

    def extract_certs
      return if dome_config.nil? || certs_config.nil?

      @hiera.extract_certs(certs_config)
    end

    def dome_config
      puts "No #{'dome'.colorize(:green)} key found in your itv.yaml." unless @settings.parse['dome']
      @settings.parse['dome']
    end

    def hiera_keys_config
      unless @settings.parse['dome']['hiera_keys']
        puts "No #{'hiera_keys'.colorize(:green)} sub-key under #{'dome'.colorize(:green)} key found "\
          'in your itv.yaml.'
      end
      @settings.parse['dome']['hiera_keys']
    end

    def certs_config
      unless @settings.parse['dome']['certs']
        puts "No #{'certs'.colorize(:green)} sub-key under #{'dome'.colorize(:green)} key found "\
          'in your itv.yaml.'
      end
      @settings.parse['dome']['certs']
    end

    def secretsmanager_config
      unless @settings.parse['dome']['secretsmanager']
        puts "No #{'secretsmanager'.colorize(:green)} sub-key under #{'dome'.colorize(:green)} key found "\
          'in your itv.yaml.'
      end
      @settings.parse['dome']['secretsmanager']
    end
  end
end
