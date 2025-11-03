package com.separate;

public class SeparateApp {
    private final String message;

    public SeparateApp() {
        this.message = "Hello from another (separate) world.";
    }

    public String getMessage() {
        return this.message;
    }
}
