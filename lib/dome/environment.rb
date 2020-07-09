# frozen_string_literal: true

# This class represents the current directory

require 'open3'

module Dome
  class Environment
    attr_reader :environment, :account, :settings, :services

    include Dome::Level

    def initialize(directories = Dir.pwd.split('/'))
      ENV['AWS_DEFAULT_REGION'] = 'eu-west-1'

      puts <<-'MSG'
             _
          __| | ___  _ __ ___   ___
        /  _` |/ _ \| '_ ` _ \ / _ \
        | (_| | (_) | | | | | |  __/
         \__,_|\___/|_| |_| |_|\___|

        Wrapping terraform since 2015
      MSG

      puts ''
      puts "[*] Operating at #{level.colorize(:red)} level"
      puts ''

      @sudo = false

      @settings               = Dome::Settings.new
      @product                = @settings.parse['product']

      case level
      when 'environment'
        @environment            = directories[-1]
        @account                = directories[-2]
        @services               = nil

      when 'ecosystem'
        @environment            = nil
        @account                = directories[-1]
        @services               = nil

      when 'product'
        @environment            = nil
        @account                = "#{@product}-prd"
        @services               = nil

      when 'roles'
        @environment            = directories[-2]
        @account                = directories[-3]
        @services               = nil

      when 'services'
        @environment            = directories[-3]
        @account                = directories[-4]
        @services               = directories[-1]

      when /^secrets-/
        @environment            = directories[-3]
        @account                = directories[-4]
        @services               = nil

      else
        puts "Invalid level: #{level}".colorize(:red)
      end

      @ecosystem              = @account.split('-')[-1]
      @account_id             = @settings.parse['aws'][@ecosystem.to_s]['account_id'].to_s

      ENV['TF_VAR_product']   = @product
      ENV['TF_VAR_envname']   = @environment
      ENV['TF_VAR_env']       = @environment
      ENV['TF_VAR_ecosystem'] = @ecosystem
      ENV['TF_VAR_aws_account_id'] = @account_id

      cidr_ecosystem = []
      cidr_ecosystem_dev = []
      cidr_ecosystem_prd = []

      ecosystem_environments = @settings.parse['aws'][@ecosystem.to_s]['environments'].keys
      ecosystem_environments.each do |k|
        cidr_ecosystem << @settings.parse['aws'][@ecosystem.to_s]['environments'][k.to_s]['aws_vpc_cidr']
      end

      dev_ecosystem_environments = @settings.parse['aws']['dev']['environments'].keys
      dev_ecosystem_environments.each do |k|
        cidr_ecosystem_dev << @settings.parse['aws']['dev']['environments'][k.to_s]['aws_vpc_cidr']
      end

      prd_ecosystem_environments = @settings.parse['aws']['prd']['environments'].keys
      prd_ecosystem_environments.each do |k|
        cidr_ecosystem_prd << @settings.parse['aws']['prd']['environments'][k.to_s]['aws_vpc_cidr']
      end

      ENV['TF_VAR_cidr_ecosystem'] = cidr_ecosystem.join(',').to_s

      #
      # TODO: Will uncomment when all the products migrate to 1.1
      #

      # ENV['TF_VAR_cidr_ecosystem_dev'] = cidr_ecosystem_dev.join(',').to_s
      # ENV['TF_VAR_cidr_ecosystem_prd'] = cidr_ecosystem_prd.join(',').to_s

      ENV['TF_VAR_dev_ecosystem_environments'] = dev_ecosystem_environments.join(',').to_s
      ENV['TF_VAR_prd_ecosystem_environments'] = prd_ecosystem_environments.join(',').to_s

      puts '--- Initial TF_VAR variables to drive terraform ---'
      puts "[*] Setting aws_account_id to #{ENV['TF_VAR_aws_account_id'].colorize(:green)}"
      puts "[*] Setting product to #{ENV['TF_VAR_product'].colorize(:green)}"
      puts "[*] Setting ecosystem to #{ENV['TF_VAR_ecosystem'].colorize(:green)}"
      puts "[*] Setting env to #{ENV['TF_VAR_env'].colorize(:green)}" unless ENV['TF_VAR_env'].nil?
      puts "[*] Setting cidr_ecosystem to #{ENV['TF_VAR_cidr_ecosystem'].colorize(:green)}"
      puts ''

      puts '--- The following TF_VAR are helpers that modules can use ---'
      puts "[*] Setting dev_ecosystem_environments to #{ENV['TF_VAR_dev_ecosystem_environments'].colorize(:green)}"
      puts "[*] Setting prd_ecosystem_environments to #{ENV['TF_VAR_prd_ecosystem_environments'].colorize(:green)}"

      #
      # TODO: Will uncomment when all the products migrate to 1.1
      #

      # puts "[*] Setting cidr_ecosystem_dev to #{ENV['TF_VAR_cidr_ecosystem_dev'].colorize(:green)}"
      # puts "[*] Setting cidr_ecosystem_prd to #{ENV['TF_VAR_cidr_ecosystem_prd'].colorize(:green)}"

      puts ''
    end

    def project
      @settings.parse['project']
    end

    def ecosystem
      directories = Dir.pwd.split('/')
      case level
      when 'ecosystem'
        directories[-1].split('-')[-1]
      when 'environment'
        directories[-2].split('-')[-1]
      when 'product'
        # FIXME: This is 'prd' if accessed as @ecosystem
        'product'
      when 'roles'
        directories[-3].split('-')[-1]
      when /^secrets-|services/
        directories[-4].split('-')[-1]
      else
        puts "Invalid level: #{level}".colorize(:red)
      end
    end

    def accounts
      %W[#{project}-dev #{project}-prd]
    end

    def environments
      ecosystems = @settings.parse['ecosystems']
      raise '[!] ecosystems must be a hashmap of ecosystems to environments' unless ecosystems.is_a?(Hash)

      ecosystems.values.flatten
    end

    def aws_credentials
      puts "[*] Attempting to assume the role defined by your profile for #{@account.colorize(:green)}."

      if ENV['FREEZE_AWS_ENVVAR']
        puts '$FREEZE_AWS_ENVVAR is set. Leaving AWS environment variables unchanged.'
        return
      end

      profile_suffix = 'pe'
      profile_suffix = 'dev' if ENV['ITV_DEV']
      profile_suffix = 'root' if @sudo

      profile = "#{account}-#{profile_suffix}"
      cmd = "aws-vault exec #{profile} -- env"
      output, status = Open3.capture2(cmd)

      unless status.success?
        puts output.colorize(:red)
        raise 'Unable to assume role'
      end

      env = output.split("\n").map { |var| Hash[*var.split('=', 2)] }.reduce({}, &:merge)

      puts '[*] Exporting temporary credentials to environment variables '\
      "#{'AWS_ACCESS_KEY_ID'.colorize(:green)}, #{'AWS_SECRET_ACCESS_KEY'.colorize(:green)}"\
      " and #{'AWS_SESSION_TOKEN'.colorize(:green)}."
      ENV['AWS_ACCESS_KEY_ID'] = env['AWS_ACCESS_KEY_ID']
      ENV['AWS_SECRET_ACCESS_KEY'] = env['AWS_SECRET_ACCESS_KEY']
      ENV['AWS_SESSION_TOKEN'] = env['AWS_SESSION_TOKEN']
      puts ''
    end

    def valid_account?(account_name)
      accounts.include? account_name
    end

    def valid_environment?(environment_name)
      environments.include? environment_name
    end

    def invalid_account_message
      generic_error_message
      raise "\n[!] '#{@account}' is not a valid account.\n".colorize(:red)
    end

    def invalid_environment_message
      generic_error_message
      raise "\n[!] '#{@environment}' is not a valid environment.\n".colorize(:red)
    end

    def sudo
      @sudo = true
    end

    private

    def generic_error_message
      puts ''
      puts '--- Debug --- '
      puts "The environments you have defined are: #{environments}."
      puts "The accounts we calculated from your project itv.yaml key are: #{accounts}."
      puts ''
      puts '--- Troubleshoot ---'
      puts 'To fix your issue, try the following:'
      puts '1. Set your .aws/config to one of the valid accounts above.'
      puts '2. Ensure you are running this from the correct directory.'
      puts '3. Update your itv.yaml with the required environments or project.'
      puts '4. Check the README in case something is missing from your setup or ask in Slack'
      puts ''
    end
  end
end
