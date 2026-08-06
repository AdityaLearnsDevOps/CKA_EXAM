package com.example.lib2;

public class RequestProcessor {
    public String process(String payload) {
        if (payload == null || payload.isBlank()) {
            return "No payload provided";
        }
        return "Received payload: " + payload.trim();
    }
}
