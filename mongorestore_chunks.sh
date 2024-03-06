#!/bin/bash

# Function to print script usage
print_usage() {
    echo "Usage: $0 [connection_string] <database_name> <chunks_folder> [collection_name]"
    echo "  connection_string (Optional): MongoDB connection string. Defaults to 'mongodb://localhost:27017' if not provided."
    echo "  database_name: Name of the MongoDB database from which documents are exported. This argument is mandatory."
    echo "  chunks_folder: Path to the folder where the dumped data batches are stored. This argument is mandatory."
    echo "  collection_name (Optional): Name of the MongoDB collection to restore. If not provided, all collections within the chunks_folder will be restored."
}

# Default values
DEFAULT_CONNECTION_STRING="mongodb://localhost:27017"

# Check for minimum arguments and print usage for incorrect cases
if [ "$#" -lt 2 ]; then
    print_usage
    exit 1
fi

# Determine if the first argument looks like a connection string (starts with mongodb:// or mongodb+srv://)
if [[ "$1" == mongodb://* ]] || [[ "$1" == mongodb+srv://* ]]; then
    if [ "$#" -lt 3 ]; then
        print_usage
        exit 1
    fi
    CONNECTION_STRING="$1"
    DB_NAME="$2"
    CHUNKS_FOLDER="$3"  
    COLLECTION_NAME="${4:-}"      # Optional collection name
else
    CONNECTION_STRING="$DEFAULT_CONNECTION_STRING"
    DB_NAME="$1"
    CHUNKS_FOLDER="$2"
    COLLECTION_NAME="${3:-}"      # Optional collection name
fi

# Check if database name was provided
if [ -z "$DB_NAME" ] || [ -z "$CHUNKS_FOLDER" ]; then
    echo "Error: Both database name and chunks_folder are mandatory."
    print_usage
    exit 1
fi

# Function to restore from dumped chunks
restore_chunks() {
    local folder="$1"
    local db_name="$2"
    local collection_filter="$3"

    # Loop through each dumped chunk folder
    for chunk_folder in "$folder"/*; do
        echo "Processing $chunk_folder"
        
        # Check if it's a directory
        if [ -d "$chunk_folder" ]; then
            # Derive the database and collection name from the folder if not provided
            IFS='-' read -ra ADDR <<< "$(basename "$chunk_folder")"
            local folder_db_name="${ADDR[0]}"
            local collection_name="${ADDR[1]}"

            # If a collection filter is specified and does not match the current collection, skip it
            if [ ! -z "$collection_filter" ] && [ "$collection_filter" != "$collection_name" ]; then
                echo "Skipping $chunk_folder as it does not match the specified collection name $collection_filter"
                continue
            fi

            echo "Restoring to Database: $db_name, Collection: $collection_name"
            
            # Construct the mongorestore command
            local bson_file_path="$chunk_folder/${collection_name}.bson"
            
            if [ -f "$bson_file_path" ]; then
                mongorestore --uri="$CONNECTION_STRING" --db="$db_name" --collection="$collection_name" "$bson_file_path"
                echo "Restored $bson_file_path to $db_name.$collection_name successfully."
            else
                echo "No BSON file found for $collection_name in $chunk_folder"
            fi
        fi
    done
}

# Main execution
restore_chunks "$CHUNKS_FOLDER" "$DB_NAME" "$COLLECTION_NAME"

echo "All relevant chunks restored successfully."
#!/bin/bash

# Function to print script usage
print_usage() {
    echo "Usage: $0 [connection_string] <database_name> <chunks_folder> [collection_name]"
    echo "  connection_string (Optional): MongoDB connection string. Defaults to 'mongodb://localhost:27017' if not provided."
    echo "  database_name: Name of the MongoDB database from which documents are exported. This argument is mandatory."
    echo "  chunks_folder: Path to the folder where the dumped data batches are stored. This argument is mandatory."
    echo "  collection_name (Optional): Name of the MongoDB collection to restore. If not provided, all collections within the chunks_folder will be restored."
}

# Default values
DEFAULT_CONNECTION_STRING="mongodb://localhost:27017"

# Check for minimum arguments and print usage for incorrect cases
if [ "$#" -lt 2 ]; then
    print_usage
    exit 1
fi

# Determine if the first argument looks like a connection string (starts with mongodb:// or mongodb+srv://)
if [[ "$1" == mongodb://* ]] || [[ "$1" == mongodb+srv://* ]]; then
    if [ "$#" -lt 3 ]; then
        print_usage
        exit 1
    fi
    CONNECTION_STRING="$1"
    DB_NAME="$2"
    CHUNKS_FOLDER="$3"  
    COLLECTION_NAME="${4:-}"      # Optional collection name
else
    CONNECTION_STRING="$DEFAULT_CONNECTION_STRING"
    DB_NAME="$1"
    CHUNKS_FOLDER="$2"
    COLLECTION_NAME="${3:-}"      # Optional collection name
fi

# Check if database name was provided
if [ -z "$DB_NAME" ] || [ -z "$CHUNKS_FOLDER" ]; then
    echo "Error: Both database name and chunks_folder are mandatory."
    print_usage
    exit 1
fi

# Function to restore from dumped chunks
restore_chunks() {
    local folder="$1"
    local db_name="$2"
    local collection_filter="$3"

    # Loop through each dumped chunk folder
    for chunk_folder in "$folder"/*; do
        echo "Processing $chunk_folder"
        
        # Check if it's a directory
        if [ -d "$chunk_folder" ]; then
            # Derive the database and collection name from the folder if not provided
            IFS='-' read -ra ADDR <<< "$(basename "$chunk_folder")"
            local folder_db_name="${ADDR[0]}"
            local collection_name="${ADDR[1]}"

            # If a collection filter is specified and does not match the current collection, skip it
            if [ ! -z "$collection_filter" ] && [ "$collection_filter" != "$collection_name" ]; then
                echo "Skipping $chunk_folder as it does not match the specified collection name $collection_filter"
                continue
            fi

            echo "Restoring to Database: $db_name, Collection: $collection_name"
            
            # Construct the mongorestore command
            local bson_file_path="$chunk_folder/${collection_name}.bson"
            
            if [ -f "$bson_file_path" ]; then
                mongorestore --uri="$CONNECTION_STRING" --db="$db_name" --collection="$collection_name" "$bson_file_path"
                echo "Restored $bson_file_path to $db_name.$collection_name successfully."
                
                # Wait for 1 second after each chunk insertion
                sleep 1
            else
                echo "No BSON file found for $collection_name in $chunk_folder"
            fi
        fi
    done
}

# Main execution
restore_chunks "$CHUNKS_FOLDER" "$DB_NAME" "$COLLECTION_NAME"

echo "All relevant chunks restored successfully."
