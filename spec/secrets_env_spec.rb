# frozen_string_literal: true

require 'spec_helper'

describe Dome do
  let(:account_dir) { 'dev' }
  let(:env) { 'dev' }
  let(:eco) { 'dev' }
  let(:environment) { Dome::Environment.new([account_dir, env]) }
  let(:secret_manager) { Dome::SecretsManagerLookup.new(environment) }
  let(:level) { 'environment' }
  let(:project_root) { File.realpath('spec/fixtures') }
  let(:client) { Struct.new(:secret_string) }
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
  before(:each) { allow_any_instance_of(Dome::Settings).to receive(:find_project_root).and_return(project_root) }
  before(:each) { allow_any_instance_of(Dome::Environment).to receive(:level).and_return(level) }
  before(:each) { allow(environment).to receive(:environment).and_return(env) }
  before(:each) { allow(environment).to receive(:ecosystem).and_return(eco) }
  before(:each) { allow_any_instance_of(Aws::SecretsManager::Client).to receive(:get_secret_value).and_return(client.new('Secret')) }

  it 'outputs the correct vars for DEV environement' do
    expected_result = [{ dev_common_secret: 'dev_common_secret_value' }, { dev_databricks_username: '{ecosystem}/dev_databricks_username/_value' }]
    expect(secret_manager.secret_env_vars(secrets_config)).to eq expected_result
  end

  context 'when calling secrets in PRD' do
    let(:env) { 'prd' }
    let(:eco) { 'prd' }

    it 'outputs the correct vars for PRD environment' do
      expected_result = [{ prd_common_secret: 'prd-prd_common_secret_value-secret' }, { prd_username: '{ecosystem}/prd_databricks_username/_value' }]
      expect(secret_manager.secret_env_vars(secrets_config)).to eq expected_result
    end
  end

  context 'when calling secrets in PRDTEST' do
    let(:env) { 'prdtest' }
    let(:eco) { 'prd' }

    it 'outputs the correct vars for PRD environment' do
      expected_result = [{ prd_common_secret: 'prd-prd_common_secret_value-secret' }, { prdtest_username: '{ecosystem}/prdtest_databricks_username/_value' }]
      expect(secret_manager.secret_env_vars(secrets_config)).to eq expected_result
    end
  end
end
