# Script Utilities

This repository contains various scripts to help with development and automation tasks.

## Installation

To install the scripts, navigate to the directory containing `install_scripts.sh` and run:

```bash
sudo ./install_scripts.sh
```

This will copy all `.sh` scripts from the `bin` folder to your `/usr/local/bin` directory, removing the `.sh` extension and making them executable.


## Available Scripts

### `docker-stop`

Stops and removes all running Docker containers.

#### Usage

```bash
./docker-stop.sh
```

### `generate_release_notes`

This script helps to generate AI-based release notes for a Git repository. It fetches the Git log between two tags or branches, formats the log for AI processing, and copies the formatted log to the clipboard. The AI prompt includes:

- New Features
- Improvements
- Other Changes

#### Usage

```bash
generate_release_notes <older_tag> [optional: latest_tag]
```

#### Parameters

- `<older_tag>`: The tag or branch to start the log from.
- `[optional: latest_tag]`: (default `main` or `master`) The tag or branch to end the log at.

#### Prerequisites

- The script must be run inside a Git repository.
- `pbcopy` must be available on the system (macOS default clipboard utility).

#### Examples

```bash
generate_release_notes v1.0.0 v1.1.0
generate_release_notes v1.0.0
```

The prompt for AI will be prepared and copied to the clipboard for further processing.

## Contribution

Feel free to fork this repository and add more scripts or improve the existing ones. Pull requests are welcome!

## License

This project is licensed under the MIT License.