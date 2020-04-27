# Session

The session management uses symmetric private key encryption to store data on the client and avoid tampering.

```ruby
use Utopia::Session,
	:expires_after => 3600,
	:secret => '40 or more random characters for your secret key'
```

All session data is stored on the client, but it's encrypted with a salt and the secret key. It would be hard for the client to decrypt the data without the secret.

## Using `environment.yaml`

The session secret should not be shared or ideally, not stored in source code. This can be easily achieved using an environment variable, stored in `environment.yaml` on the production server:

```ruby
use Utopia::Session,
	:expires_after => 3600,
	:secret => ENV['UTOPIA_SESSION_SECRET']
```

In development, the secret would be reset every time the server is restarted. To set a fixed secret on production, run the following:

```bash
$ utopia server environment UTOPIA_SESSION_SECRET=$(head /dev/urandom | shasum | base64 | head -c 40)
```

This is done by default when using `utopia server create` and `utopia server update`.
