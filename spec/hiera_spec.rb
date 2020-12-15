# frozen_string_literal: true

require 'spec_helper'

describe Dome do
  let(:account_dir) { 'deirdre-dev' }
  let(:environment_dir) { 'qa' }
  let(:environment) { Dome::Environment.new([account_dir, environment_dir]) }
  let(:hiera) { Dome::HieraLookup.new(environment) }
  let(:level) { 'environment' }
  let(:project_root) { File.realpath('spec/fixtures') }

  before(:each) { allow_any_instance_of(Dome::Settings).to receive(:find_project_root).and_return(project_root) }
  before(:each) { allow_any_instance_of(Dome::Environment).to receive(:level).and_return(level) }

  it 'outputs the correct message for a hiera lookup' do
    vars = { 'foo' => 'bar' }
    allow(hiera).to receive(:lookup).and_return('bar')
    error_message = "[*] Setting \e[0;32;49mTF_VAR_foo\e[0m.\n\n"
    expect { hiera.secret_env_vars(vars) }.to output(error_message).to_stdout
  end

  it 'outputs the correct error message for a failed hiera lookup' do
    vars = { 'foo' => 'bar' }
    allow(hiera).to receive(:lookup).and_return(nil)
    error_message = "\e[0;33;49m[!] Hiera lookup failed for 'bar', so TF_VAR_foo was not set.\e[0m\n\n"
    expect { hiera.secret_env_vars(vars) }.to output(error_message).to_stdout
  end
end
