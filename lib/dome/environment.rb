module Dome
  class Environment
    attr_reader :environment, :account, :settings

    def initialize(directories = Dir.pwd.split('/'))
      @environment = directories[-1]
      @account     = directories[-2]
      @settings    = Dome::Settings.new
      @root_account = @settings.parse['root-profile']
      @accounts_ids = @settings.parse['accounts-mapping']
      @assume_role  = @settings.parse['assumed-role']
    end

    def team
      @settings.parse['project']
    end

    def accounts
      %W(#{team}-dev #{team}-prd)
    end

    def environments
      @settings.parse['environments']
    end

    def aws_credentials
      @aws_credentials ||= AWS::ProfileParser.new.get(@root_account)
      @aws_credentials.key?(:output) && @aws_credentials.delete(:output)
      return @aws_credentials
    rescue RuntimeError
      raise "No credentials found for account: '#{@root_account}'."
    end

    def sts_client
      @sts_client = Aws::STS::Client.new(
        access_key_id: aws_credentials[:access_key_id],
        secret_access_key: aws_credentials[:secret_access_key],
        region: aws_credentials[:region]
      )
      return @sts_client
    rescue Aws::STS::Errors::ServiceError => e
      raise "Failed to connect to STS service: #{e}"
    end

    def sts_credentials
      account_id = @accounts_ids[@account]
      @sts_credentials ||= sts_client.assume_role({
        role_arn: "arn:aws:iam::#{account_id}:role/#{@assume_role}", # required
        role_session_name: "#{account_id}-#{@assume_role}", # required
        duration_seconds: 3600
      })
      return @sts_credentials
    rescue Aws::STS::Errors::ServiceError => e
      raise "Failed to assume role and get sts credentials for account: '#{account}' #{e}"
    end

    def populate_aws_access_keys
      ENV['AWS_ACCESS_KEY_ID']     = sts_credentials.credentials.access_key_id
      ENV['AWS_SECRET_ACCESS_KEY'] = sts_credentials.credentials.secret_access_key
      ENV['AWS_SECURITY_TOKEN']    = sts_credentials.credentials.session_token
      ENV['AWS_SESSION_TOKEN']     = sts_credentials.credentials.session_token
      ENV['AWS_DEFAULT_REGION']    = aws_credentials[:region]
      ENV['AWS_REGION']            = aws_credentials[:region]
    end

    def valid_account?(account_name)
      puts "Account: #{account_name.colorize(:green)}"
      accounts.include? account_name
    end

    def valid_environment?(environment_name)
      puts "Environment: #{environment_name.colorize(:green)}"
      environments.include? environment_name
    end

    def invalid_account_message
      puts "\n'#{@account}' is not a valid account.\n".colorize(:red)
      generic_error_message
      exit 1
    end

    def invalid_environment_message
      puts "\n'#{@environment}' is not a valid environment.\n".colorize(:red)
      generic_error_message
      exit 1
    end

    private

    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/AbcSize
    def generic_error_message
      puts "The 'account' and 'environment' variables are assigned based on your current directory.\n".colorize(:red)
      puts "The expected directory structure is '.../<account>/<environment>'\n".colorize(:red)
      puts '============================================================================='
      puts "Valid environments are defined using the 'environments' key in your itv.yaml."
      puts "The environments you have defined are: #{environments}."
      puts '============================================================================='
      puts 'Valid accounts are of the format <project>-dev/prd and <project>-prd' \
           " (where 'project' is defined using the 'project' key in your itv.yaml."
      puts "The accounts you have defined are: #{accounts}."
      puts '============================================================================='
      puts 'To fix your issue, try the following:'
      puts '1. Set your .aws/config to one of the valid accounts above.'
      puts '2. Ensure you are running this from the correct directory.'
      puts '3. Update your itv.yaml with the required environments or project.'
    end
  end
end
