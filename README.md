gitlabitch
==========

Features:
 - HTTP POST API for gitlab webhook
 - mirrors selected repository branches under defined user
 - logs to Syslog

Install (using RVM):
  1. create user to containt RVM and the project
  2. install RVM for the user
  3. clone this repo into his homedir
  4. run `bundle install`

Configure:
  1. copy `gitlabitch.yaml.example` to `/etc/gitlabitch.yaml` and edit it accordingly.
  2. `rvmsudo rackup -E production -D` (the user with RVM must be able to run `rvmsudo`, see RVM docs)
  3. the configured user must exist and it needs to have write permissions to the basedir; also, the user needs to have ssh keys generated (usually in `~/.ssh/`)
  4. add the SSH pubkey to the desired repo in GitLab (in section Settings -> Deploy keys)
  5. add the commit hook URL: `http://<server_with_gitlabitch>:9292/<project_name>`
  6. click test
  7. the branch should be mirrored to the desired directory
  8. you can what's been done in syslog (daemon, INFO)

TODO:
  - upstart scripts
