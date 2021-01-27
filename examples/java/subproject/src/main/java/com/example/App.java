package com.example;

public class App {
    private final String message;

    public App() {
        this.message = "Hello World!";
    }

    public String getMessage() {
        return this.message;
    }

    public static void main(String[] args) {
        System.out.println(new App().getMessage());
    }
}