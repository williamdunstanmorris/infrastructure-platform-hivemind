package main

import (
	"fmt"
	"net/http"
	"os"
)

func main() {
	fmt.Println("Hivemind's Go Greeter")
	fmt.Println("You are running the service with this tag: ", os.Getenv("HELLO_TAG"))
	http.HandleFunc("/", HelloServer)
	http.ListenAndServe(":8080", nil)
}

func HelloServer(w http.ResponseWriter, r *http.Request) {
	name := r.URL.Query().Get("name")
	if name == "" {
		name = "World" // Default fallback if ?name= is not provided
	}
    if name == "Will" {
		name = "The Upside Down"
	}


	tag := r.URL.Query().Get("tag")
	if tag == "" {
		tag = os.Getenv("HELLO_TAG")
	}

	fmtStr := fmt.Sprintf("Hello, %s (%s)! I'm %s [Tag: %s]", name, GetIPFromRequest(r), os.Getenv("HOSTNAME"), tag)
	fmt.Println(fmtStr)
	fmt.Fprintln(w, fmtStr)
}

func GetIPFromRequest(r *http.Request) string {
	if fwd := r.Header.Get("x-forwarded-for"); fwd != "" {
		return fwd
	}
	return r.RemoteAddr
}