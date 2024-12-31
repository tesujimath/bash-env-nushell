# Bash environment for Nushell

Historically Bash environment for Nushell was provided via the `nu_plugin_bash_env` plugin in this repo.

That plugin has now been removed in favour of the `bash-env` module, which is more feature rich and also embarrassingly simpler than the plugin.  For historical documentation for the plugin see its [README](README.plugin.md).

## bash-env module

### Examples

#### Simple Usage
```
> bash-env ./tests/simple.env
╭───┬───╮
│ B │ b │
│ A │ a │
╰───┴───╯
> echo $env.A
Error: nu::shell::column_not_found

  × Cannot find column 'A'
   ╭─[entry #77:1:6]
 1 │ echo $env.A
   ·      ───┬──┬
   ·         │  ╰── value originates here
   ·         ╰── cannot find column 'A'
   ╰────

> bash-env ./tests/simple.env | load-env
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
╭───────────────┬─────────────────────────────────────╮
│ SSH_AUTH_SOCK │ /tmp/ssh-XXXXXXOjZtSh/agent.1612713 │
│ SSH_AGENT_PID │ 1612715                             │
╰───────────────┴─────────────────────────────────────╯
```

#### Shell Variables

Rather than folding shell variables in with the environment variables as was done by the plugin, the `-s` or `--shellvars` option results in structured output with separate `env` and `shellvars`.

```
> echo "ABC=123" | bash-env
╭──────────────╮
│ empty record │
╰──────────────╯

> echo "ABC=123" | bash-env -s
╭───────────┬───────────────────╮
│ env       │ {record 0 fields} │
│           │ ╭─────┬─────╮     │
│ shellvars │ │ ABC │ 123 │     │
│           │ ╰─────┴─────╯     │
╰───────────┴───────────────────╯
> (echo "ABC=123" | bash-env -s).shellvars
╭─────┬─────╮
│ ABC │ 123 │
╰─────┴─────╯

> bash-env /etc/os-release
╭──────────────╮
│ empty record │
╰──────────────╯

> (bash-env /etc/os-release -s).shellvars
╭───────────────────┬─────────────────────────────────────────╮
│ LOGO              │ nix-snowflake                           │
│ NAME              │ NixOS                                   │
│ BUG_REPORT_URL    │ https://github.com/NixOS/nixpkgs/issues │
│ HOME_URL          │ https://nixos.org/                      │
│ VERSION_CODENAME  │ vicuna                                  │
│ ANSI_COLOR        │ 1;34                                    │
│ ID                │ nixos                                   │
│ PRETTY_NAME       │ NixOS 24.11 (Vicuna)                    │
│ DOCUMENTATION_URL │ https://nixos.org/learn.html            │
│ SUPPORT_URL       │ https://nixos.org/community.html        │
│ IMAGE_ID          │                                         │
│ VERSION_ID        │ 24.11                                   │
│ VERSION           │ 24.11 (Vicuna)                          │
│ IMAGE_VERSION     │                                         │
│ BUILD_ID          │ 24.11.20240916.99dc878                  │
╰───────────────────┴─────────────────────────────────────────╯
```

### Shell Functions

Shell functions may be run and their effect on the environment captured.

```
> cat ./tests/shell-functions.env
export A=1
export B=1

function f2() {
        export A=2
        export B=2
        C2="I am shell variable C2"
}

function f3() {
        export A=3
        export B=3
        C3="I am shell variable C3"
}
> bash-env ./tests/shell-functions.env
╭───┬───╮
│ B │ 1 │
│ A │ 1 │
╰───┴───╯
> bash-env -f [f2 f3] ./tests/shell-functions.env
╭───────────┬──────────────────────────────────────────────────────────╮
│           │ ╭───┬───╮                                                │
│ env       │ │ B │ 1 │                                                │
│           │ │ A │ 1 │                                                │
│           │ ╰───┴───╯                                                │
│ shellvars │ {record 0 fields}                                        │
│           │ ╭────┬─────────────────────────────────────────────────╮ │
│ fn        │ │    │ ╭───────────┬─────────────────────────────────╮ │ │
│           │ │ f2 │ │           │ ╭───┬───╮                       │ │ │
│           │ │    │ │ env       │ │ B │ 2 │                       │ │ │
│           │ │    │ │           │ │ A │ 2 │                       │ │ │
│           │ │    │ │           │ ╰───┴───╯                       │ │ │
│           │ │    │ │           │ ╭────┬────────────────────────╮ │ │ │
│           │ │    │ │ shellvars │ │ C2 │ I am shell variable C2 │ │ │ │
│           │ │    │ │           │ ╰────┴────────────────────────╯ │ │ │
│           │ │    │ ╰───────────┴─────────────────────────────────╯ │ │
│           │ │    │ ╭───────────┬─────────────────────────────────╮ │ │
│           │ │ f3 │ │           │ ╭───┬───╮                       │ │ │
│           │ │    │ │ env       │ │ B │ 3 │                       │ │ │
│           │ │    │ │           │ │ A │ 3 │                       │ │ │
│           │ │    │ │           │ ╰───┴───╯                       │ │ │
│           │ │    │ │           │ ╭────┬────────────────────────╮ │ │ │
│           │ │    │ │ shellvars │ │ C3 │ I am shell variable C3 │ │ │ │
│           │ │    │ │           │ ╰────┴────────────────────────╯ │ │ │
│           │ │    │ ╰───────────┴─────────────────────────────────╯ │ │
│           │ ╰────┴─────────────────────────────────────────────────╯ │
╰───────────┴──────────────────────────────────────────────────────────╯

> (bash-env -f [f2 f3] ./tests/shell-functions.env).fn.f2.env
╭───┬───╮
│ B │ 2 │
│ A │ 2 │
╰───┴───╯
> (bash-env -f [f2 f3] ./tests/shell-functions.env).fn.f2.env | load-env
> echo $env.B
2

```

### Installation

Download the module, and add to `config.nu`:

```
use /path/to/bash-env.nu
```

In contrast to the plugin, the module requires [`bash-env-json`](https://github.com/tesujimath/bash-env-json) to be separately downloaded and installed as an executable on the `$PATH`.

## Nix flake

The module is installable from its flake using Nix Home Manager.

See my own [Home Manager flake](https://github.com/tesujimath/home.nix/blob/main/flake.nix#L12) and [nushell module](https://github.com/tesujimath/home.nix/blob/main/modules/nushell/default.nix) for hints how to achieve this.  Note in particular the requirement for [each-time plugin registration](https://github.com/tesujimath/home.nix/blob/main/modules/nushell/config.nu#L761).

## Future work

- unsetting an environment variable ought to be possible
