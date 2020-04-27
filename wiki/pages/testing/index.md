# Testing

Utopia websites include a default set of tests, and associated `rake test` tasks. These specs can test against the actual running website. By default, [covered](https://github.com/socketry/covered) is included for coverage testing.

```bash
$ rake coverage test

my website
	should have an accessible front page

Finished in 0.44849 seconds (files took 0.15547 seconds to load)
1 example, 0 failures

Coverage report generated for RSpec. 5 / 5 LOC (100.0%) covered.
```