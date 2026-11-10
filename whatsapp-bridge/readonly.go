package main

import "net/http"

// Read-only fork (branch somente-leitura): every REST route that would act on
// WhatsApp answers 403 before reaching its handler, so not even a direct curl
// to the bridge can send, react, mark as read or show "typing".
var writeRoutes = map[string]bool{
	"/api/send":      true,
	"/api/mark-read": true,
	"/api/react":     true,
	"/api/typing":    true,
}

func readOnly(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if writeRoutes[r.URL.Path] {
			http.Error(w, "read-only bridge: this route is disabled", http.StatusForbidden)
			return
		}
		next.ServeHTTP(w, r)
	})
}
