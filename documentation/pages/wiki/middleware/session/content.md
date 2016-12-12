# Session

The session management uses symmetric private key encryption to store data on the client and avoid tampering.

```ruby
use Utopia::Session,
	:expires_after => 3600,
	:secret => '40 or more random characters for your secret key'
```

All session data is stored on the client, but it's encrypted with a salt and the secret key. It would be hard for the client to decrypt the data without the secret.
