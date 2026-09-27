# Operations

NixOS manual from Nixpkgs master snapshot `4593931c855e7cf2ab412b659dd2841030f753df`; development series 26.11.

Modified excerpts from the Nixpkgs contributors; see [COPYING](../COPYING). Source citations are pinned; public manual links may move.

- [Changing the Configuration](#sec-changing-config)
- [Upgrading NixOS](#sec-upgrading)
- [Rolling Back Configuration Changes](#sec-rollback)
- [Cleaning the Nix Store](#sec-nix-gc)
- [Boot Problems](#sec-boot-problems)
- [Service Management](#sec-systemctl)


[Upstream source](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/nixos/doc/manual/installation/changing-config.chapter.md)


# Changing the Configuration

<a id="sec-changing-config"></a>

The file `/etc/nixos/configuration.nix` contains the current
configuration of your machine. Whenever you've [changed something](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/nixos/doc/manual/configuration/configuration.md) (source section: Guides) in that file, you should do

```ShellSession
# nixos-rebuild switch
```

to build the new configuration, make it the default configuration for
booting, and try to realise the configuration in the running system
(e.g., by restarting system services).

**Warning**

This command doesn't start/stop [user services](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/nixos/modules/system/boot/systemd/user.nix) (source section: systemd.user.services)
automatically. `nixos-rebuild` only runs a `daemon-reload` for each user with running
user services.

**End warning.**


**Warning**

These commands must be executed as root, so you should either run them
from a root shell or by prefixing them with `sudo -i`.

**End warning.**


You can also do

```ShellSession
# nixos-rebuild test
```

to build the configuration and switch the running system to it, but
without making it the boot default. So if (say) the configuration locks
up your machine, you can just reboot to get back to a working
configuration.

There is also

```ShellSession
# nixos-rebuild boot
```

to build the configuration and make it the boot default, but not switch
to it now (so it will only take effect after the next reboot).

You can make your configuration show up in a different submenu of the
GRUB 2 boot screen by giving it a different *profile name*, e.g.

```ShellSession
# nixos-rebuild switch -p test
```

which causes the new configuration (and previous ones created using
`-p test`) to show up in the GRUB submenu "NixOS - Profile 'test'".
This can be useful to separate test configurations from "stable"
configurations.

A repl, or read-eval-print loop, is also available. You can inspect your configuration and use the Nix language with

```ShellSession
# nixos-rebuild repl
```

Your configuration is loaded into the `config` variable. Use tab for autocompletion, use the `:r` command to reload the configuration files. See `:?` or [`nix repl` in the Nix manual](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-repl.html) to learn more.

Finally, you can do

```ShellSession
$ nixos-rebuild build
```

to build the configuration but nothing more. This is useful to see
whether everything compiles cleanly.

If you have a machine that supports hardware virtualisation, you can
also test the new configuration in a sandbox by building and running a
QEMU *virtual machine* that contains the desired configuration. Just do

```ShellSession
$ nixos-rebuild build-vm
$ ./result/bin/run-*-vm
```

The VM does not have any data from your host system, so your existing
user accounts and home directories will not be available unless you have
set `mutableUsers = false`. Another way is to temporarily add the
following to your configuration:

```nix
{ users.users.your-user.initialHashedPassword = "test"; }
```

*Important:* delete the \$hostname.qcow2 file if you have started the
virtual machine at least once without the right users, otherwise the
changes will not get picked up. You can forward ports on the host to the
guest. For instance, the following will forward host port 2222 to guest
port 22 (SSH):

```ShellSession
$ QEMU_NET_OPTS="hostfwd=tcp:127.0.0.1:2222-:22" ./result/bin/run-*-vm
```

allowing you to log in via SSH (assuming you have set the appropriate
passwords or SSH authorized keys):

```ShellSession
$ ssh -p 2222 localhost
```

Such port forwardings connect via the VM's virtual network interface.
Thus they cannot connect to ports that are only bound to the VM's
loopback interface (`127.0.0.1`), and the VM's NixOS firewall
must be configured to allow these connections.


[Upstream source](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/nixos/doc/manual/installation/upgrading.chapter.md)


# Upgrading NixOS

<a id="sec-upgrading"></a>

The best way to keep your NixOS installation up to date is to use one of
the NixOS *channels*. A channel is a Nix mechanism for distributing Nix
expressions and associated binaries. The NixOS channels are updated
automatically from NixOS's Git repository after certain tests have
passed and a selection of packages has been built successfully
(see `nixos/release-combined.nix` and `nixos/release-small.nix`).
These channels are:

-   *Stable channels*, such as [`nixos-26.05`](https://channels.nixos.org/nixos-26.05).
    These only get conservative bug fixes and package upgrades. For
    instance, a channel update may cause the Linux kernel on your system
    to be upgraded from 4.19.34 to 4.19.38 (a minor bug fix), but not
    from 4.19.x to 4.20.x (a major change that has the potential to break things).
    Stable channels are generally maintained until the next stable
    branch is created.

-   The *unstable channel*, [`nixos-unstable`](https://channels.nixos.org/nixos-unstable).
    This corresponds to NixOS's main development branch, and may thus see
    radical changes between channel updates. It's not recommended for
    production systems.

-   *Small channels*, such as [`nixos-26.05-small`](https://channels.nixos.org/nixos-26.05-small)
    or [`nixos-unstable-small`](https://channels.nixos.org/nixos-unstable-small).
    These are identical to the stable and unstable channels described above,
    except that they contain fewer binary packages. This means they get updated
    faster than the regular channels (for instance, when a critical security patch
    is committed to NixOS's source tree), but may require more packages to be
    built from source than usual. They're mostly intended for server environments
    and as such contain few GUI applications.

To see what channels are available, go to <https://channels.nixos.org>.
(Note that the URIs of the various channels redirect to a directory that
contains the channel's latest version and includes ISO images and
VirtualBox appliances.) Please note that during the release process,
channels that are not yet released will be present here as well. See the
Getting NixOS page <https://nixos.org/download/> to find the newest
supported stable release.

When you first install NixOS, you're automatically subscribed to the
NixOS channel that corresponds to your installation source. For
instance, if you installed from a 26.05 ISO, you will be subscribed to
the `nixos-26.05` channel.

Commands below are prefixed with `#` and have to be run as root in a
login shell:

```ShellSession
$ sudo -i
```

Without `sudo`:

```ShellSession
$ su -
```

To see which NixOS channel you're subscribed to, run:

```ShellSession
# nix-channel --list | grep nixos
nixos https://channels.nixos.org/nixos-unstable
```

To switch to a different NixOS channel, do

```ShellSession
# nix-channel --add https://channels.nixos.org/channel-name nixos
```

(Be sure to include the `nixos` parameter at the end.) For instance, to
use the NixOS 26.05 stable channel:

```ShellSession
# nix-channel --add https://channels.nixos.org/nixos-26.05 nixos
```

If you have a server, you may want to use the "small" channel instead:

```ShellSession
# nix-channel --add https://channels.nixos.org/nixos-26.05-small nixos
```

And if you want to live on the bleeding edge:

```ShellSession
# nix-channel --add https://channels.nixos.org/nixos-unstable nixos
```

You can then upgrade NixOS to the latest version in your chosen channel
by running

```ShellSession
# nixos-rebuild switch --upgrade
```

which is equivalent to the more verbose `nix-channel --update nixos; nixos-rebuild switch`.

**Note**

Channels are set per user. `nix-channel` reads and writes
`$HOME/.nix-channels`, so it acts on the channels of whoever owns the
current `$HOME`. A login shell sets `$HOME` to `/root`, which is why the
commands above act on root's channels — the ones
`/etc/nixos/configuration.nix` uses.

Plain `sudo` and `su` keep your own `$HOME`. `nix-channel --list` then
lists your own channels, and prints nothing when you have none.
`nix-channel --add` adds the channel for your user alone.

**End note.**


**Warning**

It is generally safe to switch back and forth between channels. The only
exception is that a newer NixOS may also have a newer Nix version, which
may involve an upgrade of Nix's database schema. This cannot be undone
easily, so in that case you will not be able to go back to your original
channel.

**End warning.**


## Automatic Upgrades

<a id="sec-upgrading-automatic"></a>

You can keep a NixOS system up-to-date automatically by adding the
following to `configuration.nix`:

```nix
{
  system.autoUpgrade.enable = true;
  system.autoUpgrade.allowReboot = true;
}
```

This enables a periodically executed systemd service named
`nixos-upgrade.service`. If the `allowReboot` option is `false`, it runs
`nixos-rebuild switch --upgrade` to upgrade NixOS to the latest version
in the current channel. (To see when the service runs, see `systemctl list-timers`.)
If `allowReboot` is `true`, then the system will automatically reboot if
the new generation contains a different kernel, initrd or kernel
modules. You can also specify a channel explicitly, e.g.

```nix
{ system.autoUpgrade.channel = "https://channels.nixos.org/nixos-26.05"; }
```


[Upstream source](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/nixos/doc/manual/administration/rollback.section.md)


# Rolling Back Configuration Changes

<a id="sec-rollback"></a>

After running `nixos-rebuild` to switch to a new configuration, you may
find that the new configuration doesn't work very well. In that case,
there are several ways to return to a previous configuration.

First, the GRUB boot manager allows you to boot into any previous
configuration that hasn't been garbage-collected. These configurations
can be found under the GRUB submenu "NixOS - All configurations". This
is especially useful if the new configuration fails to boot. After the
system has booted, you can make the selected configuration the default
for subsequent boots:

```ShellSession
# /run/current-system/bin/switch-to-configuration boot
```

Second, you can switch to the previous configuration in a running
system:

```ShellSession
# nixos-rebuild switch --rollback
```

This is equivalent to running:

```ShellSession
# /nix/var/nix/profiles/system-N-link/bin/switch-to-configuration switch
```

where `N` is the number of the NixOS system configuration. To get a
list of the available configurations, do:

```ShellSession
$ ls -l /nix/var/nix/profiles/system-*-link
...
lrwxrwxrwx 1 root root 78 Aug 12 13:54 /nix/var/nix/profiles/system-268-link -> /nix/store/202b...-nixos-13.07pre4932_5a676e4-4be1055
```


[Upstream source](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/nixos/doc/manual/administration/cleaning-store.chapter.md)


# Cleaning the Nix Store

<a id="sec-nix-gc"></a>

Nix has a purely functional model, meaning that packages are never
upgraded in place. Instead new versions of packages end up in a
different location in the Nix store (`/nix/store`). You should
periodically run Nix's *garbage collector* to remove old, unreferenced
packages. This is easy:

```ShellSession
$ nix-collect-garbage
```

Alternatively, you can use a systemd unit that does the same in the
background:

```ShellSession
# systemctl start nix-gc.service
```

You can tell NixOS in `configuration.nix` to run this unit automatically
at certain points in time, for instance, every night at 03:15:

```nix
{
  nix.gc.automatic = true;
  nix.gc.dates = "03:15";
}
```

The commands above do not remove garbage collector roots, such as old
system configurations. Thus they do not remove the ability to roll back
to previous configurations. The following command deletes old roots,
removing the ability to roll back to them:

```ShellSession
$ nix-collect-garbage -d
```

You can also do this for specific profiles, e.g.

```ShellSession
$ nix-env -p /nix/var/nix/profiles/per-user/eelco/profile --delete-generations old
```

Note that NixOS system configurations are stored in the profile
`/nix/var/nix/profiles/system`.

Another way to reclaim disk space (often as much as 40% of the size of
the Nix store) is to run Nix's store optimiser, which seeks out
identical files in the store and replaces them with hard links to a
single copy.

```ShellSession
$ nix-store --optimise
```

Since this command needs to read the entire Nix store, it can take quite
a while to finish.

## NixOS Boot Entries

<a id="sect-nixos-gc-boot-entries"></a>

If your `/boot` partition runs out of space, after clearing old profiles
you must rebuild your system with `nixos-rebuild boot` or `nixos-rebuild
switch` to update the `/boot` partition and clear space.


[Upstream source](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/nixos/doc/manual/administration/boot-problems.section.md)


# Boot Problems

<a id="sec-boot-problems"></a>

If NixOS fails to boot, there are a number of kernel command line parameters that may help you to identify or fix the issue. You can add these parameters in the GRUB boot menu by pressing “e” to modify the selected boot entry and editing the line starting with `linux`.

[`kernel-command-line(7)`](https://www.freedesktop.org/software/systemd/man/kernel-command-line.html) documents the kernel parameters accepted by systemd. Those include many that are helpful for debugging boot issues, such as `systemd.debug_shell` and `rescue`. Some also have `rd.`‐prefixed variants that apply to stage 1.

`live.nixos.passwd=password`

Definition: Set the password for the `nixos` live user. This can be used for SSH access if there are issues using the terminal.

If no login prompts or X11 login screens appear (e.g. due to hanging dependencies), you can press Alt+ArrowUp. If you’re lucky, this will start `rescue.target` (described in [`systemd.special(7)`](https://www.freedesktop.org/software/systemd/man/systemd.special.html)). (Also note that since most units have a 90-second timeout before systemd gives up on them, the `agetty` login prompts should appear eventually unless something is very wrong.)

## Scripted stage 1

<a id="sec-boot-problems-scripted-stage-1"></a>

The scripted implementation of stage 1 also understands these boot parameters.

**Warning**

The scripted implementation of stage 1 is disabled by default and deprecated. These parameters have no effect, unless systemd stage 1 is explicitly disabled with `boot.initrd.systemd.enable = false;`.

**End warning.**


`boot.shell_on_fail`

Definition: Allows the user to start a root shell if something goes wrong in stage 1 of the boot process (the initial ramdisk). This is disabled by default because there is no authentication for the root shell.

**Note**

  systemd stage 1 alternative: `SYSTEMD_SULOGIN_FORCE=1` for rescue mode, or `rd.systemd.debug_shell` for shell on tty9.

**End note.**


`boot.debug1`

Definition: Start an interactive shell in stage 1 before anything useful has been done. That is, no modules have been loaded and no file systems have been mounted, except for `/proc` and `/sys`.

**Note**

  systemd stage 1 alternative: `rd.systemd.break=pre-udev`

**End note.**


`boot.debug1devices`

Definition: Like `boot.debug1`, but runs stage1 until kernel modules are loaded and device nodes are created. This may help with e.g. making the keyboard work.

**Note**

  systemd stage 1 alternative: `rd.systemd.break=pre-mount`

**End note.**


`boot.debug1mounts`

Definition: Like `boot.debug1` or `boot.debug1devices`, but runs stage1 until all filesystems that are mounted during initrd are mounted (see [neededForBoot](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/nixos/modules/system/boot/stage-1.nix) (source section: fileSystems.<name>.neededForBoot)). As a motivating example, this could be useful if you've forgotten to set [neededForBoot](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/nixos/modules/system/boot/stage-1.nix) (source section: fileSystems.<name>.neededForBoot) on a file system.

**Note**

  systemd stage 1 alternative: `rd.systemd.break=pre-switch-root`

**End note.**


`boot.trace`

Definition: Print every shell command executed by the stage 1 and 2 boot scripts.

**Note**

  systemd stage 1 alternative: `rd.systemd.log_level=debug`

**End note.**


Notice that for `boot.shell_on_fail`, `boot.debug1`, `boot.debug1devices`, and `boot.debug1mounts`, if you did **not** select "start the new shell as pid 1", and you `exit` from the new shell, boot will proceed normally from the point where it failed, as if you'd chosen "ignore the error and continue".


[Upstream source](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/nixos/doc/manual/administration/service-mgmt.chapter.md)


# Service Management

<a id="sec-systemctl"></a>

In NixOS, all system services are started and monitored using the
systemd program. systemd is the "init" process of the system (i.e. PID
1), the parent of all other processes. It manages a set of so-called
"units", which can be things like system services (programs), but also
mount points, swap files, devices, targets (groups of units) and more.
Units can have complex dependencies; for instance, one unit can require
that another unit must be successfully started before the first unit can
be started. When the system boots, it starts a unit named
`default.target`; the dependencies of this unit cause all system
services to be started, file systems to be mounted, swap files to be
activated, and so on.

## Interacting with a running systemd

<a id="sect-nixos-systemd-general"></a>

The command `systemctl` is the main way to interact with `systemd`. The
following paragraphs demonstrate ways to interact with any OS running
systemd as init system. NixOS is of no exception. The [next section](operations.md#sect-nixos-systemd-nixos) explains NixOS specific things worth
knowing.

Without any arguments, `systemctl` the status of active units:

```ShellSession
$ systemctl
-.mount          loaded active mounted   /
swapfile.swap    loaded active active    /swapfile
sshd.service     loaded active running   SSH Daemon
graphical.target loaded active active    Graphical Interface
...
```

You can ask for detailed status information about a unit, for instance,
the PostgreSQL database service:

```ShellSession
$ systemctl status postgresql.service
postgresql.service - PostgreSQL Server
          Loaded: loaded (/nix/store/pn3q73mvh75gsrl8w7fdlfk3fq5qm5mw-unit/postgresql.service)
          Active: active (running) since Mon, 2013-01-07 15:55:57 CET; 9h ago
        Main PID: 2390 (postgres)
          CGroup: name=systemd:/system/postgresql.service
                  ├─2390 postgres
                  ├─2418 postgres: writer process
                  ├─2419 postgres: wal writer process
                  ├─2420 postgres: autovacuum launcher process
                  ├─2421 postgres: stats collector process
                  └─2498 postgres: zabbix zabbix [local] idle

Jan 07 15:55:55 hagbard postgres[2394]: [1-1] LOG:  database system was shut down at 2013-01-07 15:55:05 CET
Jan 07 15:55:57 hagbard postgres[2390]: [1-1] LOG:  database system is ready to accept connections
Jan 07 15:55:57 hagbard postgres[2420]: [1-1] LOG:  autovacuum launcher started
Jan 07 15:55:57 hagbard systemd[1]: Started PostgreSQL Server.
```

Note that this shows the status of the unit (active and running), all
the processes belonging to the service, as well as the most recent log
messages from the service.

Units can be stopped, started or restarted:

```ShellSession
# systemctl stop postgresql.service
# systemctl start postgresql.service
# systemctl restart postgresql.service
```

These operations are synchronous: they wait until the service has
finished starting or stopping (or has failed). Starting a unit will
cause the dependencies of that unit to be started as well (if
necessary).

## systemd in NixOS

<a id="sect-nixos-systemd-nixos"></a>

Packages in Nixpkgs sometimes provide systemd units with them, usually
in e.g `#pkg-out#/lib/systemd/`. Putting such a package in
`environment.systemPackages` doesn't make the service available to
users or the system.

In order to enable a systemd *system* service with provided upstream
package, use (e.g):

```nix
{ systemd.packages = [ pkgs.packagekit ]; }
```

Usually NixOS modules written by the community do the above, plus take
care of other details. If a module was written for a service you are
interested in, you'd probably need only to use
`services.#name#.enable = true;`. These services are defined in
Nixpkgs' [ `nixos/modules/` directory](https://github.com/NixOS/nixpkgs/tree/master/nixos/modules). In case
the service is simple enough, the above method should work, and start
the service on boot.

*User* systemd services on the other hand, should be treated
differently. Given a package that has a systemd unit file at
`#pkg-out#/lib/systemd/user/`, using [systemd.packages](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/nixos/modules/system/boot/systemd.nix) (source section: systemd.packages) will
make you able to start the service via `systemctl --user start`, but it
won't start automatically on login. However, You can imperatively
enable it by adding the package's attribute to
[systemd.packages](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/nixos/modules/system/boot/systemd.nix) (source section: systemd.packages) and then do this (e.g):

```ShellSession
$ mkdir -p ~/.config/systemd/user/default.target.wants
$ ln -s /run/current-system/sw/lib/systemd/user/syncthing.service ~/.config/systemd/user/default.target.wants/
$ systemctl --user daemon-reload
$ systemctl --user enable syncthing.service
```

If you are interested in a timer file, use `timers.target.wants` instead
of `default.target.wants` in the 1st and 2nd command.

Using `systemctl --user enable syncthing.service` instead of the above,
will work, but it'll use the absolute path of `syncthing.service` for
the symlink, and this path is in `/nix/store/.../lib/systemd/user/`.
Hence [garbage collection](operations.md#sec-nix-gc) will remove that file and you
will wind up with a broken symlink in your systemd configuration, which
in turn will not make the service / timer start on login.

### Defining custom services

<a id="sect-nixos-systemd-custom-services"></a>

You can define services by adding them to `systemd.services`:

```nix
{
  systemd.services.myservice = {
    after = [ "network-online.target" ];
    requires = [ "network-online.target" ];

    before = [ "multi-user.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      ExecStart = "...";
    };
  };
}
```

If you want to specify a multi-line script for `ExecStart`,
you may want to use `pkgs.writeShellScript`.

### Template units

<a id="sect-nixos-systemd-template-units"></a>

systemd supports templated units where a base unit can be started multiple
times with a different parameter. The syntax to accomplish this is
`service-name@instance-name.service`. Units get the instance name passed to
them (see `systemd.unit(5)`). NixOS has support for these kinds of units and
for template-specific overrides. A service needs to be defined twice, once
for the base unit and once for the instance. All instances must include
`overrideStrategy = "asDropin"` for the change detection to work. This
example illustrates this:
```nix
{
  systemd.services = {
    "base-unit@".serviceConfig = {
      ExecStart = "...";
      User = "...";
    };
    "base-unit@instance-a" = {
      overrideStrategy = "asDropin"; # needed for templates to work
      wantedBy = [ "multi-user.target" ]; # causes NixOS to manage the instance
    };
    "base-unit@instance-b" = {
      overrideStrategy = "asDropin"; # needed for templates to work
      wantedBy = [ "multi-user.target" ]; # causes NixOS to manage the instance
      serviceConfig.User = "root"; # also override something for this specific instance
    };
  };
}
```
