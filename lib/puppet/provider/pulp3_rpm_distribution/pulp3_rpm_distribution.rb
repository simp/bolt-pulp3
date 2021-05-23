# frozen_string_literal: true

require 'puppet/resource_api/simple_provider'

# Implementation for the pulp3_rpm_distribution type using the Resource API.
class Puppet::Provider::Pulp3RpmDistribution::Pulp3RpmDistribution < Puppet::ResourceApi::SimpleProvider
  # Reports the current state of the managed resources
  #
  #   * Returns an enumerable of all existing resources.
  #   * Each resource is a hash with attribute names as keys, and their
  #     respective values as values
  #   * If the get method raises an exception, the provider is marked as
  #     unavailable during the current run, and all resources of this type will
  #     fail in the current transaction. The exception message will be reported
  #     to the user.
  #
  def get(context)
    distros = context.device.get('/distributions/rpm/rpm', context.device.connection)
    results = distros.map do |x|
      x.transform_keys(&:to_sym).select do |y|
        %i[name publication base_path pulp_labels pulp_href].include?(y)
      end.merge({ensure: 'present'})
    end
    results
  end

  def create(context, name, should)
    context.notice("Creating '#{name}' with #{should.inspect}")
  end

  def update(context, name, should)
    context.notice("Updating '#{name}' with #{should.inspect}")
  end

  def delete(context, name)
    context.notice("Deleting '#{name}'")
  end
end
