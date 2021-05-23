# frozen_string_literal: true

require 'puppet/resource_api'

Puppet::ResourceApi.register_type(
  name: 'pulp3_rpm_distribution',
  desc: <<-EOS,
@summary a pulp3_rpm_distribution type
@example

  pulp3_rpm_distribution { 'unique-distro-name':
    ensure      => 'present',
    base_path   => 'optional/custom/path/for/distro',
    publication => Publication[publication_title],
    pulp_labels => [ 'label1', 'label2' ],
  }

This type provides Puppet with capabilities to manage Pulp3 RPM distributions.

If your type uses autorequires, please document as shown below, else delete
these lines.
**Autorequires**:
* `Package[foo]`
EOS
  features: [
    'remote_resource' # Avoid `Skipping host resources because running on a device`
  ],
  attributes: {
    ensure: {
      type: 'Enum[present, absent]',
      desc: 'Whether this resource should be present or absent on the target system.',
      default: 'present',
    },
    name: {
      type: 'String',
      desc: 'Unique name of the RPM Distribution.',
      behaviour: :namevar,
    },
    publication: {
      type: 'Optional[String]',
      desc: 'Unique name of RPM Publication to be served',
    },
    base_path: {
      type: 'Optional[String]',
      desc: 'Path component of the published url.  If not provided, defaults to `name`. Avoid paths that overlap with other distribution base paths (e.g. "foo" and "foo/bar")',
    },
    pulp_labels: {
      type: 'Hash[String,String,0]',
      desc: 'Pulp labels',
    },
    pulp_href: {
      type: 'String[1]',
      desc: 'URI to Pulp API resource',
      behaviour: :read_only,
    },
  },
)
