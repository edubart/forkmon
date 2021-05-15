# Forkmon

Watch for file changes and auto restart an application using fork checkpoints to continue the process. Intended for quick live development.
This **works only on Linux systems**.

## How it works

The Linux `fork()` function has the interesting property of cloning
a child process when called, the child process memory remains the same
as the parent process, however both can run independently, each one with its own state and memory.
This property of `fork()` allows to us
to create checkpoints of the program that we can later use to resume a
new process from the checkpoint without require the application to
start from beginning, effectively rolling back state and memory in time.
If we hook all `fopen()` calls we can make checkpoints
every time a file is opened,
then using `inotify` Linux API we can watch that file for
changes and once a file change is detected we can resume a new process
from its checkpoint instead of restarting the whole application.
This allows to gain a few startup time in live development scenarios.

## Motivation

I had this idea other day when thinking in ways to speedup the Nelua compiler, this tool can be used to skip redundant compiler work.
Because usually when you edit a source file the
compiler needs to go parsing all sources again, even things before
the source file change. This tool is a tricky way to
allow the compiler to skip parsing and analyzing everything
before the source file change. And if the sources are designed
in such a way that a "precompiled source file" requires all hardly
ever changing files, then the compilation can be much faster by
skipping lots of parsing.

Although this was made for quick live development with Nelua on Linux,
it can be used to speedup other console applications
or compilers. And probably even servers
that goes through a lot of loading and processing during startup,
though the server startup need to be designed so the
checkpoints places does not have networking or multithreading going on.

## Limitations

* Only works well with application where all state
to checkpoint is available in its CPU memory, such as
single threaded console applications.
This is not the case for network, graphical or multithreading applications, to make it work in such
kind of applications extra work would be needed on its side.
* The application must use `open`, `fopen` or `fopen64` to open files,
as these are the only file opening functions hooked. Some applications
uses the `openat` syscall and we are unable to hook.
* The application should not launch sub processes, thus this
tool does not work with GCC/Clang compilers as they launch itself
when compiling, however it works with TCC compiler.
* File descriptor offset are shared between processes (`fork()` behavior),
and this can be problematic for applications that keep files open
instead of caching them in memory.
