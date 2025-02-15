# nu_plugin_bash_env

Historically Bash environment for Nushell was provided via the `nu_plugin_bash_env` plugin in this repo.

That plugin has now been removed in favour of the `bash-env` module, which is more feature rich and also embarrassingly simpler than the plugin.

## Historical plugin docunentation

### Plugin Version Compatability

Since Nushell 0.91.0 the plugin protocol was enhanced and now requires version compatability between plugins and Nushell itself.

The following versions are compatible.

| Nushell | bash-env plugin |
| ------- | --------------- |
|    0.89 |           0.5.0 |
|    0.90 |           0.5.0 |
|    0.91 |           0.6.2 |
|    0.92 |           0.7.1 |
|    0.93 |           0.8.0 |
|    0.93 |           0.9.0 |
|    0.94 |          0.10.0 |
|    0.95 |          0.11.0 |
|    0.96 |          0.12.1 |
|    0.97 |          0.13.0 |
|    0.98 |          0.14.2 |
|    0.98 |          0.15.1 |
|    0.99 |          0.16.1 |
|   0.100 |          0.17.3 |

Note that the plugin will not work in later versions of Nushell, and will not be updated to fix that.  Use the module instead (above).

### Dependencies

The script uses `jq` for output formatting. Previous versions required at least `jq` version `1.7`, but that may be no longer the case.

Also I suspect at least Bash version `5.1`.

Since version `0.15.0`, this plugin uses [`bash-env-json`](https://github.com/tesujimath/bash-env-json) instead of the previously bundled `bash_env.sh` script.  However, this is fetched and embedded at build time, so there is no difference at runtime.

### Examples

#### Simple Usage
```
> bash-env tests/simple.env
╭───┬───╮
│ B │ b │
│ A │ a │
╰───┴───╯

> echo $env.A
Error: nu::shell::name_not_found

  × Name not found


> bash-env tests/simple.env | load-env

> echo $env.A
a
> echo $env.B
b


> bash-env tests/simple.env
╭──────────────╮
│ empty record │
╰──────────────╯

# no new or changed environment variables, so nothing returned

> ssh-agent | bash-env
Agent pid 98985
╭───────────────┬───────────────────────────────────╮
│ SSH_AUTH_SOCK │ /tmp/ssh-XXXXXXFIMT9y/agent.98982 │
│ SSH_AGENT_PID │ 98985                             │
╰───────────────┴───────────────────────────────────╯
```

#### Exporting Shell Variables

The plugin supports `--export` for exporting shell variables into the environment.

```
> echo "ABC=123" | bash-env
╭──────────────╮
│ empty record │
╰──────────────╯

> echo "export ABC=123" | bash-env
╭─────┬─────╮
│ ABC │ 123 │
╰─────┴─────╯

> echo "ABC=123" | bash-env --export [ABC]
╭─────┬─────╮
│ ABC │ 123 │
╰─────┴─────╯

> bash-env /etc/os-release
╭──────────────╮
│ empty record │
╰──────────────╯

> bash-env --export [ID PRETTY_NAME] /etc/os-release
╭─────────────┬──────────────────────╮
│ ID          │ nixos                │
│ PRETTY_NAME │ NixOS 24.05 (Uakari) │
╰─────────────┴──────────────────────╯
```

#### Escaping Special Characters

Care has been taken to escape any special characters.

```
> bash-env `tests/Ming's "menu" of (merciless) monstrosities.env`
╭───────────┬──────────────────────────────────────────────────────╮
│ QUOTE     │ "Well done!" is better than "Well said!"             │
│ SPACEMAN  │ One small step for a man ...                         │
│ MIXED_BAG │ Did the sixth sheik's sixth sheep say "baa", or not? │
╰───────────┴──────────────────────────────────────────────────────╯

> bash-env `tests/Ming's "menu" of (merciless) monstrosities.env` | load-env
> echo $env.QUOTE
"Well done!" is better than "Well said!"
```

### Implementation

Prior to 0.13.0 this plugin was written in Bash, with the Nu plugin protocol done by hand using `jq`, with insights from the [api](api) sub-directory which contained a Rust program to produce what is required, using the official Nu plugin library.  This was too onerous to maintain through the evolution of the protocol, so was abandoned.

Since 0.13.0, the plugin is written in Rust, with the much simplified Bash script embedded.

By default the embedded Bash script is extracted at runtime into a temporary directory.  This behaviour may be overridden by setting the ``NU_PLUGIN_BASH_ENV_JSON` environment variable, which is then expected to resolve to the path of the pre-installed script.

### Logging

Logging is supported via the Rust `tracing-subscriber` crate, with log-level defined by the environment variable `NU_PLUGIN_BASH_ENV_LOG`.
