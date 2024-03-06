#!/bin/bash

# Function to print script usage
print_usage() {
    echo "Usage: $0 <database_name> <collection_name> <output_folder> <documents_per_chunk> [connection_string]"
    echo "  database_name: Name of the MongoDB database from which documents are exported."
    echo "  collection_name: Name of the MongoDB collection to export."
    echo "  output_folder: Path to the folder where the exported data batches will be stored."
    echo "  documents_per_chunk: Number of documents per output batch."
    echo "  connection_string (Optional): MongoDB connection string. Defaults to 'mongodb://localhost:27017' if not provided."
}

# Validate number of arguments
if [ "$#" -lt 4 ] || [ "$#" -gt 5 ]; then
    print_usage
    exit 1
fi

# Assign command-line arguments to variables, with a default connection string
DB_NAME="$1"
COLLECTION_NAME="$2"
OUTPUT_FOLDER="$3"
DOCS_PER_CHUNK="$4"
CONNECTION_STRING="${5:-mongodb://localhost:27017}"  # Default to localhost if no connection string is provided


# get host from connection string
HOST=$(echo $CONNECTION_STRING | awk -F/ '{print $3}' | awk -F: '{print $1}')
# get port from connection string
PORT=$(echo $CONNECTION_STRING | awk -F/ '{print $3}' | awk -F: '{print $2}' | awk -F, '{print $1}')


# Validate documents per chunk as a positive integer
if ! [[ "$DOCS_PER_CHUNK" =~ ^[0-9]+$ ]]; then
    echo "Error: <documents_per_chunk> must be a positive integer."
    exit 1
fi

# Function to execute JavaScript for pagination
paginate() {
    local skip=$1
    local limit=$2
    local start_id=$(mongo $HOST:$PORT/$DB_NAME --quiet --eval "var doc = db.$COLLECTION_NAME.find({}, {_id: 1}).sort({_id: 1}).skip($skip).limit(1).toArray()[0]; if (doc) print(doc._id.str); else print('null');")
    local end_id=$(mongo $HOST:$PORT/$DB_NAME --quiet --eval "var doc = db.$COLLECTION_NAME.find({}, {_id: 1}).sort({_id: 1}).skip($((skip + limit))).limit(1).toArray()[0]; if (doc) print(doc._id.str); else print('null');")
    local query="{\"_id\": {\"\$gte\": {\"\$oid\": \"$start_id\"}, \"\$lt\": {\"\$oid\": \"$end_id\"}}}"
    echo "$query"
}


# Use the connection string for getting total documents
total_documents=$(mongo $HOST:$PORT/$DB_NAME --quiet --eval "db.$COLLECTION_NAME.count()")

echo "Exporting documents from Database: $DB_NAME, Collection: $COLLECTION_NAME"

# Print the total number of documents
echo "Total documents: $total_documents"

# Check if there are documents in the collection
if [ "$total_documents" -eq 0 ]; then
    echo "No documents found in the collection."
    exit 0
fi
# Calculate the number of batches required
num_batches=$(( ($total_documents + DOCS_PER_CHUNK - 1) / DOCS_PER_CHUNK ))

# Process each batch
for (( i=0; i<$num_batches; i++ ))
do
    skip=$((i * DOCS_PER_CHUNK))
    query=$(paginate $skip $DOCS_PER_CHUNK)

    echo "Query for Batch $((i+1)): $query"

    # Execute MongoDB dump with the generated query
    mongodump --uri="$CONNECTION_STRING" --db=$DB_NAME --collection=$COLLECTION_NAME --query="$query" --out="${OUTPUT_FOLDER}/${DB_NAME}-${COLLECTION_NAME}-$((i+1))"
    
    # Move and rename dumped files for easier access
    mv "${OUTPUT_FOLDER}/${DB_NAME}-${COLLECTION_NAME}-$((i+1))/${DB_NAME}/${COLLECTION_NAME}.bson" "${OUTPUT_FOLDER}/${DB_NAME}-${COLLECTION_NAME}-$((i+1))/${COLLECTION_NAME}.bson"
    mv "${OUTPUT_FOLDER}/${DB_NAME}-${COLLECTION_NAME}-$((i+1))/${DB_NAME}/${COLLECTION_NAME}.metadata.json" "${OUTPUT_FOLDER}/${DB_NAME}-${COLLECTION_NAME}-$((i+1))/${COLLECTION_NAME}.metadata.json"
    # Remove the now empty database directory
    rm -r "${OUTPUT_FOLDER}/${DB_NAME}-${COLLECTION_NAME}-$((i+1))/${DB_NAME}"

    echo "Batch $((i+1)) dumped successfully."
done

echo "All batches dumped successfully."
