# `users` role

This role creates user accounts, sets their passwords and makes them able to
use sudo, if appropriate. It should be a dependency of all those roles which
copy files to home dirs or expect users to exist.

After execution, it will have defined two variables that can be used to
iterate over user information:

* `users_names` is a list holding all non-root accounts defined in the
defaults (or overriden somewhere else);
* `users_created` is the output of the `user` Ansible module and contains
useful info about created users, such as their home dirs. One can use them
like this, to avoid assuming where home dirs are placed or their names
(as we may allow setting home dir names in the future, rather than using the
username):

```yaml
name: Copy a file to user home
copy:
  src: foobar
  dest: "{{ users_created | user_home(item) }}/.foobar"
loop: "{{ users_names }}"
```

Note that `user_home` is a custom filter that simply extracts the home path
for a user name.

Modules depending on `users` are allowed to access those two variables as
role output.