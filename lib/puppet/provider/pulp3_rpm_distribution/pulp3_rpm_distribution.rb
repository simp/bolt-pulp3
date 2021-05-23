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
    distros = context.device.pulp3_api_get('/distributions/rpm/rpm', context.device.connection)
    results = distros.map do |x|
      x.transform_keys(&:to_sym).select do |y|
        %i[name publication base_path pulp_labels pulp_href].include?(y)
      end.merge({ensure: 'present'})
    end
    results
  end

  def create(context, name, should)
    context.device.pulp3_api_post( '/distributions/rpm/rpm',
      context.device.connection,
      should.reject{|k,v| k == :ensure}
    )
    require 'pry'; binding.pry
  end

  def set(context, changes)
    changes.each do |name,change|
      if change.key?(:is) && change.key?(:should)
        context.updating(name, message: 'Update') do
          update(context, name, change[:should], change[:is])
        end
      else
        require 'pry'; binding.pry
      end
    end
  end
  def update(context, name, should, is)
    context.device.pulp3_api_put(
      is[:pulp_href],
      context.device.connection,
      should.reject{|k,v| k == :ensure}
    )
  end
#
#  def delete(context, name)
#    context.notice("Deleting '#{name}'")
#  end
end
