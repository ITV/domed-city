module Dome
  class State
    include Dome::Shell

    def initialize(environment)
      @environment = environment
    end

    def state_bucket
      "#{@environment.team}-tfstate-#{@environment.environment}"
    end

    def state_file
      "#{@environment.environment}-terraform.tfstate"
    end

    def s3_client
      @s3_client ||= Aws::S3::Client.new(
          region: @environment.aws_credentials[:region],
          access_key_id: @environment.sts_credentials.credentials.access_key_id,
          secret_access_key: @environment.sts_credentials.credentials.secret_access_key,
          session_token: @environment.sts_credentials.credentials.session_token,
        )
    rescue AWS::S3::Errors::ServiceError => e
      raise "Error creating s3 client: #{e}"
    end

    def s3_bucket_exists?(bucket_name)
      resp = s3_client.list_buckets
      resp.buckets.each { |bucket| return true if bucket.name == bucket_name }
      false
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

    def create_remote_state_bucket(state_bucket, state_file)
      create_bucket state_bucket
      enable_bucket_versioning state_bucket
      put_empty_object_in_bucket(state_bucket, state_file)
    end

    def s3_state
      if s3_bucket_exists?(state_bucket)
        synchronise_s3_state
      else
        create_remote_state_bucket(state_bucket, state_file)
      end
    end

    def synchronise_s3_state
      puts 'Synchronising the remote S3 state...'
      command         = 'terraform remote config -backend=S3'\
            " -backend-config='bucket=#{state_bucket}' -backend-config='key=#{state_file}'"
      failure_message = 'Something went wrong when synchronising the S3 state.'
      execute_command(command, failure_message)
    end
  end
end
