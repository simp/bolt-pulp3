# frozen_string_literal: true

require 'spec_helper'
require 'puppet/type/pulp3_rpm_distribution'

RSpec.describe 'the pulp3_rpm_distribution type' do
  it 'loads' do
    expect(Puppet::Type.type(:pulp3_rpm_distribution)).not_to be_nil
  end
end
