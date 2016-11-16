module Dome
  class State
    include Dome::Shell

    def initialize(environment)
      @environment = environment
    end

    def state_bucket_name
      "#{@environment.project}-tfstate-#{@environment.environment}"
    end

    def state_file_name
      "#{@environment.environment}-terraform.tfstate"
    end

    def sdb_lock_name
      state_file_name.gsub!(/(-|\.)/, '_')
    end

    def sdb_domain_name
      state_bucket_name.gsub!(/(-|\.)/, '_')
    end

    def s3_client
      @s3_client ||= Aws::S3::Client.new
    end

    def sdb_lock
      @sdb_lock ||= SdbLock.new(sdb_domain_name)
    end

    def list_buckets
      s3_client.list_buckets
    end

    def bucket_names
      bucket_names = list_buckets.buckets.map(&:name)
      puts "Found the following buckets: #{bucket_names}".colorize(:yellow)
      bucket_names
    end

    def s3_bucket_exists?(bucket_name)
      bucket_names.find { |bucket| bucket == bucket_name }
    end

    def create_bucket(name)
      s3_client.create_bucket(bucket: name, acl: 'private')
    rescue Aws::S3::Errors::BucketAlreadyExists
      raise 'The S3 bucket must be globally unique. See https://docs.aws.amazon.com/AmazonS3/latest/gsg/CreatingABucket.html'.colorize(:red)
    end

    def enable_bucket_versioning(bucket_name)
      puts 'Enabling versioning on the S3 bucket - http://docs.aws.amazon.com/AmazonS3/latest/dev/Versioning.html'.colorize(:green)
      s3_client.put_bucket_versioning(bucket:                   bucket_name,
                                      versioning_configuration: {
                                        mfa_delete: 'Disabled',
                                        status:     'Enabled'
                                      })
    end

    def put_empty_object_in_bucket(bucket_name, key_name)
      puts "Putting an empty object with key: #{key_name} into bucket: #{bucket_name}".colorize(:green)
      s3_client.put_object(
        bucket: bucket_name,
        key:    key_name,
        body:   ''
      )
    end

    def create_remote_state_bucket(bucket_name, state_file)
      create_bucket bucket_name
      enable_bucket_versioning bucket_name
      put_empty_object_in_bucket(bucket_name, state_file)
    end

    def s3_state
      if s3_bucket_exists?(state_bucket_name)
        synchronise_s3_state(state_bucket_name, state_file_name)
      else
        create_remote_state_bucket(state_bucket_name, state_file_name)
      end
    end

    def synchronise_s3_state(bucket_name, state_file_name)
      puts 'Synchronising the remote S3 state...'
      command         = 'terraform remote config -backend=S3'\
            " -backend-config='bucket=#{bucket_name}' -backend-config='key=#{state_file_name}'"
      failure_message = 'Something went wrong when synchronising the S3 state.'
      execute_command(command, failure_message)
    end
  end
end
