# Server Setup

Utopia is designed to make deployment to remote servers easy.

## Deployment

The preferred method of deployment to a production server is via git. The `utopia` command assists with setup of a remote git repository on the server. It will setup a `git` `post-update` hook which will deploy the site correctly and restart the application server for that site.

To setup a server for deployment:

```bash
$ mkdir /srv/http/www.example.com
$ cd /srv/http/www.example.com
$ sudo -u http utopia server create
```

On your development machine, you should setup the git remote:

```bash
$ git remote add production ssh://remote/srv/http/www.example.com
$ git push --set-upstream production master
```

### Default Environment

Utopia will load `config/environment.yaml` and update `ENV` before executing any code. You can set default environment values using the `utopia` command:

```bash
$ sudo -u http utopia environment RACK_ENV=production DATABASE_ENV=production_cluster_primary
ENV["RACK_ENV"] will default to "production" unless otherwise specified.
ENV["DATABASE_ENV"] will default to "production_cluster_primary" unless otherwise specified.
```

To set a value, write `KEY=VALUE`. To unset a key, write `KEY`.

When you run `rake` tasks or spawn a server, the values in `config/environment.yaml` will be the defaults. You can override them by manually specifying them, e.g. `DATABASE_ENV=development rake db:info`.

## Platform

The best deployment platform for Utopia is Linux, using [falcon](https://github.com/socketry/falcon).

### Sudo Setup

Create a file `/etc/sudoers.d/http` with the following contents:

```sudoers
# Allow user samuel to check out code as user http using git:
%wheel ALL=(http) NOPASSWD: ALL
```

This allows the deploy task to correctly checkout code as user `http`.

