# Vector Search

Vector search (is a technique used to find items in a dataset that are mathematically "similar" to a query, even if they don't share exact keywords.

## 1. Core Concept: Embeddings
Traditional search relies on keyword matching (Lexical Search). Vector search relies on **Embeddings**.
- **What is an Embedding?** It is a numerical representation of data (text, images, audio) in a high-dimensional space.
- **Model-Driven:** Machine Learning models (like BERT, CLIP, or Word2Vec) transform raw data into a list of floating-point numbers (a vector).
- **Semantic Meaning:** In this high-dimensional space, items with similar meanings or features are positioned close to each other.

[Image of Word Embeddings in Vector Space]

---

## 2. How Vector Search Works
The process generally follows these steps:

1.  **Vectorization:** Convert all documents/items into vectors using an embedding model and store them in a **Vector Database** (e.g., Pinecone, Milvus, Weaviate).
2.  **Query Transformation:** When a user searches, their query is converted into a vector using the *same* embedding model.
3.  **Similarity Calculation:** The system calculates the distance between the query vector and the stored vectors.
4.  **Nearest Neighbor Retrieval:** The system returns the results with the smallest distance (highest similarity).

---

## 3. Scaling with ANN (Approximate Nearest Neighbors)
Comparing a query vector against millions of items (Brute Force/KNN) is slow. Vector databases use **ANN** algorithms to speed this up:

-   **HNSW (Hierarchical Navigable Small Worlds):** A graph-based index that allows for extremely fast traversal.
-   **IVF (Inverted File Index):** Clusters vectors into buckets; search only checks the most relevant buckets.
-   **Product Quantization (PQ):** Compresses vectors to save memory while maintaining searchable accuracy.

---

## 4. Why use Vector Search?
-   **Handles Synonyms:** Searching for "feline" will return results about "cats."
-   **Multimodal Search:** Use an image to search for similar images, or text to search for videos.
-   **Long-form Context:** Unlike keywords, vectors capture the "theme" of a whole paragraph.
-   **Foundation of RAG:** Vector search is the "retrieval" engine for **Retrieval-Augmented Generation**, allowing LLMs to access private or up-to-date data.