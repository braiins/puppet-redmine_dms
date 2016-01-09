require 'spec_helper'
describe 'redmine_dms' do

  context 'with defaults for all parameters' do
    it { should contain_class('redmine_dms') }
  end
end
