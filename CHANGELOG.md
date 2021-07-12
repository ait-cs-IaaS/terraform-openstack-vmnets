# Changelog


# v1.5.4
 - Move to github
 - Add support for host metadata
# v1.5.3
 - Add userdata vars variable input for host
 - Update to use host module 1.4.2
 - Add option to supply routes to be used by the fw host only
 - Add networking info to userdata vars

# v1.5.2
 - Add sensitive flag to host output
# v1.5.1

 - Use host module version 1.4
 - Make storage type configurable (`host_use_volume`, `true`=volume and `false`=root file)

## v1.5

- *Breaking Change* Add optional routes configuration to networks (key: `routes`) 
- Add optional routes configuration for the external network 

## v1.4

- *Breaking Change* Rename external network ip variable
- Make external network ip input optional
- Make userdata optional and upgrade host module to 1.3.2
- *Bug fix* Fix host_size not being passed as volume_size

## v1.3
- Add firewall and networks as outputs
- Add option to use firewall as dns server for internal nets (can be configured per network and fixed ip must also be supplied)

## v1.2

- Fix floating ip pool being static
- Use floating ip pool input instead of boolean flag
- Make external network creation optional
- Add changelog
  
## v1.1

- Add floating ip support

## v1.0

-  Initial Release