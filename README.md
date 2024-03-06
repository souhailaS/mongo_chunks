# mongo_chunks
<!-- ![alt text](images/d98743a1-123d-4627-9867-ad3490690bd8.webp) -->
<img src="images/d98743a1-123d-4627-9867-ad3490690bd8.webp" width="600" >

How to use :

- export the data from the mongo db using the mongodump_chunks.sh script

*Example*
```bash
./mongodump_chunks.sh  my_database collection_1  '/Users/username/Documents/mongo_chunks' 1000
```
1000 is the number of documents per chunk. This can be adjusted based on the available system resources and the desired size of the exported batches. Smaller chunks may be more manageable for processing and transferring, while larger chunks may be less memory-efficient at restoration time.

- restore the data using the mongorestore_chunks.sh script

*Example*
```bash
./mongorestore_chunks.sh my_database '/Users/username/Documents/mongo_chunks'
```

Or if you want to restore a specific collection:

```bash
./mongorestore_chunks.sh my_database '/Users/username/Documents/mongo_chunks' collection_1
```


### Requirements
```
brew tap mongodb/brew
brew install mongodb-community-shell
```


## mongodump_chunks

### Overview

This script exports documents from a specified MongoDB collection into manageable chunks. It's designed to work with large datasets by dividing the collection into smaller batches, allowing for easier processing.

### Usage

```bash
./mongodump_chunks.sh <database_name> <collection_name> <output_folder> <documents_per_chunk> [connection_string]
```

Parameters:
- `database_name`: Name of the database.
- `collection_name`: Name of the collection to export.
- `output_folder`: Destination folder for the exported batches.
- `documents_per_chunk`: Number of documents per batch.
- `connection_string` (Optional): MongoDB connection URI (defaults to `mongodb://localhost:27017`).

The number of documents per chunk can be adjusted based on the available system resources and the desired size of the exported batches. Smaller chunks may be more manageable for processing and transferring, while larger chunks may be less memory-efficient at restoration time.

### Output Structure

The script generates a structured filesystem within the `output_folder`, organizing the exported data into subfolders for each batch, each containing the batch's documents and metadata. An example of the output structure for a database named `mydb` and collection `mycollection` with batches of 1000 documents:

```
output_folder/
├── mydb-mycollection-1/
│   ├── mycollection.bson
│   └── mycollection.metadata.json
├── mydb-mycollection-2/
│   ├── mycollection.bson
│   └── mycollection.metadata.json
...
```

- **`.bson` files**: Contain the exported documents for the batch.
- **`.metadata.json` files**: Include metadata about the export process.

### Example

```bash
./mongodump_chunks.sh  my_database collection_1  '/Users/username/Documents/mongo_chunks' 1000
```


## mongorestore_chunks

### Overview
This script automates the restoration of MongoDB databases from dumped data batches (chunks). It's designed to work with MongoDB dumps that are organized into separate folders for each collection within a database. The script supports optional specifications of a MongoDB connection string, a specific database name, a mandatory chunks folder containing the dumped data, and an optional specific collection name for selective restoration. 


### Usage

```bash
./restore_script.sh [connection_string] <database_name> <chunks_folder> [collection_name]
```


- `connection_string` (Optional): MongoDB connection string. Defaults to 'mongodb://localhost:27017'.
- `database_name` (Mandatory): Name of the MongoDB database to restore.
- `chunks_folder` (Mandatory): Path to the folder containing the dumped data batches.
- `collection_name` (Optional): Name of the MongoDB collection to specifically restore. If not specified, all collections are restored.

### Output Structure
The script processes each folder within the specified `chunks_folder`, where each folder corresponds to a dumped collection named in the format `<database_name>-<collection_name>`. For each of these folders, it restores the `.bson` files found inside to the specified MongoDB database, under the collection name derived from the folder name. If a `collection_name` is specified, only the matching collection is restored. If no `collection_name` is specified, all collections are restored. 

### Example

```bash
./mongorestore_chunks.sh my_database '/Users/username/Documents/mongo_chunks'
```

```bash
./mongorestore_chunks.sh my_database '/Users/username/Documents/mongo_chunks' collection_1
```

