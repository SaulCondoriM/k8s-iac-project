package main

import (
	"context"
	"encoding/json"
	"html/template"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

// Data structure to hold dynamic content for rendering
type PageData struct {
	Title   string
	Message string
	Posts   []BlogPost
}

type BlogPost struct {
	Title   string
	Content string
	Date    time.Time
}

type Submission struct {
	Title   string
	Content string
}

var CONN_STR = ""

var pool *pgxpool.Pool

// Handler function to render the main page
func handler(w http.ResponseWriter, r *http.Request) {

	var posts []BlogPost

	rows, err := pool.Query(context.Background(), "SELECT title, content, date FROM posts ORDER BY date DESC")
	if err != nil {
		log.Printf("Error querying posts: %v", err)
		http.Error(w, "Error fetching posts", http.StatusInternalServerError)
		return
	}

	defer rows.Close()
	for rows.Next() {
		var post BlogPost
		if err := rows.Scan(&post.Title, &post.Content, &post.Date); err != nil {
			log.Printf("Error scanning post: %v", err)
			continue
		}
		posts = append(posts, post)
	}

	if err := rows.Err(); err != nil {
		log.Printf("Error iterating rows: %v", err)
	}

	data := PageData{
		Title:   "TEST DE JENKINS tes 2",
		Message: "✅ ¡PERFECTO! Jenkins detecta cambios cada minuto - Build #" + os.Getenv("BUILD_NUMBER"),
		Posts:   posts,
	}

	// Parse and execute template
	tmpl, err := template.ParseFiles("templates/index.html")
	if err != nil {
		http.Error(w, "Error parsing template", http.StatusInternalServerError)
		return
	}
	if err := tmpl.Execute(w, data); err != nil {
		http.Error(w, "Error executing template", http.StatusInternalServerError)
	}
}

func submit(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method Not Allowed", http.StatusMethodNotAllowed)
		return
	}

	var s Submission

	err := json.NewDecoder(r.Body).Decode(&s)
	if err != nil {
		http.Error(w, "Bad Request", http.StatusBadRequest)
		return
	}

	if len(s.Title) < 3 || len(s.Title) > 256 {
		http.Error(w, "Title size is bad", http.StatusBadRequest)
		return
	}

	if len(s.Content) < 3 || len(s.Content) > 10000 {
		http.Error(w, "Content size is bad", http.StatusBadRequest)
		return
	}

	query := "INSERT INTO posts (title, content, date) VALUES ($1, $2, NOW())"
	_, err = pool.Exec(context.Background(), query, s.Title, s.Content)
	if err != nil {
		log.Printf("Error inserting post: %v", err)
		http.Error(w, "Internal Server Error", http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusOK)
	w.Write([]byte("Post created successfully"))
}

func main() {

	CONN_STR = os.Getenv("CONN_STR")
	if CONN_STR == "" {
		panic("empty CONN_STR")
	}

	// Create connection pool with proper configuration
	poolConfig, err := pgxpool.ParseConfig(CONN_STR)
	if err != nil {
		panic(err)
	}

	// Configure pool settings for high concurrency
	poolConfig.MaxConns = 25                    // Maximum connections in pool
	poolConfig.MinConns = 5                     // Minimum connections to keep open
	poolConfig.MaxConnLifetime = time.Hour      // Recycle connections every hour
	poolConfig.MaxConnIdleTime = 30 * time.Minute
	poolConfig.HealthCheckPeriod = time.Minute

	// Create the connection pool
	pool, err = pgxpool.NewWithConfig(context.Background(), poolConfig)
	if err != nil {
		panic(err)
	}
	defer pool.Close()

	// Test the connection
	if err := pool.Ping(context.Background()); err != nil {
		log.Fatalf("Unable to ping database: %v\n", err)
	}

	log.Println("Successfully connected to database")

	// Create table if it doesn't exist
	_, err = pool.Exec(context.Background(), "CREATE TABLE IF NOT EXISTS posts(id SERIAL PRIMARY KEY, title VARCHAR(256), content TEXT, date TIMESTAMPTZ);")
	if err != nil {
		panic(err)
	}

	log.Println("Database table ready")

	// Register handler function for the root path
	http.HandleFunc("/", handler)
	http.HandleFunc("/submit", submit)

	// Start server on port 8080
	log.Println("Server started at :8080")
	log.Fatal(http.ListenAndServe(":8080", nil))
}
