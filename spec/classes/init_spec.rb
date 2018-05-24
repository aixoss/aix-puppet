require 'spec_helper'
describe 'aixautomation' do
  context 'with default values for all parameters' do
    it { should contain_class('aixautomation') }
  end
end
