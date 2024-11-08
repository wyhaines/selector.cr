![Selector CI](https://img.shields.io/github/actions/workflow/status/wyhaines/selector.cr/ci.yml?branch=main&style=for-the-badge&logo=GitHub)
[![GitHub release](https://img.shields.io/github/release/wyhaines/selector.cr.svg?style=for-the-badge)](https://github.com/wyhaines/selector.cr/releases)
![GitHub commits since latest release (by SemVer)](https://img.shields.io/github/commits-since/wyhaines/selector.cr/latest?style=for-the-badge)

# selector

Selector implements a simple command line utility that takes a list of data items from the command line or STDIN (or both). Those elements are then displayed, one per line, with an empty checkbox next to it. The user can scroll through the list, selecting the items of interest. After completing that, pressing enter will return all of the selected elements on STDOUT.

The purpose of this utility is to provide a nice UI for operations where one wants to perform batch operations on some set of manually selected items. An example of this would be a utility that lists all git branches, and then deletes the selected branches. A sample implementation of this can be found [in this gist](https://gist.github.com/wyhaines/253702f70bd6d19b695e1afc30a3dc7b).

Here's an example of that gist being used to clean up some old git branches:

https://github.com/user-attachments/assets/7336a809-95ad-4735-b878-c1fa204e5bf4

## Installation

Download a prebuilt binary from [Releases](https://github.com/wyhaines/selector.cr/releases), or build from source.

To build from source, ensure that Crystal is installed on your OS: https://crystal-lang.org/install/

Clone this repository:

```bash
git clone https://github.com/wyhaines/selector.cr.git
```

Build the utility:

```bash
cd selector
shards build -p -s -t --release
```

The completed binary will be found at `bin/selector`.

## Usage

Select some set of arguments passed on the command line:

```bash
selector a b c d e f g h i j | awk '{print "You selected " $0}'
```

If you selected `a`, `e`, and `i`, this would print `You selected a e i`.

Select from a list passed via STDIN:

```bash
/bin/ls | selector -d "\n" | xargs -l1 echo
```

This will output, one per line, the file names that are selected.

For command line help:

```bash
selector -h
```

```
❯ selector -h
  Usage: selector [options] [items...]

  selector displays everything passed on the command line (other than valid arguments), as well as all lines that are passed on STDIN,
  on-screen with a simple text based UI to scroll through them, selecting some subset. The subset that is selected will be returned on STDOUT.

  Use the up and down arrows to move through the list.
  Press SPACE or 'x' to toggle the selected status of an item.
  Press 'q' to discard all selections and exit.
  Press ENTER to accept all selections.

    -d DELIMITER, --delimiter=DELIMITER
                               Specify output delimiter
    -i DELIMITER, --input-delimiter=DELIMITER
                               Specify input delimiter for STDIN (default: newline)
    -v, --version              Show the selector version (v1.0.0)
    -h, --help                 Show this help
```

## Contributing

1. Fork it (<https://github.com/wyhaines/selector/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Kirk Haines](https://github.com/wyhaines) - creator and maintainer
