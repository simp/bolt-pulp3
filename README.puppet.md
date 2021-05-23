


### Experimental Remote Transport Resource API pulp resources


#### Setup

Before test-driving the experimental pulp3 resources:

1. Ensure local Pulp3 server is running
2. Prepare `device.conf` to use the current directory:

   ```sh
   pdk bundle exec spec_device_prep
   ```
3. Ensure the uri of `spec/fixtures/local_pulp_server.conf` points to your local pulp server


#### Testing the Puppet resources

To test that a Puppet resource can list entities from the local Pulp server:

```sh
pdk bundle exec puppet device --verbose --debug --trace --modulepath spec/fixtures/modules/ --deviceconfig  spec/fixtures/device.conf  --target pulp.localhost  --resource pulp3_rpm_distribution puppet-
resource-api-test
```

To test that a Puppet manifest can manipulate entities on the Pulp Service

```
pdk bundle exec puppet device --verbose --debug --trace --modulepath spec/fixtures/modules/ --deviceconfig  spec/fixtures/device.conf  --target pulp.localhost  --apply examples/pulp3_rpm_distribution.pp
```
