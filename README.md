# README for Backup Script.
**Author: Egor Sergeev**

## Overview

This Bash script creates a backup of a specified directory, optionally compresses it using a chosen algorithm, and encrypts the resulting archive. The script logs errors to a file *"backup_errors.log"* for troubleshooting.

## Features

- Supports multiple compression algorithms: `none`, `gzip`, `bzip2`, and `xz`.
- Encrypts the backup file using AES-256-CBC with PBKDF2 key derivation.
- Logs error messages to a log file for easy debugging.

## Prerequisites

- Bash shell
- OpenSSL for encryption
- Access to required compression utilities (e.g., `tar`, `gzip`, `bzip2`, `xz`)

## Usage

```bash
./backup_script.sh -d <source_directory> -a <compression_algorithm> -o <output_filename> [-h|--help]
