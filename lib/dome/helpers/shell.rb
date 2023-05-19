# frozen_string_literal: true
require 'open3'

module Dome
  module Shell
    def execute_command(command, failure_message)
      puts "[*] Running: #{command.colorize(:yellow)}"
      success = system command
      Kernel.abort(failure_message) unless success
    end

    def upload_kpi(product, environment, author, bucket_name, file_name)
      ecosystem = environment == 'prd' ? 'prd' : 'dev'
      puts "#{product},#{environment},#{author},#{bucket_name},#{file_name}"
      timestamp = Time.now.strftime('%Y-%m-%d-%H-%M-%S')
      if ENV['FREEZE_AWS_ENVVAR']
        object_exists, stderr, status = Open3.capture3("aws s3 ls s3://itv-core-terraform-kpi/#{product}-infra/dome_kpi.csv")
      else
        object_exists, stderr, status = Open3.capture3("aws-vault exec #{product}-#{ecosystem}-pe -- env -- aws s3 ls s3://itv-core-terraform-kpi/#{product}-infra/dome_kpi.csv")
      end
      if object_exists.include? "dome_kpi.csv"
        if ENV['FREEZE_AWS_ENVVAR']
          command_output("aws s3 cp s3://itv-core-terraform-kpi/#{product}-infra/dome_kpi.csv dome_kpi.csv", "Failed to copy existing object")
          version_id = command_output("aws s3api list-object-versions --bucket #{bucket_name} --prefix #{file_name} | jq -r '.Versions[] | select(.IsLatest==true) | .VersionId'", "Failed to get version id").strip
        else
          command_output("aws-vault exec #{product}-#{ecosystem}-pe -- env -- aws s3 cp s3://itv-core-terraform-kpi/#{product}-infra/dome_kpi.csv dome_kpi.csv", "Failed to copy existing object")
          version_id = command_output("aws-vault exec #{product}-#{ecosystem}-pe -- env -- aws s3api list-object-versions --bucket #{bucket_name} --prefix #{file_name} | jq -r '.Versions[] | select(.IsLatest==true) | .VersionId'", "Failed to get version id").strip
        end
        if ENV['FREEZE_AWS_ENVVAR']
          File.open("dome_kpi.csv", "a") do |f|
            puts "#{timestamp},#{product},#{environment},'EKSCI',#{version_id},#{bucket_name},#{file_name}"
            f.puts "#{timestamp},#{product},#{environment},'EKSCI',#{version_id},#{bucket_name},#{file_name}"
          end
          command_output("aws s3 cp dome_kpi.csv s3://itv-core-terraform-kpi/#{product}-infra/dome_kpi.csv", "Failed to upload new object")
        else
          File.open("dome_kpi.csv", "a") do |f|
            puts "#{timestamp},#{product},#{environment},#{author},#{version_id},#{bucket_name},#{file_name}"
            f.puts "#{timestamp},#{product},#{environment},#{author},#{version_id},#{bucket_name},#{file_name}"
          end
          command_output("aws-vault exec #{product}-#{ecosystem}-pe -- env -- aws s3 cp dome_kpi.csv s3://itv-core-terraform-kpi/#{product}-infra/dome_kpi.csv", "Failed to upload new object")
        end
        File.delete("dome_kpi.csv")
      end
    end

    def command_output(command, failure_message)
      puts "[*] Running: #{command.colorize(:yellow)}"
      stdout, stderr, status = Open3.capture3(command)
      Kernel.abort(failure_message) unless status == 0
      return stdout
    end
  end
end
