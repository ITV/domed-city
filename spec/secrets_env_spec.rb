# frozen_string_literal: true

require 'spec_helper'

describe Dome do
  let(:env) { 'dev' }
  let(:eco) { 'dev' }
  let(:environment) { Dome::Environment.new([eco, env]) }
  let(:secret_manager) { Dome::SecretsManagerLookup.new(environment) }
  let(:level) { 'environment' }
  let(:project_root) { File.realpath('spec/fixtures') }
  let(:client) { double('client') }
  let(:secret_value) { double('secret_value') }
  let(:error) { double('error') }
  let(:secrets_config) do
    {
      'dev' => {
        'dev_common_secret' => 'dev_common_secret_value',
        'dev' => {
          'dev_databricks_username' => '{ecosystem}/dev_databricks_username/_value'
        },
        'devtest' => {
          'devtest_databricks_username' => '{ecosystem}/devtest_databricks_username/_value'
        }
      },
      'prd' => {
        'prd_common_secret' => 'prd-prd_common_secret_value-secret',
        'prd' => {
          'prd_username' => '{ecosystem}/prd_databricks_username/_value'
        },
        'prdtest' => {
          'prdtest_username' => '{ecosystem}/prdtest_databricks_username/_value'
        }
      }
    }
  end
  before do
    allow_any_instance_of(Dome::Settings).to receive(:find_project_root).and_return(project_root)
    allow_any_instance_of(Dome::Environment).to receive(:level).and_return(level)
    allow(environment).to receive(:ecosystem).and_return(eco)
    allow(Aws::SecretsManager::Client).to receive(:new).and_return(client)
    allow(client).to receive(:get_secret_value).and_return(secret_value)
    allow(secret_value).to receive(:secret_string).and_return('Super secret string')
  end

  it 'outputs the correct vars for DEV environement' do
    expected_result = { 'dev_common_secret' => 'dev_common_secret_value', 'dev_databricks_username' => '{ecosystem}/dev_databricks_username/_value' }
    expect(secret_manager.secret_env_vars(secrets_config)).to eq expected_result
  end

  it 'prints correct message to the stdout' do
    expect { secret_manager.secret_env_vars(secrets_config) }
      .to output("[*] Setting \e[0;32;49mTF_VAR_dev_common_secret\e[0m.\n[*] Setting \e[0;32;49mTF_VAR_dev_databricks_username\e[0m.\n").to_stdout
  end

  context 'when calling secrets from a nonexistent environment' do
    let(:env) { 'qa' }

    it 'outputs only the global and eco scoped secrets' do
      expected_result = { 'dev_common_secret' => 'dev_common_secret_value' }
      expect(secret_manager.secret_env_vars(secrets_config)).to eq expected_result
    end
  end

  context 'when calling secrets in PRD' do
    let(:env) { 'prd' }
    let(:eco) { 'prd' }

    it 'outputs the correct vars for PRD environment' do
      expected_result = { 'prd_common_secret' => 'prd-prd_common_secret_value-secret', 'prd_username' => '{ecosystem}/prd_databricks_username/_value' }
      expect(secret_manager.secret_env_vars(secrets_config)).to eq expected_result
    end
  end

  context 'when calling secrets in PRDTEST' do
    let(:env) { 'prdtest' }
    let(:eco) { 'prd' }

    it 'outputs the correct vars for PRDTEST environment' do
      expected_result = { 'prd_common_secret' => 'prd-prd_common_secret_value-secret', 'prdtest_username' => '{ecosystem}/prdtest_databricks_username/_value' }
      expect(secret_manager.secret_env_vars(secrets_config)).to eq expected_result
    end
  end

  context 'error returned' do
    let(:secrets_config) do
      {
        'dev' => {
          'dev_common_secret' => 'dev_common_secret_value'
        }
      }
    end

    before do
      allow(client).to receive(:get_secret_value).once.and_raise(Aws::SecretsManager::Errors::ResourceNotFoundException)
      allow_any_instance_of(Aws::SecretsManager::Errors::ResourceNotFoundException).to receive(:initialize).and_return(error)
    end

    it 'prints correct error into the stdout' do
      expect { secret_manager.secret_env_vars(secrets_config) }
        .to output("\e[0;33;49m[!] Secrets Manager secret not found for 'dev_common_secret_value', so TF_VAR_dev_common_secret was not set.\e[0m\n").to_stdout
    end

    context 'AccessDeniedException' do
      before do
        allow(client).to receive(:get_secret_value).once.and_raise(Aws::SecretsManager::Errors::AccessDeniedException)
        allow_any_instance_of(Aws::SecretsManager::Errors::AccessDeniedException).to receive(:initialize).and_return(error)
      end

      it 'prints correct error into the stdout' do
        expect { secret_manager.secret_env_vars(secrets_config) }
          .to output("\e[0;33;49m[!] Access denied by Secrets Manager for 'dev_common_secret_value', so TF_VAR_dev_common_secret was not set.\e[0m\n").to_stdout
      end
    end
  end
end
