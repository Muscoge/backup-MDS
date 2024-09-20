#!/bin/bash

# Log file for error messages
LOG_FILE="backup_errors.log"

# Function to display help information
function display_help {
    echo "Usage: $0 -d <source_directory> -a <compression_algorithm> -o <output_filename> [-h|--help]"
    echo
    echo "Options:"
    echo " -d, --directory           Source directory to back up."
    echo " -a, --algorithm           Compression method (none, gzip, bzip2, xz)."
    echo " -o, --output              Desired name for the output file."
    echo " -h, --help                Show this help message."
    echo
    echo "Encryption utilizes aes-256-cbc with PBKDF2 key derivation."
    exit 0
}

# Function to log errors to the log file
function log_error {
    echo "$1" >> "$LOG_FILE"
}

# Function to validate user input
function validate_input {
    # Check if required variables are set
    if [[ -z "$SOURCE_DIR" || -z "$COMPRESSION_ALGO" || -z "$OUTPUT_NAME" ]]; then
        log_error "Input error: All arguments are required."
        display_help
        exit 1
    fi
    
    # Check if the specified directory exists
    if [[ ! -d "$SOURCE_DIR" ]]; then
        log_error "Directory not found: $SOURCE_DIR"
        exit 1
    fi
    
    # Ensure the output name is different from the source directory name
    if [[ "$SOURCE_DIR" == "$OUTPUT_NAME" ]]; then
        log_error "Output name must differ from source directory name."
        exit 1
    fi
}

# Function to create a backup archive with the specified compression algorithm
function create_archive {
    local compression_cmd=""  # Variable to hold the compression command
    local archive_file="$OUTPUT_NAME"  # Output file name
    
    # Determine the appropriate compression command based on the specified algorithm
    case "$COMPRESSION_ALGO" in
        none)
            # Create a gzipped tarball
            compression_cmd="tar -cvf $archive_file.tar -C $(dirname "$SOURCE_DIR") $(basename "$SOURCE_DIR")"
            ;;
        gzip)
            # Create a gzipped tarball
            compression_cmd="tar -czf $archive_file.tar.gz -C $(dirname "$SOURCE_DIR") $(basename "$SOURCE_DIR")"
            ;;
        bzip2)
            # Create a bzip2 compressed tarball
            compression_cmd="tar -cjf $archive_file.tar.bz2 -C $(dirname "$SOURCE_DIR") $(basename "$SOURCE_DIR")"
            ;;
        xz)
            # Create an xz compressed tarball
            compression_cmd="tar -cJf $archive_file.tar.xz -C $(dirname "$SOURCE_DIR") $(basename "$SOURCE_DIR")"
            ;;
        *)
            # Handle unsupported compression algorithms
            log_error "Unsupported compression algorithm: $COMPRESSION_ALGO"
            exit 1
            ;;
    esac
    
    # Execute the compression command and log any errors
    eval $compression_cmd 2>>"$LOG_FILE"
    if [[ $? -ne 0 ]]; then
        log_error "Backup process failed."
        exit 1
    fi
}

# Function to encrypt the backup file
function encrypt_archive {
    # Locate the backup file based on the output name and compression format
    local backup_file=$(find . -maxdepth 1 -type f \( -name "${OUTPUT_NAME}.tar.xz" -o -name "${OUTPUT_NAME}.tar.gz" -o -name "${OUTPUT_NAME}.tar.bz2" -o -name "${OUTPUT_NAME}.tar" \))
    
    # Check if the backup file exists
    if [[ -n "$backup_file" ]]; then
        # Encrypt the backup file using OpenSSL
        openssl enc -aes-256-cbc -salt -pbkdf2 -in "$backup_file" -out "$backup_file.enc" 2>>"$LOG_FILE"
        if [[ $? -ne 0 ]]; then
            log_error "Encryption process failed."
            exit 1
        fi
        
        # Remove the unencrypted backup file
        rm -f "$backup_file"
    else
        # Log error if no backup file was found
        log_error "No backup file found for encryption."
        exit 1
    fi
}

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -d|--directory)
            SOURCE_DIR="$2"  # Assign source directory
            shift 2
            ;;
        -a|--algorithm)
            COMPRESSION_ALGO="$2"  # Assign compression algorithm
            shift 2
            ;;
        -o|--output)
            OUTPUT_NAME="$2"  # Assign output filename
            shift 2
            ;;
        -h|--help)
            display_help  # Show help message
            ;;
        *)
            log_error "Unknown option: $1"  # Log unknown options
            display_help
            ;;
    esac
done

# Suppress standard output (redirect to /dev/null)
exec 1>/dev/null

# Validate input parameters
validate_input

# Create backup archive
create_archive

# Encrypt the backup
encrypt_archive

exit 0
