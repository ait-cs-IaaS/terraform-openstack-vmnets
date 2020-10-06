# Changelog

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