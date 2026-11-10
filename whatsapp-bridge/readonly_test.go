package main

import (
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestReadOnlyBlocksWriteRoutes(t *testing.T) {
	reached := false
	h := readOnly(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		reached = true
		w.WriteHeader(http.StatusOK)
	}))
	for path := range writeRoutes {
		reached = false
		rec := httptest.NewRecorder()
		h.ServeHTTP(rec, httptest.NewRequest(http.MethodPost, path, nil))
		if rec.Code != http.StatusForbidden || reached {
			t.Errorf("%s: got %d, handler reached=%v; want 403 and not reached", path, rec.Code, reached)
		}
	}
	for _, path := range []string{"/api/health", "/api/download"} {
		reached = false
		rec := httptest.NewRecorder()
		h.ServeHTTP(rec, httptest.NewRequest(http.MethodGet, path, nil))
		if !reached {
			t.Errorf("%s: read route did not reach the handler", path)
		}
	}
}

func TestWebhooksOffByDefault(t *testing.T) {
	t.Setenv("WEBHOOK_ENABLED", "")
	if webhooksEnabled() {
		t.Error("webhooks are on with WEBHOOK_ENABLED unset; the read-only fork wants them off")
	}
}
