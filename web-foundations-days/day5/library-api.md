# Library Books API

This API provides endpoints for managing books in a library.

## Endpoints

### 1. List all books

- **Method:** GET
- **Path:** `/books`
- **Description:** Returns a list of all books.
- **Success status:** `200 OK`

### 2. Get one book

- **Method:** GET
- **Path:** `/books/{id}`
- **Description:** Returns one book using its ID.
- **Success status:** `200 OK`

### 3. Create a book

- **Method:** POST
- **Path:** `/books`
- **Description:** Creates a new book.
- **Example request body:**

```json
{
  "title": "Things Fall Apart",
  "author": "Chinua Achebe",
  "year": 1958
}
```
- Success status: 201 Created

### 4. Update a book

- **Method:** PUT
- **Path:** `/books/{id}`
- **Description:** Updates an existing book using its ID.

```Example request body:
{
  "title": "Things Fall Apart",
  "author": "Chinua Achebe",
  "year": 1958
}
```
- Success status: 200 OK

### 5. Delete a book

- **Method:** DELETE
- **Path:** `/books/{id}`
- **Description:** Deletes a book using its ID.
- **Success status:** `204 No Content`

### 6. List books by author

- **Method:** GET
- **Path:** `/books?author=Chinua%20Achebe`
- **Description:** Returns books written by the specified author.
- **Success status:** `200 OK`

### Error Codes

#### `400 Bad Request`

- The request is invalid or contains missing or invalid data.

```Example:
A client tries to create a book without providing a title or author.
`POST /books`
with an incomplete request body.
```

#### `404 Not Found`

- The requested book does not exist.

```Example:
A client requests:
`GET /books/999`
but there is no book with ID 999
```