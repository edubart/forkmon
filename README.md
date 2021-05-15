# Forkmon

Watch for file changes and auto restart an application using fork checkpoints to continue. Intended for quick live development.
This **works only on Linux systems**.

## Quick Usage

Small example of compiling `forkmon` and using with Lua to reload scripts
on the middle:

```sh
git clone https://github.com/edubart/forkmon.git && cd forkmon
make
LD_PRELOAD=./forkmonhook.so FORKMON_FILTER="%.lua$" lua tests/example.lua
```

Now when running the above you should get something like:

```
[forkmon] watch '/home/bart/projects/forkmon/example.lua'
startup
[forkmon] watch '/home/bart/projects/forkmon/foo.lua'
foo!
finished
```

The application will keep running, waiting for any watached file change.
Now try to edit to `foo.lua` and change the print to `'hello world!'`, you should get something like:
```
[forkmon] file '/home/bart/projects/forkmon/tests/foo.lua' changed, resuming from it..
hello world!
finished
```

Notice that only `'hello world!'` is printed, but not `'startup'`,
this means the application did not restart! Because a forked (cloned) application was waiting for changes in the `foo.lua` and resumed.

## How it works

The Linux `fork()` function has the interesting property of cloning
a child process when called, the child process memory remains the same
as the parent process, however both can run independently, each one with its own state and memory. But  this is not a heavy operation,
the process memory is not duplicated, instead
[copy on write](https://en.wikipedia.org/wiki/Copy-on-write) is used,
thus this is a lightweight operation.
This property of `fork()` allows to us
to create checkpoints of the program that we can later use to resume a
new process from the checkpoint without require the application to
start from beginning, effectively rolling back state and memory in time.
If we hook all `fopen()` calls we can make checkpoints
every time a file is opened,
then using [inotify Linux API](https://en.wikipedia.org/wiki/Inotify) we can watch files for
changes and once a file change is detected we can resume a new process
from its checkpoint instead of restarting the whole application.
This allows to gain a few startup time in live development scenarios.

## Options

The tool can be configured using the following environment variables:

* `FORKMON_FILTER` pattern that a watched file name should match, following [Lua pattern rules](https://www.lua.org/manual/5.4/manual.html#6.4.1).
* `FORKMON_QUIET` if set, the tool will be quiet and not print anything.

## Motivation

I had this idea other day when thinking in ways to speedup the [Nelua](https://nelua.io/) compiler, this tool can be used there to skip redundant compiler work.
Because usually when you edit a source file the
compiler needs to go parsing all sources again, even things before
the source file change. This tool is a "hacky" way to
allow the compiler to skip parsing and analyzing everything
before a source file change. And if the sources are designed
in such a way that a separate single source file requires all hardly
ever changing files (similar to precompiled headers in C world),
then the compilation can be much faster by
skipping lots of parsing.

Although this was made for quick live development with Nelua on Linux,
it can be used to speedup other console applications
or compilers. And probably even servers
that goes through a lot of loading and processing during startup,
though the server startup need to be designed in such way that the
checkpoints places does not have networking or multithreading going on.

## Limitations

* Only works well with application where all state
to checkpoint is available in CPU memory, such as
single threaded console applications.
This is not the case for networking, graphical or multithreading applications, to make it work in such
kind of applications extra work would be needed.
* The application must use `open`, `fopen` or `fopen64` to open files,
as these are the only file opening functions hooked. Some applications
uses the `openat` syscall and this case will be missed.
* The application should not launch sub processes, thus this
tool does not work well with GCC/Clang compilers as they launch itself
when compiling, however it works with TCC compiler thus TCC could be even faster for live development!
* File descriptor offset are shared between processes (a `fork()` behavior),
and this can be problematic for applications that keep files open
instead of caching them in memory.

## Implementation details

This has been implemented using the [Nelua](https://nelua.io/)
programming language,
however a standalone C file is bundled in the repository,
thus just a C compiler is needed to compile the project.