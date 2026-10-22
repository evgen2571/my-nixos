# Public SSH keys

Only `.pub` keys go here, never private SSH or age identities. User login keys belong under `keys/users/<user>/`. `keys/hosts/` is reserved for host identity/trust keys.

Add a login key to `my.primaryUser.authorizedKeyFiles` in the relevant host, then build and test a **second** SSH login before closing the old one. To revoke one, remove its reference and make sure another key still works.

Even public key comments can reveal personal details, so check them before publishing.
