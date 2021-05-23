pulp3_rpm_distribution{ 'puppet-resource-api-test':
  pulp_labels => {
    'label_a'   => 'text a',
    # Always results in a resource update
    'timestamp' => $timestamp = Timestamp.new().strftime('%a%d%b%Y%H%M%S'),
  },
}
